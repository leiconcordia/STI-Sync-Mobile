import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/firestore_paths.dart';
import '../../../core/exceptions/app_exception.dart';
import '../../../services/cloudinary_service.dart';
import '../models/student_model.dart';

/// Handles student self-registration: Auth creation, duplicate checks,
/// Cloudinary uploads, and the final Firestore write.
class RegistrationRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final CloudinaryService _cloudinary;

  RegistrationRepository(this._auth, this._firestore, this._cloudinary);

  Future<bool> isStudentIdTaken(String studentId) async {
    final snap = await _firestore
        .collection(FirestorePaths.students)
        .where('studentId', isEqualTo: studentId)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  Future<bool> isEmailTaken(String email) async {
    final snap = await _firestore
        .collection(FirestorePaths.students)
        .where('email', isEqualTo: email.toLowerCase())
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
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

  /// Full self-registration pipeline.
  Future<void> register({
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
        message: 'This email address is already registered.',
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
          message: 'Email already in use. Try logging in.',
        );
      }
      rethrow;
    }

    final uid = cred.user!.uid;
    late String profilePhotoUrl;
    late String schoolIdPhotoUrl;

    try {
      // 3. Upload profile photo
      onProgress?.call(0.4, 'Uploading profile photo…');
      profilePhotoUrl = await _cloudinary.uploadFile(
        profilePhotoFile,
        folder: 'students/profile',
      );

      // 4. Upload school ID photo
      onProgress?.call(0.65, 'Uploading school ID…');
      schoolIdPhotoUrl = await _cloudinary.uploadFile(
        schoolIdFile,
        folder: 'students/school-id',
      );

      // 5. Write Firestore document
      onProgress?.call(0.85, 'Saving your registration…');
      await _firestore
          .collection(FirestorePaths.students)
          .doc(uid)
          .set(data.toFirestoreMap(
            uid: uid,
            profilePhotoUrl: profilePhotoUrl,
            schoolIdPhotoUrl: schoolIdPhotoUrl,
          ));

      onProgress?.call(1.0, 'Done!');
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
  Future<void> resubmit({
    required String uid,
    required StudentModel data,
    File? profilePhotoFile,
    String? existingProfilePhotoUrl,
    File? schoolIdFile,
    String? existingSchoolIdUrl,
    void Function(double progress, String label)? onProgress,
  }) async {
    // 1. Duplicate checks are less relevant here since the user already exists,
    // but we should verify the email hasn't been taken by ANOTHER user if changed.
    // Assuming email doesn't change on resubmit for simplicity, or we check if taken by *others*.
    // For now, skip duplicate checks on resubmit to avoid blocking the same user.

    late String profilePhotoUrl;
    late String schoolIdPhotoUrl;

    // 2. Upload profile photo
    if (profilePhotoFile != null) {
      onProgress?.call(0.4, 'Uploading profile photo…');
      profilePhotoUrl = await _cloudinary.uploadFile(
        profilePhotoFile,
        folder: 'students/profile',
      );
    } else {
      profilePhotoUrl = existingProfilePhotoUrl ?? '';
    }

    // 3. Upload school ID photo
    if (schoolIdFile != null) {
      onProgress?.call(0.65, 'Uploading school ID…');
      schoolIdPhotoUrl = await _cloudinary.uploadFile(
        schoolIdFile,
        folder: 'students/school-id',
      );
    } else {
      schoolIdPhotoUrl = existingSchoolIdUrl ?? '';
    }

    // 4. Update Firestore document
    onProgress?.call(0.85, 'Updating your registration…');
    await _firestore
        .collection(FirestorePaths.students)
        .doc(uid)
        .set(data.toFirestoreMap(
          uid: uid,
          profilePhotoUrl: profilePhotoUrl,
          schoolIdPhotoUrl: schoolIdPhotoUrl,
        ));

    onProgress?.call(1.0, 'Done!');
  }
}
