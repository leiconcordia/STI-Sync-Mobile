import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/student_model.dart';
import '../repositories/profile_completion_repository.dart';

class ProfileCompletionState {
  final int currentStep;

  // Step 0: Security & Credentials
  final String newPassword;
  final String confirmPassword;
  final bool isPasswordVisible;
  final bool isConfirmPasswordVisible;
  final String personalEmail;

  // Step 1: Personal Contact Info
  final DateTime? dateOfBirth;
  final String contactNumber;

  // Step 2: Identity Photos
  final File? profilePhotoFile;
  final File? schoolIdPhotoFile;

  // Step 3: Review & Submit
  final bool confirmedAccuracy;

  // Submission Status
  final bool isSubmitting;
  final double submitProgress;
  final String submitProgressLabel;
  final String? submitError;
  final bool submitSuccess;

  const ProfileCompletionState({
    this.currentStep = 0,
    this.newPassword = '',
    this.confirmPassword = '',
    this.isPasswordVisible = false,
    this.isConfirmPasswordVisible = false,
    this.personalEmail = '',
    this.dateOfBirth,
    this.contactNumber = '',
    this.profilePhotoFile,
    this.schoolIdPhotoFile,
    this.confirmedAccuracy = false,
    this.isSubmitting = false,
    this.submitProgress = 0.0,
    this.submitProgressLabel = '',
    this.submitError,
    this.submitSuccess = false,
  });

  bool get isFirstStep => currentStep == 0;
  bool get isLastStep => currentStep == 3;

  ProfileCompletionState copyWith({
    int? currentStep,
    String? newPassword,
    String? confirmPassword,
    bool? isPasswordVisible,
    bool? isConfirmPasswordVisible,
    String? personalEmail,
    DateTime? dateOfBirth,
    String? contactNumber,
    File? profilePhotoFile,
    File? schoolIdPhotoFile,
    bool? confirmedAccuracy,
    bool? isSubmitting,
    double? submitProgress,
    String? submitProgressLabel,
    String? submitError,
    bool? submitSuccess,
    bool clearDateOfBirth = false,
    bool clearError = false,
  }) {
    return ProfileCompletionState(
      currentStep: currentStep ?? this.currentStep,
      newPassword: newPassword ?? this.newPassword,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      isPasswordVisible: isPasswordVisible ?? this.isPasswordVisible,
      isConfirmPasswordVisible: isConfirmPasswordVisible ?? this.isConfirmPasswordVisible,
      personalEmail: personalEmail ?? this.personalEmail,
      dateOfBirth: clearDateOfBirth ? null : (dateOfBirth ?? this.dateOfBirth),
      contactNumber: contactNumber ?? this.contactNumber,
      profilePhotoFile: profilePhotoFile ?? this.profilePhotoFile,
      schoolIdPhotoFile: schoolIdPhotoFile ?? this.schoolIdPhotoFile,
      confirmedAccuracy: confirmedAccuracy ?? this.confirmedAccuracy,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitProgress: submitProgress ?? this.submitProgress,
      submitProgressLabel: submitProgressLabel ?? this.submitProgressLabel,
      submitError: clearError ? null : (submitError ?? this.submitError),
      submitSuccess: submitSuccess ?? this.submitSuccess,
    );
  }
}

class ProfileCompletionViewModel extends StateNotifier<ProfileCompletionState> {
  final ProfileCompletionRepository _repository;

  ProfileCompletionViewModel(this._repository) : super(const ProfileCompletionState());

  void setStep(int step) {
    if (step >= 0 && step <= 3) {
      state = state.copyWith(currentStep: step, clearError: true);
    }
  }

  void nextStep() {
    if (state.currentStep < 3) {
      state = state.copyWith(currentStep: state.currentStep + 1, clearError: true);
    }
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1, clearError: true);
    }
  }

  // ── Setters ────────────────────────────────────────────────────────────────
  void setNewPassword(String val) =>
      state = state.copyWith(newPassword: val, clearError: true);

  void setConfirmPassword(String val) =>
      state = state.copyWith(confirmPassword: val, clearError: true);

  void togglePasswordVisibility() =>
      state = state.copyWith(isPasswordVisible: !state.isPasswordVisible);

  void toggleConfirmPasswordVisibility() =>
      state = state.copyWith(isConfirmPasswordVisible: !state.isConfirmPasswordVisible);

  void setPersonalEmail(String val) =>
      state = state.copyWith(personalEmail: val.trim(), clearError: true);

  void setDateOfBirth(DateTime? val) =>
      state = state.copyWith(dateOfBirth: val, clearError: true);

  void setContactNumber(String val) {
    // Strip non-digits and normalize
    var clean = val.replaceAll(RegExp(r'\D'), '');
    if (clean.startsWith('0')) clean = clean.substring(1);
    if (clean.startsWith('63')) clean = clean.substring(2);
    if (clean.length > 10) clean = clean.substring(0, 10);
    state = state.copyWith(contactNumber: clean, clearError: true);
  }

  void setProfilePhotoFile(File? file) =>
      state = state.copyWith(profilePhotoFile: file, clearError: true);

  void setSchoolIdPhotoFile(File? file) =>
      state = state.copyWith(schoolIdPhotoFile: file, clearError: true);

  void setConfirmedAccuracy(bool val) =>
      state = state.copyWith(confirmedAccuracy: val, clearError: true);

  void clearError() => state = state.copyWith(clearError: true);

  // ── Validations ────────────────────────────────────────────────────────────

  /// Synchronous validation for Step 0 (Credentials).
  String? validateCredentials(StudentModel? student) {
    final pwd = state.newPassword.trim();
    final confirm = state.confirmPassword.trim();
    final email = state.personalEmail.trim();

    if (pwd.isEmpty) return 'Please enter a new password.';
    if (pwd.length < 8) return 'Password must be at least 8 characters long.';
    if (!RegExp(r'[A-Z]').hasMatch(pwd)) {
      return 'Password must contain at least one uppercase letter (A-Z).';
    }
    if (!RegExp(r'[0-9]').hasMatch(pwd) && !RegExp(r'[!@#\$&*~%^()_+=|<>?{}\[\]-]').hasMatch(pwd)) {
      return 'Password must contain at least one number or special character.';
    }

    // Ensure student is not reusing the initial default temporary password, formula, or Student ID
    if (student != null) {
      final cleanPwd = pwd.trim().toLowerCase();
      final noSpacePwd = cleanPwd.replaceAll(RegExp(r'[\s\-]'), '');

      // 1. Direct match with stored defaultPassword in Firestore
      if (student.defaultPassword != null && student.defaultPassword!.trim().isNotEmpty) {
        final defPwdClean = student.defaultPassword!.trim().toLowerCase();
        final defPwdNoSpace = defPwdClean.replaceAll(RegExp(r'[\s\-]'), '');
        if (cleanPwd == defPwdClean || noSpacePwd == defPwdNoSpace) {
          return 'You cannot reuse the default temporary password. Please choose a new private password.';
        }
      }

      // 2. Default formula variations (Caps(LastName) + last 6 digits of Student No.)
      final rawLastName = student.lastName.trim();
      final rawStudentId = student.studentId.trim();
      final sIdDigits = rawStudentId.replaceAll(RegExp(r'\D'), '');
      final last6 = sIdDigits.length >= 6
          ? sIdDigits.substring(sIdDigits.length - 6)
          : sIdDigits;

      if (rawLastName.isNotEmpty && last6.isNotEmpty) {
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

        final normalizedLast = normalizeAccents(rawLastName);
        final lettersOnly = normalizedLast.replaceAll(RegExp(r'[^a-zA-Z]'), '').toLowerCase();
        final noSpaceLast = normalizedLast.replaceAll(RegExp(r'\s+'), '').toLowerCase();
        final rawLastLower = rawLastName.toLowerCase();

        final forbiddenCandidates = <String>{
          '$lettersOnly$last6',
          '$noSpaceLast$last6',
          '$rawLastLower$last6',
          if (sIdDigits.isNotEmpty) sIdDigits,
          if (rawStudentId.isNotEmpty) rawStudentId.toLowerCase(),
        };

        for (final forbidden in forbiddenCandidates) {
          if (cleanPwd == forbidden || noSpacePwd == forbidden.replaceAll(RegExp(r'[\s\-]'), '')) {
            return 'You cannot reuse the default temporary password. Please choose a new private password.';
          }
        }
      }
    }

    if (confirm.isEmpty) return 'Please confirm your new password.';
    if (pwd != confirm) return 'Passwords do not match.';

    if (email.isEmpty) return 'Please enter your personal email address.';
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(email)) {
      return 'Please enter a valid email address (e.g. name@gmail.com).';
    }
    if (email.toLowerCase().endsWith('@student.sti.edu')) {
      return 'Please enter your personal email address (e.g. Gmail, Yahoo, Outlook) instead of the temporary student ID domain.';
    }

    return null;
  }

  /// Asynchronous validation for Step 0 (Duplicate email check).
  Future<String?> validateCredentialsAsync(String currentUid) async {
    final isTaken = await _repository.isEmailTaken(state.personalEmail, excludeUid: currentUid);
    if (isTaken) {
      return 'This email address is already registered to another account.';
    }
    return null;
  }

  /// Synchronous validation for Step 1 (Personal Contact Details).
  String? validatePersonalInfo() {
    if (state.dateOfBirth == null) return 'Please select your Date of Birth.';

    final dob = state.dateOfBirth!;
    final now = DateTime.now();
    var age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
      age--;
    }

    if (age < 14) {
      return 'You must be at least 14 years old to register.';
    }
    if (age > 80) {
      return 'Please enter a valid Date of Birth.';
    }

    final phone = state.contactNumber.trim();
    if (phone.isEmpty) return 'Please enter your mobile contact number.';
    if (!RegExp(r'^9\d{9}$').hasMatch(phone)) {
      return 'Please enter a valid 10-digit mobile number starting with 9 (e.g. 9171234567).';
    }

    return null;
  }

  /// Asynchronous validation for Step 1 (Duplicate contact number check).
  Future<String?> validatePersonalInfoAsync(String currentUid) async {
    final isTaken = await _repository.isContactNumberTaken(state.contactNumber, excludeUid: currentUid);
    if (isTaken) {
      return 'This contact number is already registered to another student.';
    }
    return null;
  }

  /// Validation for Step 2 (Photos).
  String? validatePhotos() {
    if (state.profilePhotoFile == null) {
      return 'Please take or upload your Profile Photo (Selfie / ID Headshot).';
    }
    if (state.schoolIdPhotoFile == null) {
      return 'Please take or upload a photo of your School ID card or Registration Form.';
    }
    return null;
  }

  /// Validation for Step 3 (Review & Confirmation).
  String? validateReview() {
    if (!state.confirmedAccuracy) {
      return 'Please certify that the information and photos submitted are accurate.';
    }
    return null;
  }

  /// Submits the profile completion data.
  Future<bool> submit(StudentModel student) async {
    // Re-validate all steps before submitting
    final credError = validateCredentials(student);
    if (credError != null) {
      state = state.copyWith(submitError: credError, currentStep: 0);
      return false;
    }

    final infoError = validatePersonalInfo();
    if (infoError != null) {
      state = state.copyWith(submitError: infoError, currentStep: 1);
      return false;
    }

    final photoError = validatePhotos();
    if (photoError != null) {
      state = state.copyWith(submitError: photoError, currentStep: 2);
      return false;
    }

    final reviewError = validateReview();
    if (reviewError != null) {
      state = state.copyWith(submitError: reviewError, currentStep: 3);
      return false;
    }

    state = state.copyWith(
      isSubmitting: true,
      submitProgress: 0.1,
      submitProgressLabel: 'Checking account availability…',
      clearError: true,
    );

    try {
      // Async uniqueness check
      final emailTaken = await _repository.isEmailTaken(state.personalEmail, excludeUid: student.id);
      if (emailTaken) {
        state = state.copyWith(
          isSubmitting: false,
          submitError: 'This personal email is already in use by another account.',
          currentStep: 0,
        );
        return false;
      }

      final phoneTaken = await _repository.isContactNumberTaken(state.contactNumber, excludeUid: student.id);
      if (phoneTaken) {
        state = state.copyWith(
          isSubmitting: false,
          submitError: 'This mobile number is already registered to another student.',
          currentStep: 1,
        );
        return false;
      }

      // 1. Upload Profile Photo
      state = state.copyWith(
        submitProgress: 0.35,
        submitProgressLabel: 'Uploading profile photo…',
      );
      final profileUrl = await _repository.uploadProfilePhoto(
        state.profilePhotoFile!,
        onProgress: (p) {
          state = state.copyWith(submitProgress: 0.35 + (p * 0.25));
        },
      );

      // 2. Upload School ID Photo
      state = state.copyWith(
        submitProgress: 0.65,
        submitProgressLabel: 'Uploading school ID photo…',
      );
      final schoolIdUrl = await _repository.uploadSchoolId(
        state.schoolIdPhotoFile!,
        onProgress: (p) {
          state = state.copyWith(submitProgress: 0.65 + (p * 0.20));
        },
      );

      // 3. Finalize Credentials & Database
      state = state.copyWith(
        submitProgress: 0.90,
        submitProgressLabel: 'Securing your account credentials…',
      );

      final dobFormatted = state.dateOfBirth != null
          ? '${state.dateOfBirth!.year.toString().padLeft(4, '0')}-${state.dateOfBirth!.month.toString().padLeft(2, '0')}-${state.dateOfBirth!.day.toString().padLeft(2, '0')}'
          : '';

      await _repository.completeAccount(
        studentDocId: student.id,
        uid: student.id,
        newPassword: state.newPassword.trim(),
        personalEmail: state.personalEmail.trim(),
        contactNumber: state.contactNumber.trim(),
        dateOfBirth: dobFormatted,
        profilePhotoUrl: profileUrl,
        schoolIdPhotoUrl: schoolIdUrl,
      );

      state = state.copyWith(
        isSubmitting: false,
        submitProgress: 1.0,
        submitProgressLabel: 'Account setup complete!',
        submitSuccess: true,
      );
      return true;
    } catch (e) {
      debugPrint('Profile completion submission error: $e');
      state = state.copyWith(
        isSubmitting: false,
        submitError: e.toString().replaceFirst(RegExp(r'^[A-Za-z]+Exception:\s*'), ''),
      );
      return false;
    }
  }

  void reset() {
    state = const ProfileCompletionState();
  }
}
