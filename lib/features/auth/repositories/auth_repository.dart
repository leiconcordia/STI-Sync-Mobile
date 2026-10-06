import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/firestore_paths.dart';
import '../../../core/exceptions/app_exception.dart';
import '../models/student_model.dart';
import '../../semester/models/semester_model.dart';

/// Repository for authentication and student profile reads.
class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRepository(this._auth, this._firestore);

  FirebaseAuth get auth => _auth;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Signs in with email or student ID & password. Throws [AppException] on failure.
  /// Checks whether [enteredPassword] matches the stored default password or the
  /// official default formula: Capitalized Last Name + Last 6 digits of Student No.
  /// (e.g. "Ablen496332", "Delacruz458280", "Canete505336").
  bool _isDefaultOrFormulaPasswordValid({
    required Map<String, dynamic> data,
    required String enteredPassword,
  }) {
    final cleanPassword = enteredPassword.trim();
    if (cleanPassword.isEmpty) return false;

    // 1. Direct comparison with stored defaultPassword in Firestore
    final defaultPassword = (data['defaultPassword'] as String?)?.trim();
    if (defaultPassword != null && defaultPassword.isNotEmpty) {
      if (cleanPassword == defaultPassword ||
          cleanPassword.toLowerCase() == defaultPassword.toLowerCase()) {
        return true;
      }
    }

    // 2. Compute formula password candidates:
    final rawLastName = (data['lastName'] as String? ?? '').trim();
    final rawStudentId = (data['studentId'] as String? ?? '').trim();
    final sIdDigits = rawStudentId.replaceAll(RegExp(r'\D'), '');
    final last6 = sIdDigits.length >= 6
        ? sIdDigits.substring(sIdDigits.length - 6)
        : sIdDigits;

    if (rawLastName.isEmpty || last6.isEmpty) return false;

    // Normalize Spanish/Tagalog diacritics (Ñ -> N, etc.)
    String normalizeAccents(String s) {
      return s
          .replaceAll('Ñ', 'N')
          .replaceAll('ñ', 'n')
          .replaceAll('É', 'E')
          .replaceAll('é', 'e')
          .replaceAll('Á', 'A')
          .replaceAll('á', 'a')
          .replaceAll('Í', 'I')
          .replaceAll('í', 'i')
          .replaceAll('Ó', 'O')
          .replaceAll('ó', 'o')
          .replaceAll('Ú', 'U')
          .replaceAll('ú', 'u');
    }

    final normalizedLastName = normalizeAccents(rawLastName);

    // Variant A: Pure letters only (removes spaces, hyphens: "DE LA CRUZ" -> "Delacruz")
    final lettersOnly = normalizedLastName.replaceAll(RegExp(r'[^a-zA-Z]'), '');
    final titleLetters = lettersOnly.isNotEmpty
        ? '${lettersOnly[0].toUpperCase()}${lettersOnly.substring(1).toLowerCase()}'
        : '';

    // Variant B: Direct title-case preserving spaces/dashes (e.g. "De la cruz")
    final titleRaw = normalizedLastName.isNotEmpty
        ? '${normalizedLastName[0].toUpperCase()}${normalizedLastName.substring(1).toLowerCase()}'
        : '';

    // Variant C: No spaces (e.g. "Dela-cruz")
    final noSpaces = normalizedLastName.replaceAll(RegExp(r'\s+'), '');
    final titleNoSpaces = noSpaces.isNotEmpty
        ? '${noSpaces[0].toUpperCase()}${noSpaces.substring(1).toLowerCase()}'
        : '';

    final candidates = <String>{
      if (titleLetters.isNotEmpty) '$titleLetters$last6',
      if (titleLetters.isNotEmpty) '${lettersOnly.toLowerCase()}$last6',
      if (titleLetters.isNotEmpty) '${lettersOnly.toUpperCase()}$last6',
      if (titleRaw.isNotEmpty) '$titleRaw$last6',
      if (titleNoSpaces.isNotEmpty) '$titleNoSpaces$last6',
    };

    for (final candidate in candidates) {
      if (cleanPassword == candidate ||
          cleanPassword.toLowerCase() == candidate.toLowerCase() ||
          cleanPassword.replaceAll(RegExp(r'[\s\-]'), '').toLowerCase() ==
              candidate.replaceAll(RegExp(r'[\s\-]'), '').toLowerCase()) {
        return true;
      }
    }

    return false;
  }

  /// Initiates an anonymous session for first-time profile completion and associates
  /// it with the student document.
  Future<UserCredential> _initiateFirstTimeOnboardingSession(
    DocumentReference studentDocRef,
  ) async {
    try {
      final anonCred = await _auth.signInAnonymously();
      final anonUid = anonCred.user!.uid;

      await studentDocRef.update({
        'authUid': anonUid,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return anonCred;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'admin-restricted-operation') {
        throw const AppException(
          code: 'admin-restricted-operation',
          message:
              'Anonymous authentication is disabled in Firebase Console. Please contact the administrator.',
        );
      }
      throw AppException(
        code: e.code,
        message:
            'First-time onboarding session failed: ${e.message ?? e.toString()}',
      );
    } catch (e) {
      throw AppException(
        code: 'onboarding-session-error',
        message: 'Failed to initiate first-time session: $e',
      );
    }
  }

  /// Signs in with email or student ID & password. Throws [AppException] on failure.
  Future<UserCredential> login(String emailOrStudentId, String password) async {
    final rawInput = emailOrStudentId.trim();
    final enteredPassword = password.trim();

    if (rawInput.isEmpty) {
      throw const AppException(
        code: 'empty-identifier',
        message: 'Please enter your Student ID or Email.',
      );
    }
    if (enteredPassword.isEmpty) {
      throw const AppException(
        code: 'empty-password',
        message: 'Please enter your password.',
      );
    }

    final isEmail = rawInput.contains('@');
    String email = rawInput;

    if (!isEmail) {
      // Input is a Student ID (e.g. "02000496332", "02000-496332", etc.)
      try {
        final cleanId = rawInput.replaceAll(RegExp(r'[-\s]'), '');

        // Query by cleaned student ID or raw student ID
        QuerySnapshot<Map<String, dynamic>> snap = await _firestore
            .collection(FirestorePaths.students)
            .where('studentId', isEqualTo: cleanId)
            .limit(1)
            .get();

        if (snap.docs.isEmpty && cleanId != rawInput) {
          snap = await _firestore
              .collection(FirestorePaths.students)
              .where('studentId', isEqualTo: rawInput)
              .limit(1)
              .get();
        }

        if (snap.docs.isEmpty) {
          throw const AppException(
            code: 'student-not-found',
            message:
                'No student record found with this Student ID. Please ensure your Student ID is correct.',
          );
        }

        final studentDoc = snap.docs.first;
        final data = studentDoc.data();
        final fetchedEmail = (data['email'] as String?)?.trim();
        final status = (data['status'] as String? ?? '').toUpperCase();

        if (status != 'ACTIVE') {
          throw const AppException(
            code: 'student-inactive',
            message: 'Your student account is not active. Please visit the SAO office.',
          );
        }

        final isProfileComplete = data['isProfileComplete'] as bool? ??
            (fetchedEmail != null &&
                fetchedEmail.isNotEmpty &&
                data['defaultPassword'] == null);
        final requiresPasswordChange =
            data['requiresPasswordChange'] as bool? ?? false;
        final hasDefaultPassword = data['defaultPassword'] != null &&
            data['defaultPassword'].toString().isNotEmpty;
        final isPasswordDefaultValid = _isDefaultOrFormulaPasswordValid(
          data: data,
          enteredPassword: enteredPassword,
        );

        final isFirstTimeUser = !isProfileComplete ||
            requiresPasswordChange ||
            hasDefaultPassword ||
            fetchedEmail == null ||
            fetchedEmail.isEmpty;

        // If the student has not finished onboarding OR entered their default formula password
        if (isFirstTimeUser || isPasswordDefaultValid) {
          if (!isPasswordDefaultValid) {
            throw const AppException(
              code: 'wrong-password',
              message:
                  'Incorrect password. For first-time login, please use your default credentials provided by the school (e.g. Capitalized Last Name + last 6 digits of Student No.).',
            );
          }

          return await _initiateFirstTimeOnboardingSession(studentDoc.reference);
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
        password: enteredPassword,
      );
    } on FirebaseAuthException catch (e) {
      // If logging in with email failed, check if this is a student attempting first-login with default credentials
      if (isEmail &&
          (e.code == 'user-not-found' ||
              e.code == 'invalid-credential' ||
              e.code == 'wrong-password' ||
              e.code == 'INVALID_LOGIN_CREDENTIALS')) {
        try {
          final snap = await _firestore
              .collection(FirestorePaths.students)
              .where('email', isEqualTo: email.toLowerCase())
              .limit(1)
              .get();

          if (snap.docs.isNotEmpty) {
            final studentDoc = snap.docs.first;
            final data = studentDoc.data();
            final status = (data['status'] as String? ?? '').toUpperCase();
            if (status == 'ACTIVE' &&
                _isDefaultOrFormulaPasswordValid(
                  data: data,
                  enteredPassword: enteredPassword,
                )) {
              return await _initiateFirstTimeOnboardingSession(
                  studentDoc.reference);
            }
          }
        } catch (_) {
          // Fall through to standard human-readable exception handling
        }
      }

      String humanMessage;
      switch (e.code) {
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
        case 'INVALID_LOGIN_CREDENTIALS':
          humanMessage =
              'Incorrect password or account credentials. Please try again.';
          break;
        case 'invalid-email':
          humanMessage =
              'Please enter a valid email address or 11-digit Student ID.';
          break;
        case 'user-disabled':
          humanMessage =
              'This student account has been disabled. Please contact SAO.';
          break;
        case 'too-many-requests':
          humanMessage =
              'Too many failed login attempts. Please wait a moment and try again.';
          break;
        default:
          humanMessage =
              e.message ?? 'An unknown authentication error occurred.';
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
        .where('authUid', isEqualTo: uid)
        .limit(1)
        .snapshots()
        .asyncMap((snap) async {
          if (snap.docs.isNotEmpty) {
            return StudentModel.fromFirestore(snap.docs.first);
          }
          final doc = await _firestore.collection(FirestorePaths.students).doc(uid).get();
          return doc.exists ? StudentModel.fromFirestore(doc) : null;
        });
  }

  /// One-time fetch of the student's Firestore document.
  Future<StudentModel?> getStudentProfile(String uid) async {
    try {
      final snap = await _firestore
          .collection(FirestorePaths.students)
          .where('authUid', isEqualTo: uid)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) {
        return StudentModel.fromFirestore(snap.docs.first);
      }
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

  /// Updates student profile fields in Firestore `students`.
  Future<void> updateStudentProfile(String uid, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      final docRef = _firestore.collection(FirestorePaths.students).doc(uid);
      final docSnap = await docRef.get();
      if (docSnap.exists) {
        await docRef.update(data);
      } else {
        final querySnap = await _firestore
            .collection(FirestorePaths.students)
            .where('authUid', isEqualTo: uid)
            .limit(1)
            .get();
        if (querySnap.docs.isNotEmpty) {
          await querySnap.docs.first.reference.update(data);
        } else {
          await docRef.update(data);
        }
      }
    } on FirebaseException catch (e) {
      throw AppException(
        code: e.code,
        message: e.message ?? 'Failed to update student profile.',
      );
    }
  }

  /// One-time fetch of the active semester document.
  Future<SemesterModel?> getActiveSemester() async {
    try {
      final snap = await _firestore.collection(FirestorePaths.semesters).get();
      if (snap.docs.isEmpty) return null;
      for (var doc in snap.docs) {
        final data = doc.data();
        final status = (data['status'] as String?)?.toUpperCase() ?? '';
        final isActive = data['isActive'] == true || data['isCurrent'] == true || data['is_active'] == true;
        if (status == 'ACTIVE' || isActive) {
          return SemesterModel.fromFirestore(doc);
        }
      }
      return SemesterModel.fromFirestore(snap.docs.first);
    } catch (_) {
      return null;
    }
  }
}
