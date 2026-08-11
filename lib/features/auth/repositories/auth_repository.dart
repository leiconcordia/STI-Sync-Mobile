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

  /// Signs in with email or student ID & password. Throws [AppException] on failure.
  Future<UserCredential> login(String emailOrStudentId, String password) async {
    String email = emailOrStudentId.trim();

    if (email.isEmpty) {
      throw const AppException(
        code: 'empty-identifier',
        message: 'Please enter your Student ID or Email.',
      );
    }
    if (password.trim().isEmpty) {
      throw const AppException(
        code: 'empty-password',
        message: 'Please enter your password.',
      );
    }

    // If input is an 11-digit Student ID (e.g. 02000123456), look up student's email from Firestore
    if (RegExp(r'^\d{11}$').hasMatch(email)) {
      try {
        final snap = await _firestore
            .collection(FirestorePaths.students)
            .where('studentId', isEqualTo: email)
            .limit(1)
            .get();
        if (snap.docs.isEmpty) {
          throw const AppException(
            code: 'student-not-found',
            message: 'No student record found with this Student ID.',
          );
        }
        final fetchedEmail = snap.docs.first.data()['email'] as String?;
        if (fetchedEmail == null || fetchedEmail.isEmpty) {
          throw const AppException(
            code: 'no-email-record',
            message: 'No email address registered for this Student ID.',
          );
        }
        email = fetchedEmail;
      } catch (e) {
        if (e is AppException) rethrow;
        throw AppException(
          code: 'student-lookup-error',
          message: 'Failed to look up Student ID: ${e.toString()}',
        );
      }
    }

    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      String humanMessage;
      switch (e.code) {
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
        case 'INVALID_LOGIN_CREDENTIALS':
          humanMessage = 'Incorrect password or account credentials. Please try again.';
          break;
        case 'invalid-email':
          humanMessage = 'Please enter a valid email address or 11-digit Student ID.';
          break;
        case 'user-disabled':
          humanMessage = 'This student account has been disabled. Please contact SAO.';
          break;
        case 'too-many-requests':
          humanMessage = 'Too many failed login attempts. Please wait a moment and try again.';
          break;
        default:
          humanMessage = e.message ?? 'An unknown authentication error occurred.';
      }
      throw AppException(
        code: e.code,
        message: humanMessage,
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
