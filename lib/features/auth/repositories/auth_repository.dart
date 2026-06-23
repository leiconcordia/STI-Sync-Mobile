import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/firestore_paths.dart';
import '../../../core/exceptions/app_exception.dart';
import '../models/student_model.dart';

/// Repository for authentication and student profile reads.
class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRepository(this._auth, this._firestore);

  FirebaseAuth get auth => _auth;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Signs in with email/password. Throws [AppException] on failure.
  Future<UserCredential> login(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AppException(
        code: e.code,
        message: e.message ?? 'An unknown authentication error occurred.',
      );
    }
  }

  Future<void> logout() async => _auth.signOut();

  /// Live stream of the student's own Firestore document.
  Stream<StudentModel?> watchStudentProfile(String uid) {
    return _firestore
        .collection(FirestorePaths.students)
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? StudentModel.fromFirestore(doc) : null);
  }

  /// One-time fetch of the student's Firestore document.
  Future<StudentModel?> getStudentProfile(String uid) async {
    try {
      final doc = await _firestore
          .collection(FirestorePaths.students)
          .doc(uid)
          .get();
      return doc.exists ? StudentModel.fromFirestore(doc) : null;
    } on FirebaseException catch (e) {
      throw AppException(
        code: e.code,
        message: e.message ?? 'Failed to fetch student profile.',
      );
    }
  }
}
