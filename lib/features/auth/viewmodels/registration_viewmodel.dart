import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/student_model.dart';
import '../repositories/registration_repository.dart';

/// Total number of steps in the registration flow.
const int kRegistrationStepCount = 6;

// ─────────────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────────────

class RegistrationState {
  final int currentStep;

  // Step 1 — Personal Info
  final String lastName;
  final String firstName;
  final String middleName;
  final String studentId;
  final DateTime? dateOfBirth;
  final String sex;
  final String contactNumber;

  // Step 2 — Academic Details
  final String courseCode;
  final String courseName;
  final String yearLevel;
  final String section;
  final String departmentId;
  final String departmentName;
  final String semester;
  final String schoolYear;

  // Academic Data Fetching
  final bool isFetchingAcademicData;
  final List<Map<String, dynamic>> availableCourses;
  final List<Map<String, dynamic>> availableSections;

  // Step 3 — Credentials
  final String email;
  final String password;
  final String confirmPassword;

  // Step 4 — Profile Photo
  final File? profilePhotoFile;
  final String? existingProfilePhotoUrl;

  // Step 5 — School ID
  final File? schoolIdFile;
  final String? existingSchoolIdUrl;

  // Step 6 — Review
  final bool confirmedAccuracy;

  // Submission
  final String? existingUid; // If non-null, this is a resubmit
  final bool isSubmitting;
  final double submitProgress;
  final String submitProgressLabel;
  final String? submitError;
  final bool submitSuccess;
  final List<String> debugLog;

  const RegistrationState({
    this.currentStep = 0,
    this.lastName = '',
    this.firstName = '',
    this.middleName = '',
    this.studentId = '',
    this.dateOfBirth,
    this.sex = '',
    this.contactNumber = '',
    this.courseCode = '',
    this.courseName = '',
    this.yearLevel = '',
    this.section = '',
    this.departmentId = '',
    this.departmentName = '',
    this.semester = '',
    this.schoolYear = '',
    this.isFetchingAcademicData = false,
    this.availableCourses = const [],
    this.availableSections = const [],
    this.email = '',
    this.password = '',
    this.confirmPassword = '',
    this.profilePhotoFile,
    this.existingProfilePhotoUrl,
    this.schoolIdFile,
    this.existingSchoolIdUrl,
    this.confirmedAccuracy = false,
    this.existingUid,
    this.isSubmitting = false,
    this.submitProgress = 0,
    this.submitProgressLabel = '',
    this.submitError,
    this.submitSuccess = false,
    this.debugLog = const [],
  });

  bool get isResubmit => existingUid != null;
  bool get isLastStep => currentStep == kRegistrationStepCount - 1;
  bool get isFirstStep => currentStep == 0;
  bool get hasProfilePhoto => profilePhotoFile != null || (existingProfilePhotoUrl != null && existingProfilePhotoUrl!.isNotEmpty);
  bool get hasSchoolId => schoolIdFile != null || (existingSchoolIdUrl != null && existingSchoolIdUrl!.isNotEmpty);

  String get displayFullName {
    final mi = middleName.trim().isEmpty ? '' : ' ${middleName.trim()[0]}.';
    return '${lastName.trim()}, ${firstName.trim()}$mi';
  }

  /// Per-step validation. Returns null if valid, or an error message string.
  String? validateCurrentStep() {
    switch (currentStep) {
      case 0:
        return _validatePersonalInfo();
      case 1:
        return _validateAcademicDetails();
      case 2:
        return _validateCredentials();
      case 3:
        if (!hasProfilePhoto) return 'Please take or upload your profile photo.';
        return null;
      case 4:
        if (!hasSchoolId) return 'Please take or upload your school ID.';
        return null;
      case 5:
        if (!confirmedAccuracy) {
          return 'Please confirm that your information is accurate before submitting.';
        }
        return null;
      default:
        return null;
    }
  }

  String? _validatePersonalInfo() {
    if (lastName.trim().isEmpty) return 'Last name is required.';
    if (firstName.trim().isEmpty) return 'First name is required.';
    if (studentId.trim().isEmpty) return 'Student ID is required.';
    if (!RegExp(r'^\d{11}$').hasMatch(studentId.trim())) {
      return 'Student ID must be exactly 11 digits (e.g. 02000258377).';
    }
    if (dateOfBirth == null) return 'Date of birth is required.';
    if (sex.isEmpty) return 'Please select your sex.';
    final digits = contactNumber.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 10 || !digits.startsWith('9')) {
      return 'Contact number must be 10 digits starting with 9 (e.g. 9171234567).';
    }
    return null;
  }

  String? _validateAcademicDetails() {
    if (courseCode.isEmpty) return 'Please select a course.';
    if (yearLevel.isEmpty) return 'Please select your year level.';
    if (section.trim().isEmpty) return 'Section is required.';
    if (semester.isEmpty) return 'Please select a semester.';
    return null;
  }

  String? _validateCredentials() {
    if (isResubmit) return null; // Skip password validation on resubmit
    if (email.trim().isEmpty) return 'Email address is required.';
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email.trim())) {
      return 'Enter a valid email address.';
    }
    if (password.length < 8) return 'Password must be at least 8 characters.';
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter.';
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number.';
    }
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain at least one special character.';
    }
    if (password != confirmPassword) return 'Passwords do not match.';
    return null;
  }

  RegistrationState copyWith({
    int? currentStep,
    String? lastName,
    String? firstName,
    String? middleName,
    String? studentId,
    DateTime? dateOfBirth,
    String? sex,
    String? contactNumber,
    String? courseCode,
    String? courseName,
    String? yearLevel,
    String? section,
    String? departmentId,
    String? departmentName,
    String? semester,
    String? schoolYear,
    bool? isFetchingAcademicData,
    List<Map<String, dynamic>>? availableCourses,
    List<Map<String, dynamic>>? availableSections,
    String? email,
    String? password,
    String? confirmPassword,
    File? profilePhotoFile,
    bool clearProfilePhoto = false,
    String? existingProfilePhotoUrl,
    File? schoolIdFile,
    bool clearSchoolId = false,
    String? existingSchoolIdUrl,
    bool? confirmedAccuracy,
    String? existingUid,
    bool? isSubmitting,
    double? submitProgress,
    String? submitProgressLabel,
    String? submitError,
    bool clearSubmitError = false,
    bool? submitSuccess,
    List<String>? debugLog,
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
      courseCode: courseCode ?? this.courseCode,
      courseName: courseName ?? this.courseName,
      yearLevel: yearLevel ?? this.yearLevel,
      section: section ?? this.section,
      departmentId: departmentId ?? this.departmentId,
      departmentName: departmentName ?? this.departmentName,
      semester: semester ?? this.semester,
      schoolYear: schoolYear ?? this.schoolYear,
      isFetchingAcademicData: isFetchingAcademicData ?? this.isFetchingAcademicData,
      availableCourses: availableCourses ?? this.availableCourses,
      availableSections: availableSections ?? this.availableSections,
      email: email ?? this.email,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      profilePhotoFile:
          clearProfilePhoto ? null : (profilePhotoFile ?? this.profilePhotoFile),
      existingProfilePhotoUrl: existingProfilePhotoUrl ?? this.existingProfilePhotoUrl,
      schoolIdFile:
          clearSchoolId ? null : (schoolIdFile ?? this.schoolIdFile),
      existingSchoolIdUrl: existingSchoolIdUrl ?? this.existingSchoolIdUrl,
      confirmedAccuracy: confirmedAccuracy ?? this.confirmedAccuracy,
      existingUid: existingUid ?? this.existingUid,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitProgress: submitProgress ?? this.submitProgress,
      submitProgressLabel: submitProgressLabel ?? this.submitProgressLabel,
      submitError: clearSubmitError ? null : (submitError ?? this.submitError),
      submitSuccess: submitSuccess ?? this.submitSuccess,
      debugLog: debugLog ?? this.debugLog,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ViewModel
// ─────────────────────────────────────────────────────────────────────────────

class RegistrationViewModel extends StateNotifier<RegistrationState> {
  final RegistrationRepository _repo;

  RegistrationViewModel(this._repo) : super(const RegistrationState()) {
    _fetchInitialAcademicData();
  }

  void reset() {
    state = const RegistrationState();
    _fetchInitialAcademicData();
  }

  Future<void> _fetchInitialAcademicData() async {
    state = state.copyWith(isFetchingAcademicData: true);
    try {
      final courses = await _repo.getCourses();
      final activeSemester = await _repo.getActiveSemester();

      String sem = '';
      String sy = '';
      if (activeSemester != null) {
        sem = (activeSemester['name'] as String?) ?? (activeSemester['semester'] as String?) ?? (activeSemester['term'] as String?) ?? '';
        sy = (activeSemester['academicYear'] as String?) ?? (activeSemester['schoolYear'] as String?) ?? (activeSemester['year'] as String?) ?? '';
      }

      state = state.copyWith(
        availableCourses: courses,
        semester: sem,
        schoolYear: sy,
        isFetchingAcademicData: false,
      );
    } catch (e) {
      state = state.copyWith(isFetchingAcademicData: false);
    }
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  String? validateStep(int stepIndex) {
    final s = state;
    switch (stepIndex) {
      case 0:
        if (s.lastName.trim().isEmpty) return 'Last name is required.';
        if (s.firstName.trim().isEmpty) return 'First name is required.';
        if (!RegExp(r'^\d{11}$').hasMatch(s.studentId.trim())) {
          return 'Student ID must be exactly 11 digits.';
        }
        if (s.dateOfBirth == null) return 'Date of birth is required.';
        if (s.sex.isEmpty) return 'Please select your sex.';
        final digits = s.contactNumber.replaceAll(RegExp(r'\D'), '');
        if (digits.length != 10 || !digits.startsWith('9')) {
          return 'Contact number must be 10 digits starting with 9.';
        }
        return null;
      case 1:
        if (s.courseCode.isEmpty) return 'Please select a course.';
        if (s.yearLevel.isEmpty) return 'Please select your year level.';
        if (s.section.trim().isEmpty) return 'Section is required.';
        if (s.semester.isEmpty) return 'Please select a semester.';
        return null;
      case 2:
        if (s.email.trim().isEmpty) return 'Email address is required.';
        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(s.email.trim())) {
          return 'Enter a valid email address.';
        }
        if (!s.isResubmit) {
          if (s.password.length < 8) return 'Password must be at least 8 characters.';
          if (!s.password.contains(RegExp(r'[A-Z]'))) {
            return 'Password must contain at least one uppercase letter.';
          }
          if (!s.password.contains(RegExp(r'[0-9]'))) {
            return 'Password must contain at least one number.';
          }
          if (!s.password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
            return 'Password must contain at least one special character.';
          }
          if (s.password != s.confirmPassword) return 'Passwords do not match.';
        }
        return null;
      case 3:
        if (!s.hasProfilePhoto) return 'Please take or upload your profile photo.';
        return null;
      case 4:
        if (!s.hasSchoolId) return 'Please take or upload your school ID.';
        return null;
      case 5:
        if (!s.confirmedAccuracy) {
          return 'Please confirm that your information is accurate before submitting.';
        }
        return null;
      default:
        return null;
    }
  }

  void nextStep() {
    if (!state.isLastStep) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  String? tryNextStep() {
    final error = validateStep(state.currentStep);
    if (error != null) return error;
    if (!state.isLastStep) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
    return null;
  }

  void previousStep() {
    if (!state.isFirstStep) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  void goToStep(int index) {
    if (index >= 0 && index < kRegistrationStepCount) {
      state = state.copyWith(currentStep: index);
    }
  }

  // ── Field setters ─────────────────────────────────────────────────────────

  void setLastName(String v) => state = state.copyWith(lastName: v);
  void setFirstName(String v) => state = state.copyWith(firstName: v);
  void setMiddleName(String v) => state = state.copyWith(middleName: v);
  void setStudentId(String v) => state = state.copyWith(studentId: v);
  void setDateOfBirth(DateTime v) => state = state.copyWith(dateOfBirth: v);
  void setSex(String v) => state = state.copyWith(sex: v);
  void setContactNumber(String v) => state = state.copyWith(contactNumber: v);

  void setCourse(String courseId) async {
    final courseMap = state.availableCourses.firstWhere(
      (c) => c['id'] == courseId || c['courseCode'] == courseId || c['code'] == courseId,
      orElse: () => <String, dynamic>{},
    );

    final codeForDisplay = (courseMap['courseCode'] as String?) ?? (courseMap['code'] as String?) ?? (courseMap['id'] as String?) ?? '';

    state = state.copyWith(
      courseCode: codeForDisplay,
      courseName: courseMap['name'] ?? '',
      departmentId: courseMap['departmentId'] ?? '',
      departmentName: courseMap['departmentName'] ?? '',
      section: '', // clear section
      availableSections: [],
      isFetchingAcademicData: true,
    );

    try {
      final deptId = courseMap['departmentId'];
      String fetchedDeptName = courseMap['departmentName'] ?? '';
      
      if (deptId != null && deptId.toString().isNotEmpty && fetchedDeptName.isEmpty) {
        final deptSnap = await _repo.getDepartment(deptId);
        if (deptSnap != null) {
          fetchedDeptName = deptSnap['name'] ?? deptSnap['departmentName'] ?? '';
        }
      }

      final sections = await _repo.getSections(courseId);
      state = state.copyWith(
        departmentName: fetchedDeptName,
        availableSections: sections,
        isFetchingAcademicData: false,
      );
    } catch (e) {
      state = state.copyWith(isFetchingAcademicData: false);
    }
  }

  void setYearLevel(String v) => state = state.copyWith(yearLevel: v);
  void setSection(String v) => state = state.copyWith(section: v);
  void setSemester(String v) => state = state.copyWith(semester: v);
  void setEmail(String v) => state = state.copyWith(email: v);
  void setPassword(String v) => state = state.copyWith(password: v);
  void setConfirmPassword(String v) =>
      state = state.copyWith(confirmPassword: v);

  void setProfilePhotoFile(File? f) => f == null
      ? state = state.copyWith(clearProfilePhoto: true)
      : state = state.copyWith(profilePhotoFile: f);

  void setSchoolIdFile(File? f) => f == null
      ? state = state.copyWith(clearSchoolId: true)
      : state = state.copyWith(schoolIdFile: f);

  void setConfirmedAccuracy(bool v) =>
      state = state.copyWith(confirmedAccuracy: v);

  void clearSubmitError() => state = state.copyWith(clearSubmitError: true);

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<void> populateFromStudent(StudentModel student) async {
    state = state.copyWith(
      existingUid: student.id,
      lastName: student.lastName,
      firstName: student.firstName,
      middleName: student.middleName,
      studentId: student.studentId,
      dateOfBirth: DateTime.tryParse(student.dateOfBirth),
      sex: student.sex,
      contactNumber: student.contactNumber,
      courseCode: student.courseCode.isNotEmpty ? student.courseCode : student.courseId,
      courseName: student.courseName,
      yearLevel: student.yearLevel,
      section: student.section,
      departmentId: student.departmentId,
      departmentName: student.departmentName,
      semester: student.semester,
      schoolYear: student.schoolYear,
      email: student.email,
      existingProfilePhotoUrl: student.profilePhotoUrl,
      existingSchoolIdUrl: student.schoolIdPhotoUrl,
      currentStep: 0,
    );
    
    // Fetch sections for the pre-populated course directly so the dropdown works.
    // We use courseId if available, otherwise courseCode.
    final targetCourseId = student.courseId.isNotEmpty ? student.courseId : student.courseCode;
    if (targetCourseId.isNotEmpty) {
      state = state.copyWith(isFetchingAcademicData: true);
      try {
        final sections = await _repo.getSections(targetCourseId);
        state = state.copyWith(
          availableSections: sections,
          isFetchingAcademicData: false,
        );
      } catch (e) {
        state = state.copyWith(isFetchingAcademicData: false);
      }
    }
  }

  // ── Submission ────────────────────────────────────────────────────────────

  Future<bool> submit() async {
    final s = state;
    
    // Check for missing files explicitly before starting
    if (!s.hasProfilePhoto) {
      state = state.copyWith(
        isSubmitting: false,
        submitError: 'Profile photo is missing. Please go back and take a photo.',
      );
      return false;
    }
    if (!s.hasSchoolId) {
      state = state.copyWith(
        isSubmitting: false,
        submitError: 'School ID photo is missing. Please go back and take a photo.',
      );
      return false;
    }
    
    state = state.copyWith(isSubmitting: true, submitError: null);

    state = state.copyWith(
      isSubmitting: true,
      clearSubmitError: true,
      submitProgress: 0,
      submitProgressLabel: 'Preparing…',
    );

    final dob = s.dateOfBirth!;
    final dobStr =
        '${dob.year}-${dob.month.toString().padLeft(2, '0')}-${dob.day.toString().padLeft(2, '0')}';
    final digits = s.contactNumber.replaceAll(RegExp(r'\D'), '');

    final model = StudentModel(
      id: s.existingUid ?? '',
      authUid: s.existingUid ?? '',
      lastName: s.lastName.trim(),
      firstName: s.firstName.trim(),
      middleName: s.middleName.trim(),
      studentId: s.studentId.trim(),
      dateOfBirth: dobStr,
      sex: s.sex,
      contactNumber: digits,
      courseId: s.courseCode,
      courseName: s.courseName,
      courseCode: s.courseCode,
      departmentId: s.departmentId,
      departmentName: s.departmentName,
      yearLevel: s.yearLevel,
      section: s.section.trim(),
      schoolYear: s.schoolYear,
      semester: s.semester,
      email: s.email.trim().toLowerCase(),
      profilePhotoUrl: '',
      schoolIdPhotoUrl: '',
      status: 'PENDING',
      registrationSource: 'SELF_REGISTER',
      addedBy: 'self',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      rejectionReason: null, // Clear rejection reason on resubmit
    );

    try {
      if (s.isResubmit) {
        await _repo.resubmit(
          uid: s.existingUid!,
          data: model,
          profilePhotoFile: s.profilePhotoFile,
          existingProfilePhotoUrl: s.existingProfilePhotoUrl,
          schoolIdFile: s.schoolIdFile,
          existingSchoolIdUrl: s.existingSchoolIdUrl,
          onProgress: (progress, label) {
            state = state.copyWith(
              submitProgress: progress,
              submitProgressLabel: label,
            );
          },
        );
      } else {
        await _repo.register(
          data: model,
          password: s.password,
          profilePhotoFile: s.profilePhotoFile!,
          schoolIdFile: s.schoolIdFile!,
          onProgress: (progress, label) {
            state = state.copyWith(
              submitProgress: progress,
              submitProgressLabel: label,
            );
          },
        );
      }
      state = state.copyWith(isSubmitting: false, submitSuccess: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        submitError: 'Failed to submit registration. Please try again.',
        debugLog: [...s.debugLog, 'Submit error: $e'],
      );
      return false;
    }
  }
}
