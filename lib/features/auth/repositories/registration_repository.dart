import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/firestore_paths.dart';
import '../../../core/exceptions/app_exception.dart';
import '../../../services/cloudinary_service.dart';
import '../models/student_model.dart';

import '../../../services/gemini_ai_verification_service.dart';

/// Handles student self-registration: Auth creation, duplicate checks,
/// Cloudinary uploads, AI Verification, and the final Firestore write.
class RegistrationRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final CloudinaryService _cloudinary;
  final GeminiAiVerificationService _aiService;

  RegistrationRepository(
    this._auth,
    this._firestore,
    this._cloudinary, [
    GeminiAiVerificationService? aiService,
  ]) : _aiService = aiService ?? GeminiAiVerificationService();

  Future<bool> isStudentIdTaken(String studentId, {String? excludeUid}) async {
    final snap = await _firestore
        .collection(FirestorePaths.students)
        .where('studentId', isEqualTo: studentId)
        .get();
    for (final doc in snap.docs) {
      if (excludeUid != null && doc.id == excludeUid) continue;
      return true;
    }
    return false;
  }

  Future<bool> isEmailTaken(String email, {String? excludeUid}) async {
    final snap = await _firestore
        .collection(FirestorePaths.students)
        .where('email', isEqualTo: email.toLowerCase())
        .get();
    for (final doc in snap.docs) {
      if (excludeUid != null && doc.id == excludeUid) continue;
      return true;
    }
    return false;
  }

  /// Checks if a student with the same First Name, Last Name, and Date of Birth already exists in Firestore.
  Future<bool> isNameAndDobTaken({
    required String firstName,
    required String lastName,
    required String dob,
    String? excludeUid,
  }) async {
    final cleanFirst = firstName.trim().toLowerCase();
    final cleanLast = lastName.trim().toLowerCase();

    final snap = await _firestore
        .collection(FirestorePaths.students)
        .where('dateOfBirth', isEqualTo: dob)
        .get();

    for (final doc in snap.docs) {
      if (excludeUid != null && doc.id == excludeUid) continue;
      final data = doc.data();
      final docFirst = (data['firstName'] as String? ?? '').trim().toLowerCase();
      final docLast = (data['lastName'] as String? ?? '').trim().toLowerCase();

      if (docFirst == cleanFirst && docLast == cleanLast) {
        return true;
      }
    }
    return false;
  }

  /// Fetches available courses from Firestore.
  Future<List<Map<String, dynamic>>> getCourses() async {
    final snap = await _firestore.collection(FirestorePaths.courses).get();
    return snap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  Future<List<Map<String, dynamic>>> getSections(String courseIdOrCode) async {
    // 1. Try subcollection under courses
    try {
      final subSnap = await _firestore
          .collection(FirestorePaths.courses)
          .doc(courseIdOrCode)
          .collection(FirestorePaths.sections)
          .get();
      if (subSnap.docs.isNotEmpty) {
        return subSnap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
      }
    } catch (_) {}

    // 2. Try top-level collection with courseId
    final snapId = await _firestore
        .collection(FirestorePaths.sections)
        .where('courseId', isEqualTo: courseIdOrCode)
        .get();
    if (snapId.docs.isNotEmpty) {
      return snapId.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    }

    // 3. Fallback to courseCode
    final snapCode = await _firestore
        .collection(FirestorePaths.sections)
        .where('courseCode', isEqualTo: courseIdOrCode)
        .get();
    return snapCode.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  /// Fetches a department by its ID
  Future<Map<String, dynamic>?> getDepartment(String id) async {
    try {
      final doc = await _firestore.collection(FirestorePaths.departments).doc(id).get();
      if (doc.exists) {
        return {'id': doc.id, ...doc.data()!};
      }
    } catch (_) {}
    return null;
  }

  /// Fetches the active semester robustly.
  Future<Map<String, dynamic>?> getActiveSemester() async {
    try {
      final snap = await _firestore.collection(FirestorePaths.semesters).get();
      if (snap.docs.isEmpty) return null;

      for (var doc in snap.docs) {
        final data = doc.data();
        final status = data['status']?.toString().toLowerCase();
        final isActive = data['isActive'] == true || data['is_active'] == true || data['current'] == true;
        
        if (status == 'active' || status == 'current' || isActive) {
          return {'id': doc.id, ...data};
        }
      }
      
      // Fallback: If there's only 1 semester in the collection, assume it's the active one.
      if (snap.docs.length == 1) {
        return {'id': snap.docs.first.id, ...snap.docs.first.data()};
      }
    } catch (_) {}
    return null;
  }

  /// Full self-registration pipeline with AI Verification.
  /// Returns the final status string ('ACTIVE' for AI auto-approve, 'PENDING' for admin review).
  Future<String> register({
    required StudentModel data,
    required String password,
    required File profilePhotoFile,
    required File schoolIdFile,
    void Function(double progress, String label)? onProgress,
  }) async {
    // 1. Duplicate checks
    onProgress?.call(0.05, 'Checking student ID…');
    if (await isStudentIdTaken(data.studentId)) {
      throw const AppException(
        code: 'studentId-taken',
        message: 'A student with this ID already exists.',
      );
    }

    onProgress?.call(0.1, 'Checking email…');
    if (await isEmailTaken(data.email)) {
      throw const AppException(
        code: 'email-taken',
        message: 'This email address is already registered to another account.',
      );
    }

    onProgress?.call(0.15, 'Checking student identity…');
    if (await isNameAndDobTaken(
      firstName: data.firstName,
      lastName: data.lastName,
      dob: data.dateOfBirth,
    )) {
      throw const AppException(
        code: 'name-dob-taken',
        message: 'A student record with the same name and date of birth already exists.',
      );
    }

    // 2. Create Firebase Auth account
    onProgress?.call(0.2, 'Creating account…');
    late UserCredential cred;
    try {
      cred = await _auth.createUserWithEmailAndPassword(
        email: data.email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw const AppException(
          code: 'email-already-in-use',
          message: 'The email address is already in use by another account. Try logging in or use a different email.',
        );
      }
      rethrow;
    }

    final uid = cred.user!.uid;
    late String profilePhotoUrl;
    late String schoolIdPhotoUrl;

    try {
      // 3. Upload profile photo
      onProgress?.call(0.35, 'Uploading profile photo…');
      profilePhotoUrl = await _cloudinary.uploadFile(
        profilePhotoFile,
        folder: 'students/profile',
      );

      // 4. Upload school ID photo
      onProgress?.call(0.55, 'Uploading school ID…');
      schoolIdPhotoUrl = await _cloudinary.uploadFile(
        schoolIdFile,
        folder: 'students/school-id',
      );

      // 5. AI Identity & Document Verification
      onProgress?.call(0.75, 'Running AI Verification…');
      final registeredName = '${data.firstName} ${data.lastName}'.trim();
      final aiResult = await _aiService.verifyStudentIdentity(
        schoolIdFile: schoolIdFile,
        profilePhotoFile: profilePhotoFile,
        registeredName: registeredName,
      );

      String finalStatus = 'PENDING';
      String? rejectionReason;

      if (aiResult.decision == AiDecision.autoApprove) {
        finalStatus = 'ACTIVE'; // AUTO-APPROVED BY AI!
      } else if (aiResult.decision == AiDecision.autoReject) {
        // Instead of deleting the account, mark status as RETURNED with the AI comment
        // so the student can edit their registration and upload new photos.
        finalStatus = 'RETURNED';
        rejectionReason = 'AI Verification Returned: ${aiResult.reason}';
      } else {
        // MANUAL_ADMIN_REVIEW
        finalStatus = 'PENDING';
        rejectionReason = 'AI Flagged for Admin Review: ${aiResult.reason}';
      }

      // 6. Write Firestore document
      onProgress?.call(0.9, 'Saving your registration…');
      await _firestore
          .collection(FirestorePaths.students)
          .doc(uid)
          .set(data.toFirestoreMap(
            uid: uid,
            profilePhotoUrl: profilePhotoUrl,
            schoolIdPhotoUrl: schoolIdPhotoUrl,
            statusOverride: finalStatus,
            rejectionReasonOverride: rejectionReason,
          ));

      onProgress?.call(1.0, 'Done!');
      return finalStatus;
    } catch (e) {
      // Auth account was created — delete it so the student can retry
      // with the same email without hitting "email already in use".
      try {
        await cred.user?.delete();
      } catch (_) {}
      rethrow;
    }
  }

  /// Re-submits registration for an existing user (e.g., status was RETURNED).
  /// Skips Auth creation, uploads new photos, and updates the Firestore document.
  /// Returns the final status string ('ACTIVE' for AI auto-approve, 'RETURNED', or 'PENDING').
  Future<String> resubmit({
    required String uid,
    required StudentModel data,
    File? profilePhotoFile,
    String? existingProfilePhotoUrl,
    File? schoolIdFile,
    String? existingSchoolIdUrl,
    void Function(double progress, String label)? onProgress,
  }) async {
    // 1. Duplicate checks excluding self
    if (await isStudentIdTaken(data.studentId, excludeUid: uid)) {
      throw const AppException(
        code: 'studentId-taken',
        message: 'A student with this Student ID already exists.',
      );
    }
    if (await isEmailTaken(data.email, excludeUid: uid)) {
      throw const AppException(
        code: 'email-taken',
        message: 'This email address is already registered to another account.',
      );
    }
    if (await isNameAndDobTaken(
      firstName: data.firstName,
      lastName: data.lastName,
      dob: data.dateOfBirth,
      excludeUid: uid,
    )) {
      throw const AppException(
        code: 'name-dob-taken',
        message: 'A student record with the same name and date of birth already exists.',
      );
    }

    late String profilePhotoUrl;
    late String schoolIdPhotoUrl;

    // 2. Upload profile photo
    if (profilePhotoFile != null) {
      onProgress?.call(0.3, 'Uploading profile photo…');
      profilePhotoUrl = await _cloudinary.uploadFile(
        profilePhotoFile,
        folder: 'students/profile',
      );
    } else {
      profilePhotoUrl = existingProfilePhotoUrl ?? '';
    }

    // 3. Upload school ID photo
    if (schoolIdFile != null) {
      onProgress?.call(0.5, 'Uploading school ID…');
      schoolIdPhotoUrl = await _cloudinary.uploadFile(
        schoolIdFile,
        folder: 'students/school-id',
      );
    } else {
      schoolIdPhotoUrl = existingSchoolIdUrl ?? '';
    }

    // 4. Run AI Verification on resubmit (ALWAYS triggers on resubmit)
    String finalStatus = 'PENDING';
    String? rejectionReason;

    try {
      File? targetProfileFile = profilePhotoFile;
      File? targetSchoolIdFile = schoolIdFile;

      // If profile photo wasn't changed, download existing Cloudinary URL for AI comparison
      if (targetProfileFile == null && profilePhotoUrl.isNotEmpty) {
        onProgress?.call(0.6, 'Preparing profile photo for AI check…');
        targetProfileFile = await _fileFromUrl(profilePhotoUrl, 'temp_profile_$uid.jpg');
      }

      // If school ID photo wasn't changed, download existing Cloudinary URL for AI comparison
      if (targetSchoolIdFile == null && schoolIdPhotoUrl.isNotEmpty) {
        onProgress?.call(0.7, 'Preparing school ID photo for AI check…');
        targetSchoolIdFile = await _fileFromUrl(schoolIdPhotoUrl, 'temp_school_id_$uid.jpg');
      }

      if (targetProfileFile != null && targetSchoolIdFile != null) {
        onProgress?.call(0.78, 'Re-running AI Verification…');
        final registeredName = '${data.firstName} ${data.lastName}'.trim();
        final aiResult = await _aiService.verifyStudentIdentity(
          schoolIdFile: targetSchoolIdFile,
          profilePhotoFile: targetProfileFile,
          registeredName: registeredName,
        );

        if (aiResult.decision == AiDecision.autoApprove) {
          finalStatus = 'ACTIVE';
        } else if (aiResult.decision == AiDecision.autoReject) {
          finalStatus = 'RETURNED';
          rejectionReason = 'AI Verification Returned: ${aiResult.reason}';
        } else {
          finalStatus = 'PENDING';
          rejectionReason = 'AI Flagged for Admin Review: ${aiResult.reason}';
        }
      }
    } catch (e) {
      debugPrint('AI Verification exception on resubmit: $e');
      finalStatus = 'PENDING';
      rejectionReason = 'AI Flagged for Admin Review: $e';
    }

    // 5. Update Firestore document
    onProgress?.call(0.9, 'Updating your registration…');
    await _firestore
        .collection(FirestorePaths.students)
        .doc(uid)
        .set(data.toFirestoreMap(
          uid: uid,
          profilePhotoUrl: profilePhotoUrl,
          schoolIdPhotoUrl: schoolIdPhotoUrl,
          statusOverride: finalStatus,
          rejectionReasonOverride: rejectionReason,
        ));

    onProgress?.call(1.0, 'Done!');
    return finalStatus;
  }

  /// Downloads a remote image URL to a local temporary File.
  Future<File> _fileFromUrl(String url, String filename) async {
    final response = await http.get(Uri.parse(url));
    final tempDir = Directory.systemTemp;
    final file = File('${tempDir.path}/$filename');
    await file.writeAsBytes(response.bodyBytes);
    return file;
  }
}
