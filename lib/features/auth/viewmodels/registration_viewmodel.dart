import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Total number of steps in the registration flow.
const int kRegistrationStepCount = 6;

/// Immutable state for the multi-step student registration flow.
///
/// Holds the current step index plus every value the user has entered so the
/// final Review step can display real data and back navigation preserves input.
class RegistrationState {
  final int currentStep; // 0-based index, 0..5

  // ─── Step 1: Personal Info ───
  final String lastName;
  final String firstName;
  final String middleName;
  final String studentId;
  final DateTime? dateOfBirth;
  final String sex; // 'Male' | 'Female' | ''
  final String contactNumber;

  // ─── Step 2: Academic Details ───
  final String course;
  final String yearLevel;
  final String section;
  final String department; // Auto-filled from selected course
  final String semester;

  // ─── Step 3: Credentials ───
  final String email;
  final String password;
  final String confirmPassword;

  // ─── Step 4 & 5: Media (placeholder flags until upload is wired) ───
  final bool hasProfilePhoto;
  final bool hasSchoolId;

  // ─── Step 6: Review ───
  final bool confirmedAccuracy;

  const RegistrationState({
    this.currentStep = 0,
    this.lastName = '',
    this.firstName = '',
    this.middleName = '',
    this.studentId = '',
    this.dateOfBirth,
    this.sex = '',
    this.contactNumber = '',
    this.course = '',
    this.yearLevel = '',
    this.section = '',
    this.department = '',
    this.semester = '',
    this.email = '',
    this.password = '',
    this.confirmPassword = '',
    this.hasProfilePhoto = false,
    this.hasSchoolId = false,
    this.confirmedAccuracy = false,
  });
  /// Returns a copy of this state with the provided fields overridden.
  RegistrationState copyWith({
    int? currentStep,
    String? lastName,
    String? firstName,
    String? middleName,
    String? studentId,
    DateTime? dateOfBirth,
    String? sex,
    String? contactNumber,
    String? course,
    String? yearLevel,
    String? section,
    String? department,
    String? semester,
    String? email,
    String? password,
    String? confirmPassword,
    bool? hasProfilePhoto,
    bool? hasSchoolId,
    bool? confirmedAccuracy,
  }) {
    return RegistrationState(
      currentStep: currentStep ?? this.currentStep,
      lastName: lastName ?? this.lastName,
      firstName: firstName ?? this.firstName,
      middleName: middleName ?? this.middleName,
      studentId: studentId ?? this.studentId,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      sex: sex ?? this.sex,
      contactNumber: contactNumber ?? this.contactNumber,
      course: course ?? this.course,
      yearLevel: yearLevel ?? this.yearLevel,
      section: section ?? this.section,
      department: department ?? this.department,
      semester: semester ?? this.semester,
      email: email ?? this.email,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      hasProfilePhoto: hasProfilePhoto ?? this.hasProfilePhoto,
      hasSchoolId: hasSchoolId ?? this.hasSchoolId,
      confirmedAccuracy: confirmedAccuracy ?? this.confirmedAccuracy,
    );
  }

  /// Whether the user is on the final (Review) step.
  bool get isLastStep => currentStep == kRegistrationStepCount - 1;

  /// Whether the user is on the first step.
  bool get isFirstStep => currentStep == 0;

  /// Denormalized full name shown on the review card: "dela Cruz, Juan M.".
  String get displayFullName {
    final mi = middleName.trim().isEmpty ? '' : ' ${middleName.trim()[0]}.';
    return '$lastName, $firstName$mi';
  }
}

/// Drives the multi-step registration flow: step navigation + form capture.
///
/// Holds no Firestore logic — submission/validation is wired separately.
class RegistrationViewModel extends StateNotifier<RegistrationState> {
  RegistrationViewModel() : super(const RegistrationState());

  /// Advances to the next step (capped at the last step).
  void nextStep() {
    if (state.currentStep < kRegistrationStepCount - 1) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  /// Returns to the previous step (floored at the first step).
  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  /// Jumps directly to a step index (used by "Tap any field to edit").
  void goToStep(int index) {
    if (index >= 0 && index < kRegistrationStepCount) {
      state = state.copyWith(currentStep: index);
    }
  }

  // ─── Field setters ───
  void setLastName(String v) => state = state.copyWith(lastName: v);
  void setFirstName(String v) => state = state.copyWith(firstName: v);
  void setMiddleName(String v) => state = state.copyWith(middleName: v);
  void setStudentId(String v) => state = state.copyWith(studentId: v);
  void setDateOfBirth(DateTime v) => state = state.copyWith(dateOfBirth: v);
  void setSex(String v) => state = state.copyWith(sex: v);
  void setContactNumber(String v) => state = state.copyWith(contactNumber: v);

  /// Sets the course and auto-fills the owning department.
  void setCourse(String v) =>
      state = state.copyWith(course: v, department: _departmentForCourse(v));
  void setYearLevel(String v) => state = state.copyWith(yearLevel: v);
  void setSection(String v) => state = state.copyWith(section: v);
  void setSemester(String v) => state = state.copyWith(semester: v);

  void setEmail(String v) => state = state.copyWith(email: v);
  void setPassword(String v) => state = state.copyWith(password: v);
  void setConfirmPassword(String v) =>
      state = state.copyWith(confirmPassword: v);

  void setHasProfilePhoto(bool v) =>
      state = state.copyWith(hasProfilePhoto: v);
  void setHasSchoolId(bool v) => state = state.copyWith(hasSchoolId: v);
  void setConfirmedAccuracy(bool v) =>
      state = state.copyWith(confirmedAccuracy: v);

  /// Maps a course code to its owning department for the auto-fill field.
  String _departmentForCourse(String course) {
    switch (course) {
      case 'BSIT':
      case 'BSCS':
      case 'BSCE':
        return 'ICT';
      case 'BSED':
        return 'Education';
      case 'BSA':
      case 'BSBA':
        return 'Business & Accountancy';
      default:
        return '';
    }
  }
}

/// Provider for the registration flow. `autoDispose` clears entered data once
/// the user leaves the flow so a fresh registration starts clean.
final registrationViewModelProvider =
    StateNotifierProvider.autoDispose<RegistrationViewModel, RegistrationState>(
  (ref) => RegistrationViewModel(),
);
