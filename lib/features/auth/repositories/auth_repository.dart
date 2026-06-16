import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/firestore_paths.dart';
import '../../../core/exceptions/app_exception.dart';
import '../models/student_model.dart';

/// Repository for handling authentication and student profile data.
class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRepository(this._auth, this._firestore);

  /// Stream of the current user's authentication state.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Logs in a student using email and password.
  /// 
  /// Throws [AppException] if login fails.
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

  /// Logs out the current user.
  Future<void> logout() async {
    await _auth.signOut();
  }

  /// Fetches the student profile for a given UID.
  /// 
  /// Returns a stream of [StudentModel] to listen for live updates.
  Stream<StudentModel?> watchStudentProfile(String uid) {
    return _firestore
        .collection(FirestorePaths.students)
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? StudentModel.fromFirestore(doc) : null);
  }

  /// Gets the current student profile one-time.
  Future<StudentModel?> getStudentProfile(String uid) async {
    try {
      final doc = await _firestore.collection(FirestorePaths.students).doc(uid).get();
      if (doc.exists) {
        return StudentModel.fromFirestore(doc);
      }
      return null;
    } on FirebaseException catch (e) {
      throw AppException(
        code: e.code,
        message: e.message ?? 'Failed to fetch student profile.',
      );
    }
  }
}
