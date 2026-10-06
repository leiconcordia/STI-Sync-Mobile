import 'package:flutter_test/flutter_test.dart';
import 'package:sti_sync/features/auth/models/student_model.dart';
import 'package:sti_sync/features/organizations/models/organization_model.dart';

void main() {
  group('Organization Department Scope & Eligibility Tests', () {
    final itStudent = StudentModel(
      id: 'stud_it_1',
      authUid: 'stud_it_1',
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
      departmentName: 'Information and Communications Technology',
      yearLevel: '2nd Year',
      section: 'BSIT 2101',
      schoolYear: '2026-2027',
      semester: '1st Semester',
      email: 'lei@example.com',
      profilePhotoUrl: '',
      schoolIdPhotoUrl: '',
      status: 'ACTIVE',
      registrationSource: 'SELF_REGISTER',
      addedBy: 'self',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final crossDeptOrg = OrganizationModel(
      id: 'org_ssc',
      name: 'Supreme Student Council',
      acronym: 'SSC',
      description: 'Campus-wide student government',
      departmentId: 'cross-departmental',
      departmentName: 'Institutional',
      scope: 'cross-departmental',
      allowedDepartmentIds: [],
      allowedCourseIds: [],
      academicYear: '2026-2027',
      semester: '1st Semester',
      status: 'active',
      memberCount: 150,
    );

    final itOrg = OrganizationModel(
      id: 'org_jpcs',
      name: 'Junior Philippine Computer Society',
      acronym: 'JPCS',
      description: 'ICT Department Academic Society',
      departmentId: 'dept_it',
      departmentName: 'Information and Communications Technology',
      scope: 'departmental',
      allowedDepartmentIds: ['dept_it'],
      allowedCourseIds: ['BSIT', 'BSCS'],
      academicYear: '2026-2027',
      semester: '1st Semester',
      status: 'active',
      memberCount: 45,
    );

    final tourismOrg = OrganizationModel(
      id: 'org_hms',
      name: 'Hospitality Management Society',
      acronym: 'HMS',
      description: 'Tourism and Hospitality Department Academic Society',
      departmentId: 'dept_tourism',
      departmentName: 'Tourism and Hospitality Management',
      scope: 'departmental',
      allowedDepartmentIds: ['dept_tourism'],
      allowedCourseIds: ['BSHM', 'BSTM'],
      academicYear: '2026-2027',
      semester: '1st Semester',
      status: 'active',
      memberCount: 30,
    );

    test('Organization scope flags resolve accurately', () {
      expect(crossDeptOrg.isCrossDepartmental, isTrue);
      expect(crossDeptOrg.isDepartmental, isFalse);

      expect(itOrg.isDepartmental, isTrue);
      expect(itOrg.isCrossDepartmental, isFalse);

      expect(tourismOrg.isDepartmental, isTrue);
      expect(tourismOrg.isCrossDepartmental, isFalse);
    });

    test('Cross-departmental organizations are open to all students', () {
      expect(
        crossDeptOrg.isStudentEligible(itStudent.departmentId, itStudent.departmentName),
        isTrue,
      );

      // Even a student with no department can join cross-departmental orgs
      expect(crossDeptOrg.isStudentEligible('', ''), isTrue);
      expect(crossDeptOrg.isStudentEligible(null, null), isTrue);
    });

    test('Students can join departmental organizations matching their enrolled department', () {
      expect(
        itOrg.isStudentEligible(itStudent.departmentId, itStudent.departmentName),
        isTrue,
      );

      // Matching by department name
      expect(
        itOrg.isStudentEligible('random_id', 'Information and Communications Technology'),
        isTrue,
      );

      // Matching by allowedDepartmentIds
      expect(
        itOrg.isStudentEligible('dept_it', 'Other Name'),
        isTrue,
      );
    });

    test('Students are strictly BLOCKED from joining non-matching departmental organizations', () {
      expect(
        tourismOrg.isStudentEligible(itStudent.departmentId, itStudent.departmentName),
        isFalse,
      );

      // Student with no department is blocked from departmental orgs
      expect(tourismOrg.isStudentEligible('', ''), isFalse);
      expect(tourismOrg.isStudentEligible(null, null), isFalse);
    });

    test('OrganizationModel.fromFirestore accurately parses governance fields', () {
      final parsed = OrganizationModel.fromFirestore({
        'name': 'JPCS STI Ormoc',
        'code': 'JPCS',
        'departmentId': 'dept_it',
        'departmentName': 'ICT Department',
        'scope': 'departmental',
        'allowedDepartmentIds': ['dept_it', 'dept_cs'],
      }, 'org_test_1');

      expect(parsed.id, 'org_test_1');
      expect(parsed.name, 'JPCS STI Ormoc');
      expect(parsed.acronym, 'JPCS');
      expect(parsed.departmentId, 'dept_it');
      expect(parsed.departmentName, 'ICT Department');
      expect(parsed.scope, 'departmental');
      expect(parsed.isDepartmental, isTrue);
      expect(parsed.isCrossDepartmental, isFalse);
      expect(parsed.allowedDepartmentIds, contains('dept_it'));
    });
  });
}
