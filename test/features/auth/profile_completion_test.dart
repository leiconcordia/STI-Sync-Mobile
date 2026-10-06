import 'package:flutter_test/flutter_test.dart';
import 'package:sti_sync/features/auth/models/student_model.dart';
import 'package:sti_sync/features/auth/repositories/profile_completion_repository.dart';
import 'package:sti_sync/features/auth/viewmodels/profile_completion_viewmodel.dart';

// Simple mock for testing ProfileCompletionViewModel in isolation
class _FakeProfileCompletionRepository implements ProfileCompletionRepository {
  bool emailTaken = false;
  bool contactNumberTaken = false;

  @override
  Future<bool> isEmailTaken(String email, {String? excludeUid}) async => emailTaken;

  @override
  Future<bool> isContactNumberTaken(String contactNumber, {String? excludeUid}) async => contactNumberTaken;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('ProfileCompletionViewModel Validation Tests', () {
    late _FakeProfileCompletionRepository repo;
    late ProfileCompletionViewModel vm;
    late StudentModel sampleStudent;

    setUp(() {
      repo = _FakeProfileCompletionRepository();
      vm = ProfileCompletionViewModel(repo);
      sampleStudent = StudentModel(
        id: 'test_uid_123',
        authUid: 'test_uid_123',
        lastName: 'Ablen',
        firstName: 'Jhillary Duphnie',
        middleName: '',
        studentId: '02000496332',
        dateOfBirth: '',
        sex: 'Female',
        contactNumber: '',
        courseId: 'course_bsit',
        courseName: 'BS IN INFORMATION TECHNOLOGY',
        courseCode: 'BSIT',
        departmentId: 'dept_cite',
        departmentName: 'CITE',
        yearLevel: '1st Year',
        section: 'UNASSIGNED',
        schoolYear: '2026-2027',
        semester: '1st Semester',
        email: '02000496332@student.sti.edu',
        profilePhotoUrl: '',
        schoolIdPhotoUrl: '',
        status: 'ACTIVE',
        registrationSource: 'REGISTRAR_IMPORT',
        addedBy: 'admin',
        isProfileComplete: false,
        requiresPasswordChange: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    test('Password validation enforces min 8 chars, uppercase, and digit/symbol', () {
      vm.setNewPassword('weak');
      vm.setConfirmPassword('weak');
      vm.setPersonalEmail('jhillary@gmail.com');
      expect(vm.validateCredentials(sampleStudent), contains('at least 8 characters'));

      vm.setNewPassword('lowercase123!');
      vm.setConfirmPassword('lowercase123!');
      expect(vm.validateCredentials(sampleStudent), contains('uppercase letter'));

      vm.setNewPassword('UppercaseLetters');
      vm.setConfirmPassword('UppercaseLetters');
      expect(vm.validateCredentials(sampleStudent), contains('number or special character'));
    });

    test('Student cannot reuse the initial default registrar password formula', () {
      // Default formula: Caps(LastName) + Last6(StudentNo) -> Ablen496332
      vm.setNewPassword('Ablen496332');
      vm.setConfirmPassword('Ablen496332');
      vm.setPersonalEmail('jhillary@gmail.com');

      final error = vm.validateCredentials(sampleStudent);
      expect(error, contains('You cannot reuse the default temporary password'));
    });

    test('Personal email rejects provisional school domain and malformed emails', () {
      vm.setNewPassword('ValidPassword123!');
      vm.setConfirmPassword('ValidPassword123!');

      // Malformed email
      vm.setPersonalEmail('invalid-email');
      expect(vm.validateCredentials(sampleStudent), contains('valid email address'));

      // Provisional school domain
      vm.setPersonalEmail('02000496332@student.sti.edu');
      expect(vm.validateCredentials(sampleStudent), contains('personal email address'));

      // Valid personal email
      vm.setPersonalEmail('jhillary.ablen@gmail.com');
      expect(vm.validateCredentials(sampleStudent), isNull);
    });

    test('Personal Info step validates minimum age and 10-digit mobile number starting with 9', () {
      // Underage (<14)
      vm.setDateOfBirth(DateTime.now());
      vm.setContactNumber('9171234567');
      expect(vm.validatePersonalInfo(), contains('at least 14 years old'));

      // Valid DOB (18 years old)
      final now = DateTime.now();
      vm.setDateOfBirth(DateTime(now.year - 18, 5, 12));

      // Invalid mobile number (not starting with 9 or too short)
      vm.setContactNumber('8171234567');
      expect(vm.validatePersonalInfo(), contains('starting with 9'));

      // Valid mobile number
      vm.setContactNumber('9171234567');
      expect(vm.validatePersonalInfo(), isNull);
    });

    test('StudentModel defaults isProfileComplete to true for legacy docs, false when specified', () {
      final legacy = StudentModel(
        id: 'u1',
        authUid: 'u1',
        lastName: 'Santos',
        firstName: 'Maria',
        middleName: '',
        studentId: '02000111222',
        dateOfBirth: '2004-01-01',
        sex: 'Female',
        contactNumber: '9123456789',
        courseId: 'c1',
        courseName: 'BSIT',
        courseCode: 'BSIT',
        departmentId: 'd1',
        departmentName: 'CITE',
        yearLevel: '2nd Year',
        section: 'BSIT-2A',
        schoolYear: '2026-2027',
        semester: '1st Semester',
        email: 'maria@gmail.com',
        profilePhotoUrl: 'https://cloudinary.com/pic.jpg',
        schoolIdPhotoUrl: 'https://cloudinary.com/id.jpg',
        status: 'ACTIVE',
        registrationSource: 'SELF_REGISTER',
        addedBy: 'self',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Legacy default is true (unblocked)
      expect(legacy.isProfileComplete, isTrue);
      expect(legacy.requiresPasswordChange, isFalse);

      // Imported student is false (gated into profile completion)
      expect(sampleStudent.isProfileComplete, isFalse);
      expect(sampleStudent.requiresPasswordChange, isTrue);
    });
  });
}
