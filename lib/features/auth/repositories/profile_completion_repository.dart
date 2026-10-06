import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../../core/constants/firestore_paths.dart';
import '../../../core/exceptions/app_exception.dart';
import '../../../services/cloudinary_service.dart';

/// Repository responsible for First-Login Profile Completion.
///
/// Handles Cloudinary asset uploads, Firebase Auth credential transitions
/// (updating from default password and provisional email to personal ones),
/// and atomic Firestore profile updates.
class ProfileCompletionRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final CloudinaryService _cloudinary;

  ProfileCompletionRepository(
    this._auth,
    this._firestore,
    this._cloudinary,
  );

  /// Checks if an email is already used by another student in Firestore.
  Future<bool> isEmailTaken(String email, {String? excludeUid}) async {
    try {
      final snap = await _firestore
          .collection(FirestorePaths.students)
          .where('email', isEqualTo: email.trim().toLowerCase())
          .get();
      for (final doc in snap.docs) {
        if (excludeUid != null && doc.id == excludeUid) continue;
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error checking email duplication: $e');
      return false;
    }
  }

  /// Checks if a contact number is already used by another student in Firestore.
  Future<bool> isContactNumberTaken(String contactNumber, {String? excludeUid}) async {
    final cleanDigits = contactNumber.replaceAll(RegExp(r'\D'), '');
    if (cleanDigits.isEmpty) return false;

    final tenDigits = cleanDigits.length == 10
        ? cleanDigits
        : (cleanDigits.length == 11 && cleanDigits.startsWith('0'))
            ? cleanDigits.substring(1)
            : (cleanDigits.length == 12 && cleanDigits.startsWith('63'))
                ? cleanDigits.substring(2)
                : cleanDigits;

    final candidateVariants = <String>{
      tenDigits,
      '0$tenDigits',
      '+63$tenDigits',
      '63$tenDigits',
      cleanDigits,
    }.toList();

    try {
      final snap = await _firestore
          .collection(FirestorePaths.students)
          .where('contactNumber', whereIn: candidateVariants)
          .get();

      for (final doc in snap.docs) {
        if (excludeUid != null && doc.id == excludeUid) continue;
        return true;
      }
    } catch (e) {
      debugPrint('Error checking contact number duplication: $e');
    }
    return false;
  }

  /// Uploads profile photo to Cloudinary under 'students/profile'.
  Future<String> uploadProfilePhoto(
    File file, {
    void Function(double progress)? onProgress,
  }) async {
    try {
      return await _cloudinary.uploadFile(
        file,
        folder: 'students/profile',
        onProgress: onProgress,
      );
    } catch (e) {
      throw AppException(
        code: 'profile-photo-upload-failed',
        message: 'Failed to upload profile photo: ${e.toString()}',
      );
    }
  }

  /// Uploads student school ID to Cloudinary under 'students/school-id'.
  Future<String> uploadSchoolId(
    File file, {
    void Function(double progress)? onProgress,
  }) async {
    try {
      return await _cloudinary.uploadFile(
        file,
        folder: 'students/school-id',
        onProgress: onProgress,
      );
    } catch (e) {
      throw AppException(
        code: 'school-id-upload-failed',
        message: 'Failed to upload School ID: ${e.toString()}',
      );
    }
  }

  /// Completes student first-login onboarding by updating Auth password,
  /// updating email, and setting `isProfileComplete = true` in Firestore.
  Future<void> completeAccount({
    String? uid,
    String? studentDocId,
    required String newPassword,
    required String personalEmail,
    required String contactNumber,
    required String dateOfBirth,
    required String profilePhotoUrl,
    required String schoolIdPhotoUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AppException(
        code: 'unauthenticated',
        message: 'No authenticated student session found. Please log in again.',
      );
    }

    final cleanEmail = personalEmail.trim().toLowerCase();

    // 1. Link anonymous first-login account or update existing credentials
    try {
      if (user.isAnonymous) {
        final credential = EmailAuthProvider.credential(
          email: cleanEmail,
          password: newPassword,
        );
        await user.linkWithCredential(credential);
      } else {
        await user.updatePassword(newPassword);
        try {
          await user.verifyBeforeUpdateEmail(cleanEmail);
        } catch (e) {
          debugPrint('Firebase Auth verifyBeforeUpdateEmail note: $e');
        }
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        throw const AppException(
          code: 'weak-password',
          message: 'The password is too weak. Please choose a stronger password.',
        );
      } else if (e.code == 'requires-recent-login') {
        throw const AppException(
          code: 'requires-recent-login',
          message: 'Your session has expired. Please log in again to continue.',
        );
      } else if (e.code == 'email-already-in-use') {
        throw const AppException(
          code: 'email-already-in-use',
          message: 'This email address is already registered to another account.',
        );
      }
      throw AppException(
        code: e.code,
        message: e.message ?? 'Failed to update account credentials.',
      );
    }

    // 2. Update Firestore student document
    try {
      final docIdToTry = (studentDocId != null && studentDocId.isNotEmpty)
          ? studentDocId
          : (uid != null && uid.isNotEmpty ? uid : '');

      DocumentReference targetRef =
          _firestore.collection(FirestorePaths.students).doc(docIdToTry);
      final docSnap = docIdToTry.isNotEmpty ? await targetRef.get() : null;

      if (docSnap == null || !docSnap.exists) {
        final querySnap = await _firestore
            .collection(FirestorePaths.students)
            .where('authUid', isEqualTo: user.uid)
            .limit(1)
            .get();
        if (querySnap.docs.isNotEmpty) {
          targetRef = querySnap.docs.first.reference;
        }
      }

      await targetRef.update({
        'authUid': user.uid,
        'email': cleanEmail,
        'contactNumber': contactNumber.trim(),
        'dateOfBirth': dateOfBirth.trim(),
        'profilePhotoUrl': profilePhotoUrl,
        'schoolIdPhotoUrl': schoolIdPhotoUrl,
        'isProfileComplete': true,
        'requiresPasswordChange': false,
        'requiresChangePassword': FieldValue.delete(),
        'defaultPassword': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw AppException(
        code: e.code,
        message: e.message ?? 'Failed to update student profile in database.',
      );
    }
  }
}
