import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sti_sync/features/auth/models/student_model.dart';
import '../models/semester_model.dart';
import '../repositories/semester_repository.dart';
import '../../../shared/providers/providers.dart';

class ReEnrollmentState {
  final bool isLoadingSections;
  final List<String> sections;
  final String selectedYearLevel;
  final String selectedSection;
  final bool isConfirmed;
  final bool isSubmitting;
  final bool isSuccess;
  final String? errorMessage;

  const ReEnrollmentState({
    this.isLoadingSections = false,
    this.sections = const [],
    this.selectedYearLevel = '1st Year',
    this.selectedSection = '',
    this.isConfirmed = false,
    this.isSubmitting = false,
    this.isSuccess = false,
    this.errorMessage,
  });

  ReEnrollmentState copyWith({
    bool? isLoadingSections,
    List<String>? sections,
    String? selectedYearLevel,
    String? selectedSection,
    bool? isConfirmed,
    bool? isSubmitting,
    bool? isSuccess,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ReEnrollmentState(
      isLoadingSections: isLoadingSections ?? this.isLoadingSections,
      sections: sections ?? this.sections,
      selectedYearLevel: selectedYearLevel ?? this.selectedYearLevel,
      selectedSection: selectedSection ?? this.selectedSection,
      isConfirmed: isConfirmed ?? this.isConfirmed,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class ReEnrollmentViewModel extends StateNotifier<ReEnrollmentState> {
  final SemesterRepository _repository;

  ReEnrollmentViewModel(this._repository) : super(const ReEnrollmentState());

  static const List<String> yearLevels = [
    '1st Year',
    '2nd Year',
    '3rd Year',
    '4th Year',
  ];

  Future<void> init(StudentModel student, SemesterModel semester) async {
    state = state.copyWith(
      isLoadingSections: true,
      selectedYearLevel: _resolveDefaultYearLevel(student.yearLevel, semester.semester),
      selectedSection: student.section,
      isConfirmed: false,
      isSuccess: false,
      clearError: true,
    );

    try {
      final courseIdOrCode = student.courseCode.isNotEmpty
          ? student.courseCode
          : (student.courseId.isNotEmpty ? student.courseId : 'BSIT');

      final rawSections = await _repository.getSectionsForCourse(courseIdOrCode);
      final sectionNames = <String>{};

      for (final s in rawSections) {
        final name = (s['name'] as String?) ??
            (s['section'] as String?) ??
            (s['sectionName'] as String?) ??
            (s['code'] as String?) ??
            '';
        if (name.trim().isNotEmpty) {
          sectionNames.add(name.trim());
        }
      }

      // If current section exists, ensure it's in the list
      if (student.section.isNotEmpty) {
        sectionNames.add(student.section.trim());
      }

      final sortedList = sectionNames.toList()..sort();
      final defaultSection = sortedList.contains(student.section)
          ? student.section
          : (sortedList.isNotEmpty ? sortedList.first : student.section);

      state = state.copyWith(
        isLoadingSections: false,
        sections: sortedList,
        selectedSection: defaultSection,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingSections: false,
        errorMessage: 'Failed to load sections: $e',
      );
    }
  }

  void setYearLevel(String value) {
    state = state.copyWith(selectedYearLevel: value, clearError: true);
  }

  void setSection(String value) {
    state = state.copyWith(selectedSection: value, clearError: true);
  }

  void setConfirmed(bool value) {
    state = state.copyWith(isConfirmed: value, clearError: true);
  }

  Future<bool> submit(StudentModel student, SemesterModel semester) async {
    if (state.selectedYearLevel.isEmpty) {
      state = state.copyWith(errorMessage: 'Please select your Year Level.');
      return false;
    }
    if (state.selectedSection.isEmpty) {
      state = state.copyWith(errorMessage: 'Please select or enter your Section.');
      return false;
    }
    if (!state.isConfirmed) {
      state = state.copyWith(errorMessage: 'Please check the box confirming your enrollment.');
      return false;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      await _repository.confirmReEnrollment(
        studentUid: student.id,
        academicYear: semester.academicYear,
        semester: semester.semester,
        yearLevel: state.selectedYearLevel,
        section: state.selectedSection,
      );

      state = state.copyWith(isSubmitting: false, isSuccess: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Re-enrollment failed: $e',
      );
      return false;
    }
  }

  String _resolveDefaultYearLevel(String currentYearLevel, String newSemester) {
    if (yearLevels.contains(currentYearLevel)) {
      return currentYearLevel;
    }
    return '1st Year';
  }
}

final reEnrollmentViewModelProvider =
    StateNotifierProvider.autoDispose<ReEnrollmentViewModel, ReEnrollmentState>(
  (ref) => ReEnrollmentViewModel(ref.watch(semesterRepositoryProvider)),
);
