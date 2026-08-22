import 'package:flutter_test/flutter_test.dart';
import 'package:sti_sync/features/auth/models/student_model.dart';
import 'package:sti_sync/features/semester/models/semester_model.dart';
import 'package:sti_sync/features/semester/viewmodels/re_enrollment_viewmodel.dart';
import 'package:sti_sync/features/qr_ticket/viewmodels/qr_ticket_viewmodel.dart';

void main() {
  group('Semester Rollover & Re-enrollment Tests', () {
    final activeSemester = SemesterModel(
      id: 'sem_2026_2nd',
      academicYear: '2026-2027',
      semester: '2nd Semester',
      status: 'ACTIVE',
      isCurrent: true,
      reenrollDeadline: DateTime(2026, 8, 31),
    );

    final baseStudent = StudentModel(
      id: 'stud_1',
      authUid: 'stud_1',
      lastName: 'Concordia',
      firstName: 'Lei',
      middleName: '',
      studentId: '02000123456',
      dateOfBirth: '2004-01-01',
      sex: 'Male',
      contactNumber: '9123456789',
      courseId: 'course_bsit',
      courseName: 'Information Technology',
      courseCode: 'BSIT',
      departmentId: 'dept_it',
      departmentName: 'ICT Department',
      yearLevel: '2nd Year',
      section: 'BSIT 2101',
      schoolYear: '2026-2027',
      semester: '1st Semester', // Rollover mismatch: 1st sem != 2nd sem
      email: 'lei@example.com',
      profilePhotoUrl: '',
      schoolIdPhotoUrl: '',
      status: 'ACTIVE',
      registrationSource: 'SELF_REGISTER',
      addedBy: 'self',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    test('SemesterModel parses fields and handles active/display state', () {
      expect(activeSemester.isActive, true);
      expect(activeSemester.displayName, '2nd Semester · A.Y. 2026-2027');
      expect(activeSemester.formattedDeadline, 'Aug 31 2026');

      final fromMap = SemesterModel.fromMap({
        'name': '1st Semester',
        'schoolYear': '2025-2026',
        'isActive': true,
      }, 'sem_test');

      expect(fromMap.academicYear, '2025-2026');
      expect(fromMap.semester, '1st Semester');
      expect(fromMap.isActive, true);
    });

    test('isPendingReEnrollment returns true when semester or schoolYear differs', () {
      // Student is on 1st Semester 2026-2027, Active Semester is 2nd Semester 2026-2027
      expect(baseStudent.isPendingReEnrollment(activeSemester), true);
      expect(baseStudent.isReEnrolled(activeSemester), false);

      // Student has re-enrolled for 2nd Semester 2026-2027
      final reEnrolledStudent = baseStudent.copyWith(
        semester: '2nd Semester',
        schoolYear: '2026-2027',
      );
      expect(reEnrolledStudent.isPendingReEnrollment(activeSemester), false);
      expect(reEnrolledStudent.isReEnrolled(activeSemester), true);
    });

    test('isPendingReEnrollment returns true when status is PENDING_REENROLLMENT', () {
      final flaggedStudent = baseStudent.copyWith(
        semester: '2nd Semester',
        schoolYear: '2026-2027',
        status: 'PENDING_REENROLLMENT',
      );
      expect(flaggedStudent.isPendingReEnrollment(activeSemester), true);
    });

    test('isPendingReEnrollment returns false when student status is not ACTIVE (e.g. PENDING)', () {
      final pendingInitialApproval = baseStudent.copyWith(
        status: 'PENDING',
      );
      expect(pendingInitialApproval.isPendingReEnrollment(activeSemester), false);
    });

    test('ReEnrollmentState default year levels and copyWith', () {
      expect(ReEnrollmentViewModel.yearLevels.length, 4);
      expect(ReEnrollmentViewModel.yearLevels, contains('1st Year'));
      expect(ReEnrollmentViewModel.yearLevels, contains('4th Year'));

      const state = ReEnrollmentState();
      expect(state.selectedYearLevel, '1st Year');
      expect(state.isConfirmed, false);
      expect(state.isSubmitting, false);

      final updated = state.copyWith(
        selectedYearLevel: '3rd Year',
        selectedSection: 'BSIT 3101',
        isConfirmed: true,
      );
      expect(updated.selectedYearLevel, '3rd Year');
      expect(updated.selectedSection, 'BSIT 3101');
      expect(updated.isConfirmed, true);
    });

    test('QrTicketLocked identifies re-enrollment requirement correctly', () {
      const lockedPayment = QrTicketLocked(
        amountDue: 150.0,
        paymentStatus: 'UNPAID',
        eventTitle: 'Event 1',
        studentName: 'Lei',
        studentId: '02000',
        profilePhotoUrl: '',
        courseInfo: 'BSIT',
      );
      expect(lockedPayment.isReEnrollmentRequired, false);

      const lockedReEnrollment = QrTicketLocked(
        amountDue: 0.0,
        paymentStatus: 'RE_ENROLLMENT_REQUIRED',
        eventTitle: 'Re-enrollment Required',
        studentName: 'Lei',
        studentId: '02000',
        profilePhotoUrl: '',
        courseInfo: 'BSIT',
        lockReason: 'Please complete semester re-enrollment to unlock tickets.',
      );
      expect(lockedReEnrollment.isReEnrollmentRequired, true);
      expect(lockedReEnrollment.lockReason, isNotNull);
    });
  });
}
