import 'package:flutter_test/flutter_test.dart';
import 'package:sti_sync/features/auth/models/student_model.dart';
import 'package:sti_sync/features/semester/models/semester_model.dart';
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
      expect(activeSemester.formattedDeadline, 'Aug, 31 2026');

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

    test('isPendingReEnrollment tolerates formatting differences between web and mobile', () {
      // AY with 'A.Y.' prefix vs plain year
      final enrolledWithAy = baseStudent.copyWith(
        schoolYear: 'A.Y. 2026-2027',
        semester: '2nd Semester',
      );
      expect(enrolledWithAy.isPendingReEnrollment(activeSemester), false);

      // AY with spaces around hyphen
      final enrolledWithSpacedAy = baseStudent.copyWith(
        schoolYear: '2026 - 2027',
        semester: '2nd Semester',
      );
      expect(enrolledWithSpacedAy.isPendingReEnrollment(activeSemester), false);

      // Semester with term index match ('2nd' vs '2nd Semester')
      final enrolledShortTerm = baseStudent.copyWith(
        schoolYear: '2026-2027',
        semester: '2nd',
      );
      expect(enrolledShortTerm.isPendingReEnrollment(activeSemester), false);
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

    test('College Semester vs SHS Trimester: Student and Semester model level distinction', () {
      // College student & semester
      expect(baseStudent.isCollege, isTrue);
      expect(baseStudent.isShs, isFalse);
      expect(activeSemester.isCollege, isTrue);
      expect(activeSemester.isShs, isFalse);

      // SHS student & trimester
      final shsStudent = baseStudent.copyWith(
        courseCode: 'STEM',
        courseName: 'Science, Technology, Engineering, and Math',
        yearLevel: 'Grade 11',
        section: 'STEM 11-A',
        semester: '1st Trimester',
        academicLevel: 'SHS',
      );
      expect(shsStudent.isShs, isTrue);
      expect(shsStudent.isCollege, isFalse);

      final shsTrimester = SemesterModel(
        id: 'sem_shs_2nd_tri',
        academicYear: '2026-2027',
        semester: '2nd Trimester',
        academicLevel: 'SHS',
        status: 'ACTIVE',
        isCurrent: true,
      );
      expect(shsTrimester.isShs, isTrue);
      expect(shsTrimester.isCollege, isFalse);

      // Isolation: College student is NOT pending re-enrollment when an SHS trimester updates
      expect(baseStudent.isPendingReEnrollment(shsTrimester), isFalse);

      // Isolation: SHS student is NOT pending re-enrollment when a College semester updates
      expect(shsStudent.isPendingReEnrollment(activeSemester), isFalse);

      // Matching cohort: SHS student is pending re-enrollment when their own trimester updates (1st vs 2nd)
      expect(shsStudent.isPendingReEnrollment(shsTrimester), isTrue);

      // College BSIT student with legacy semester string '2nd Trimester' still evaluates to College
      final legacyStudent = baseStudent.copyWith(semester: '2nd Trimester');
      expect(legacyStudent.isCollege, isTrue);
      expect(legacyStudent.isShs, isFalse);

      // SemesterModel.forCohort adapts Trimester to Semester for College
      final adaptedForCollege = shsTrimester.forCohort(isShs: false);
      expect(adaptedForCollege.semester, '2nd Semester');
      expect(adaptedForCollege.isCollege, isTrue);
      expect(adaptedForCollege.displayName, '2nd Semester · A.Y. 2026-2027');

      // SemesterModel.forCohort adapts Semester to Trimester for SHS
      final adaptedForShs = activeSemester.forCohort(isShs: true);
      expect(adaptedForShs.semester, '2nd Trimester');
      expect(adaptedForShs.isShs, isTrue);
      expect(adaptedForShs.displayName, '2nd Trimester · A.Y. 2026-2027');
    });
  });
}
