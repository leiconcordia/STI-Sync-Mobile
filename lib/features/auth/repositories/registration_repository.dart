import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
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

  /// Fetches sections for a course matching courseId/courseCode and yearLevel.
  /// Follows the exact normalization logic from the Web Admin.
  Future<List<Map<String, dynamic>>> getSections({
    required String courseId,
    String? courseCode,
    String? yearLevel,
  }) async {
    List<Map<String, dynamic>> results = [];

    // 1. Try querying /sections by courseId
    if (courseId.isNotEmpty) {
      try {
        final snapId = await _firestore
            .collection(FirestorePaths.sections)
            .where('courseId', isEqualTo: courseId)
            .get();
        if (snapId.docs.isNotEmpty) {
          results.addAll(snapId.docs.map((doc) => {'id': doc.id, ...doc.data()}));
        }
      } catch (_) {}
    }

    // 2. Try querying /sections by courseCode if results are empty
    if (results.isEmpty && courseCode != null && courseCode.isNotEmpty) {
      try {
        final snapCode = await _firestore
            .collection(FirestorePaths.sections)
            .where('courseCode', isEqualTo: courseCode)
            .get();
        if (snapCode.docs.isNotEmpty) {
          results.addAll(snapCode.docs.map((doc) => {'id': doc.id, ...doc.data()}));
        }
      } catch (_) {}
    }

    // 3. Try subcollection under courses if still empty
    if (results.isEmpty && courseId.isNotEmpty) {
      try {
        final subSnap = await _firestore
            .collection(FirestorePaths.courses)
            .doc(courseId)
            .collection(FirestorePaths.sections)
            .get();
        if (subSnap.docs.isNotEmpty) {
          results.addAll(subSnap.docs.map((doc) => {'id': doc.id, ...doc.data()}));
        }
      } catch (_) {}
    }

    // 4. Fallback: Fetch all sections if queries didn't yield results (in case of field differences)
    if (results.isEmpty) {
      try {
        final allSnap = await _firestore.collection(FirestorePaths.sections).get();
        results = allSnap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
      } catch (_) {}
    }

    // 5. In-memory filter matching the Web Admin:
    return results.where((s) {
      if (s['archived'] == true) return false;

      // Filter by course
      final sCourseId = s['courseId']?.toString() ?? '';
      final sCourseCode = s['courseCode']?.toString() ?? '';
      final matchesCourse = (courseId.isNotEmpty && sCourseId == courseId) ||
          (courseCode != null && courseCode.isNotEmpty && (sCourseCode == courseCode || sCourseId == courseCode));
      if (!matchesCourse && (courseId.isNotEmpty || (courseCode != null && courseCode.isNotEmpty))) {
        return false;
      }

      // Filter by yearLevel if provided
      if (yearLevel == null || yearLevel.trim().isEmpty) return true;

      final rawYl = yearLevel.trim();
      int yNum;
      if (rawYl.contains('11')) {
        yNum = 11;
      } else if (rawYl.contains('12')) {
        yNum = 12;
      } else if (rawYl.contains('1st') || rawYl == '1') {
        yNum = 1;
      } else if (rawYl.contains('2nd') || rawYl == '2') {
        yNum = 2;
      } else if (rawYl.contains('3rd') || rawYl == '3') {
        yNum = 3;
      } else if (rawYl.contains('4th') || rawYl == '4') {
        yNum = 4;
      } else if (rawYl.contains('5th') || rawYl == '5') {
        yNum = 5;
      } else {
        yNum = int.tryParse(rawYl) ?? 1;
      }

      final dynamic sYl = s['yearLevel'] ?? s['year'];
      if (sYl == null) return true;

      if (sYl is num) {
        if (sYl == yNum) return true;
        if (yNum == 11 && sYl == 1) return true;
        if (yNum == 12 && sYl == 2) return true;
        return false;
      }

      final sYlStr = sYl.toString().trim();
      if (sYlStr.toLowerCase() == rawYl.toLowerCase()) return true;

      final sYlNum = int.tryParse(sYlStr);
      if (sYlNum != null) {
        if (sYlNum == yNum) return true;
        if (yNum == 11 && sYlNum == 1) return true;
        if (yNum == 12 && sYlNum == 2) return true;
      }

      return false;
    }).toList();
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

  /// Fetches all active academic periods (College Semesters and SHS Trimesters)
  /// matching the Web Admin's useActiveAcademicPeriods hook.
  Future<Map<String, Map<String, dynamic>?>> getActiveAcademicPeriods() async {
    Map<String, dynamic>? collegePeriod;
    Map<String, dynamic>? shsPeriod;

    try {
      final snap = await _firestore.collection(FirestorePaths.semesters).get();
      if (snap.docs.isNotEmpty) {
        for (var doc in snap.docs) {
          final data = doc.data();
          if (data['archived'] == true) continue;

          final status = data['status']?.toString().toUpperCase();
          final isActive = data['isActive'] == true || data['is_active'] == true || data['current'] == true;
          if (status != 'ACTIVE' && !isActive) continue;

          final level = (data['academicLevel'] as String?)?.toUpperCase() ?? '';
          final semName = (data['semester'] as String? ?? data['name'] as String? ?? data['term'] as String? ?? '');
          final isTrimester = semName.toLowerCase().contains('trimester');

          if (shsPeriod == null && (level == 'SHS' || isTrimester)) {
            shsPeriod = {'id': doc.id, ...data};
          }

          if (collegePeriod == null && (level == 'COLLEGE' || level == 'TERTIARY' || (!isTrimester && level.isEmpty))) {
            collegePeriod = {'id': doc.id, ...data};
          }
        }
      }
    } catch (_) {}

    return {
      'college': collegePeriod,
      'shs': shsPeriod,
    };
  }

  /// Fetches the active semester robustly for a specific academic level ('COLLEGE' / 'TERTIARY' vs 'SHS').
  Future<Map<String, dynamic>?> getActiveSemester({String academicLevel = 'COLLEGE'}) async {
    final periods = await getActiveAcademicPeriods();
    final isShs = academicLevel.toUpperCase() == 'SHS';
    if (isShs) {
      return periods['shs'] ?? periods['college'];
    } else {
      return periods['college'] ?? periods['shs'];
    }
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
        message: 'This user already exists. A student record with the same name and date of birth is already registered.',
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
        registeredStudentId: data.studentId,
      );

      String finalStatus = 'PENDING';
      String? rejectionReason;
      final revisionHistory = <Map<String, dynamic>>[];
      int revisionCount = 0;

      if (aiResult.decision == AiDecision.autoApprove) {
        finalStatus = 'ACTIVE'; // AUTO-APPROVED BY AI!
        rejectionReason = null;
        revisionCount = 0;
      } else if (aiResult.decision == AiDecision.autoReject) {
        // Instead of deleting the account, mark status as RETURNED with the user-friendly guidance
        // so the student can easily fix and upload the correct photo.
        finalStatus = 'RETURNED';
        rejectionReason = aiResult.userFriendlyMessage.isNotEmpty
            ? aiResult.userFriendlyMessage
            : aiResult.reason;
        revisionCount = 1;
        revisionHistory.add({
          'revisionNumber': 1,
          'status': 'RETURNED',
          'reason': rejectionReason,
          'reviewedBy': 'AI_VERIFICATION',
          'timestamp': DateTime.now().toIso8601String(),
        });
      } else {
        // MANUAL_ADMIN_REVIEW
        finalStatus = 'PENDING';
        rejectionReason = aiResult.userFriendlyMessage.isNotEmpty
            ? aiResult.userFriendlyMessage
            : 'Your registration has been submitted for manual review by SAO staff.';
        revisionCount = 1;
        revisionHistory.add({
          'revisionNumber': 1,
          'status': 'PENDING',
          'reason': rejectionReason,
          'reviewedBy': 'AI_VERIFICATION',
          'timestamp': DateTime.now().toIso8601String(),
        });
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
            revisionCountOverride: revisionCount,
            revisionHistoryOverride: revisionHistory,
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
        message: 'This user already exists. A student record with the same name and date of birth is already registered.',
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
    final List<Map<String, dynamic>> revisionHistory = [];

    // Fetch existing revision history from Firestore
    try {
      final docSnap = await _firestore.collection(FirestorePaths.students).doc(uid).get();
      if (docSnap.exists) {
        final data = docSnap.data();
        final rawHistory = data?['revisionHistory'] as List<dynamic>?;
        if (rawHistory != null && rawHistory.isNotEmpty) {
          revisionHistory.addAll(
            rawHistory.map((item) => Map<String, dynamic>.from(item as Map)),
          );
        }

        final existingRejection = data?['rejectionReason'] as String?;
        final currentDocStatus = (data?['status'] as String? ?? '').toUpperCase();

        if (revisionHistory.isEmpty && ((existingRejection != null && existingRejection.isNotEmpty) || currentDocStatus == 'RETURNED')) {
          // Backward compatibility for existing rejected registrations without history
          revisionHistory.add({
            'revisionNumber': 1,
            'status': currentDocStatus.isNotEmpty ? currentDocStatus : 'RETURNED',
            'reason': (existingRejection != null && existingRejection.isNotEmpty)
                ? existingRejection
                : 'Returned for revision by Adviser / SAO Staff.',
            'reviewedBy': 'Adviser / SAO Staff',
            'timestamp': DateTime.now().toIso8601String(),
          });
        } else if (revisionHistory.isNotEmpty && existingRejection != null && existingRejection.isNotEmpty) {
          // If the adviser reviewed and commented on the last revision, attribute it to the adviser
          final last = revisionHistory.last;
          if (last['reason'] != existingRejection || last['status'] != 'RETURNED') {
            last['status'] = 'RETURNED';
            last['reason'] = existingRejection;
            last['reviewedBy'] = 'Adviser / SAO Staff';
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching existing revision history: $e');
    }

    final currentRevisionNumber = revisionHistory.length + 1;

    try {
      File? targetProfileFile = profilePhotoFile;
      File? targetSchoolIdFile = schoolIdFile;

      // If profile photo wasn't changed, download existing Cloudinary URL for AI comparison
      if (targetProfileFile == null && profilePhotoUrl.isNotEmpty) {
        onProgress?.call(0.6, 'Preparing profile photo for AI check…');
        debugPrint('Downloading existing profile photo from Cloudinary for AI check: $profilePhotoUrl');
        targetProfileFile = await _fileFromUrl(profilePhotoUrl, 'temp_profile_$uid.jpg');
      }

      // If school ID photo wasn't changed, download existing Cloudinary URL for AI comparison
      if (targetSchoolIdFile == null && schoolIdPhotoUrl.isNotEmpty) {
        onProgress?.call(0.7, 'Preparing school ID photo for AI check…');
        debugPrint('Downloading existing school ID from Cloudinary for AI check: $schoolIdPhotoUrl');
        targetSchoolIdFile = await _fileFromUrl(schoolIdPhotoUrl, 'temp_school_id_$uid.jpg');
      }

      debugPrint('=== RESUBMIT AI REVALIDATION CHECK ===');
      debugPrint('targetProfileFile: ${targetProfileFile?.path} (exists: ${targetProfileFile?.existsSync()})');
      debugPrint('targetSchoolIdFile: ${targetSchoolIdFile?.path} (exists: ${targetSchoolIdFile?.existsSync()})');

      if (targetProfileFile != null && targetSchoolIdFile != null) {
        onProgress?.call(0.78, 'Re-running AI Verification…');
        final registeredName = '${data.firstName} ${data.lastName}'.trim();
        debugPrint('Invoking AI verifyStudentIdentity on resubmit for "$registeredName"...');
        final aiResult = await _aiService.verifyStudentIdentity(
          schoolIdFile: targetSchoolIdFile,
          profilePhotoFile: targetProfileFile,
          registeredName: registeredName,
          registeredStudentId: data.studentId,
        );

        debugPrint('Resubmit AI result: decision=${aiResult.decision}, error=${aiResult.errorCode}, reason=${aiResult.reason}');

        if (aiResult.decision == AiDecision.autoApprove) {
          finalStatus = 'ACTIVE';
          rejectionReason = null;
          revisionHistory.add({
            'revisionNumber': currentRevisionNumber,
            'status': 'ACTIVE',
            'reason': 'Official STI ID Card and student identity approved by AI.',
            'reviewedBy': 'AI_VERIFICATION',
            'timestamp': DateTime.now().toIso8601String(),
          });
        } else if (aiResult.decision == AiDecision.autoReject) {
          finalStatus = 'RETURNED';
          rejectionReason = aiResult.userFriendlyMessage.isNotEmpty
              ? aiResult.userFriendlyMessage
              : aiResult.reason;
          revisionHistory.add({
            'revisionNumber': currentRevisionNumber,
            'status': 'RETURNED',
            'reason': rejectionReason,
            'reviewedBy': 'AI_VERIFICATION',
            'timestamp': DateTime.now().toIso8601String(),
          });
        } else {
          finalStatus = 'PENDING';
          rejectionReason = aiResult.userFriendlyMessage.isNotEmpty
              ? aiResult.userFriendlyMessage
              : 'Your registration has been submitted for manual review by SAO staff.';
          revisionHistory.add({
            'revisionNumber': currentRevisionNumber,
            'status': 'PENDING',
            'reason': rejectionReason,
            'reviewedBy': 'AI_VERIFICATION',
            'timestamp': DateTime.now().toIso8601String(),
          });
        }
      } else {
        debugPrint('⚠️ Resubmit: One or both files missing for AI check (profile=$targetProfileFile, id=$targetSchoolIdFile)');
        revisionHistory.add({
          'revisionNumber': currentRevisionNumber,
          'status': 'PENDING',
          'reason': 'Submitted for manual review by SAO staff.',
          'reviewedBy': 'SYSTEM',
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
    } catch (e, stack) {
      debugPrint('AI Verification exception on resubmit: $e\n$stack');
      finalStatus = 'PENDING';
      rejectionReason = 'Your registration has been submitted for manual review by SAO staff.';
      revisionHistory.add({
        'revisionNumber': currentRevisionNumber,
        'status': 'PENDING',
        'reason': rejectionReason,
        'reviewedBy': 'SYSTEM',
        'timestamp': DateTime.now().toIso8601String(),
      });
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
          revisionCountOverride: revisionHistory.length,
          revisionHistoryOverride: revisionHistory,
        ));

    onProgress?.call(1.0, 'Done!');
    return finalStatus;
  }

  /// Downloads a remote image URL to a local temporary File using application cache directory.
  Future<File?> _fileFromUrl(String url, String filename) async {
    try {
      if (url.isEmpty) return null;
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/$filename');
        await file.writeAsBytes(response.bodyBytes);
        return file;
      } else {
        debugPrint('Failed to download image from $url: HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error in _fileFromUrl for $url: $e');
    }
    return null;
  }
}
