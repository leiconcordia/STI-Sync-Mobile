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
}
