import 'package:flutter_test/flutter_test.dart';
import 'package:sti_sync/features/auth/viewmodels/registration_viewmodel.dart';
import 'package:sti_sync/services/gemini_ai_verification_service.dart';

void main() {
  group('RegistrationState & Academic Logic Tests', () {
    test('Student ID validation enforces exact 11 digits', () {
      const state = RegistrationState(
        lastName: 'Dela Cruz',
        firstName: 'Juan',
        studentId: '0200025837', // 10 digits
        sex: 'Male',
        contactNumber: '9171234567',
      );

      final error = state.validateCurrentStep();
      expect(error, contains('Student ID must be exactly 11 digits'));

      final validState = state.copyWith(studentId: '02000258377');
      final validWithDob = validState.copyWith(dateOfBirth: DateTime(2005, 5, 20));
      expect(validWithDob.validateCurrentStep(), isNull);
    });

    test('Academic Level filters courses cleanly between Tertiary and SHS', () {
      final sampleCourses = [
        {
          'id': 'c_bsit',
          'courseCode': 'BSIT',
          'name': 'BS in Information Technology',
          'academicLevel': 'Tertiary',
          'totalYears': 4,
        },
        {
          'id': 'c_dit',
          'courseCode': 'DIT',
          'name': 'Diploma in Information Technology',
          'academicLevel': 'Tertiary',
          'totalYears': 2,
        },
        {
          'id': 'c_act',
          'courseCode': 'ACT',
          'name': 'Associate in Computer Technology',
          'academicLevel': 'Tertiary',
          'totalYears': 3,
        },
        {
          'id': 'c_stem',
          'courseCode': 'STEM',
          'name': 'Science, Technology, Engineering, and Math',
          'academicLevel': 'SHS',
          'totalYears': 2,
        },
        {
          'id': 'c_abm',
          'courseCode': 'ABM',
          'name': 'Accountancy, Business, and Management',
          'academicLevel': 'SHS',
          'totalYears': 2,
        },
      ];

      // Tertiary level selection
      final tertiaryState = RegistrationState(
        academicLevel: 'Tertiary',
        availableCourses: sampleCourses,
      );
      expect(tertiaryState.filteredCourses.length, 3);
      expect(
        tertiaryState.filteredCourses.map((c) => c['courseCode']).toList(),
        ['BSIT', 'DIT', 'ACT'],
      );

      // SHS level selection
      final shsState = RegistrationState(
        academicLevel: 'SHS',
        availableCourses: sampleCourses,
      );
      expect(shsState.filteredCourses.length, 2);
      expect(
        shsState.filteredCourses.map((c) => c['courseCode']).toList(),
        ['STEM', 'ABM'],
      );
    });

    test('Dynamic year levels for college based on totalYears (2, 3, 4, 5 years) and fixed for SHS', () {
      final sampleCourses = [
        {
          'id': 'c_dit',
          'courseCode': 'DIT',
          'totalYears': 2,
          'academicLevel': 'Tertiary',
        },
        {
          'id': 'c_act',
          'courseCode': 'ACT',
          'totalYears': 3,
          'academicLevel': 'Tertiary',
        },
        {
          'id': 'c_bsit',
          'courseCode': 'BSIT',
          'totalYears': 4,
          'academicLevel': 'Tertiary',
        },
        {
          'id': 'c_eng',
          'courseCode': 'BSCpE',
          'totalYears': 5,
          'academicLevel': 'Tertiary',
        },
        {
          'id': 'c_stem',
          'courseCode': 'STEM',
          'totalYears': 2,
          'academicLevel': 'SHS',
        },
      ];

      // 2-year college diploma
      final ditState = RegistrationState(
        academicLevel: 'Tertiary',
        courseCode: 'DIT',
        availableCourses: sampleCourses,
      );
      expect(ditState.availableYearLevels, ['1st Year', '2nd Year']);

      // 3-year college diploma
      final actState = RegistrationState(
        academicLevel: 'Tertiary',
        courseCode: 'ACT',
        availableCourses: sampleCourses,
      );
      expect(actState.availableYearLevels, ['1st Year', '2nd Year', '3rd Year']);

      // 4-year BSIT
      final bsitState = RegistrationState(
        academicLevel: 'Tertiary',
        courseCode: 'BSIT',
        availableCourses: sampleCourses,
      );
      expect(bsitState.availableYearLevels, ['1st Year', '2nd Year', '3rd Year', '4th Year']);

      // 5-year BSCpE
      final engState = RegistrationState(
        academicLevel: 'Tertiary',
        courseCode: 'BSCpE',
        availableCourses: sampleCourses,
      );
      expect(engState.availableYearLevels, ['1st Year', '2nd Year', '3rd Year', '4th Year', '5th Year']);

      // SHS STEM track (always Grade 11 & 12)
      final stemState = RegistrationState(
        academicLevel: 'SHS',
        courseCode: 'STEM',
        availableCourses: sampleCourses,
      );
      expect(stemState.availableYearLevels, ['Grade 11', 'Grade 12']);
    });

    test('Dual active academic periods bind College Semester vs SHS Trimester', () {
      final collegePeriod = {
        'id': 'sem_college_active',
        'academicYear': '2026-2027',
        'academicLevel': 'COLLEGE',
        'semester': '2nd Semester',
        'status': 'ACTIVE',
      };

      final shsPeriod = {
        'id': 'sem_shs_active',
        'academicYear': '2026-2027',
        'academicLevel': 'SHS',
        'semester': '1st Trimester',
        'status': 'ACTIVE',
      };

      // State with College level
      final collegeState = RegistrationState(
        academicLevel: 'Tertiary',
        semester: '2nd Semester',
        schoolYear: '2026-2027',
        activeCollegePeriod: collegePeriod,
        activeShsPeriod: shsPeriod,
      );
      expect(collegeState.semester, '2nd Semester');
      expect(collegeState.schoolYear, '2026-2027');

      // State with SHS level
      final shsState = RegistrationState(
        academicLevel: 'SHS',
        semester: '1st Trimester',
        schoolYear: '2026-2027',
        activeCollegePeriod: collegePeriod,
        activeShsPeriod: shsPeriod,
      );
      expect(shsState.semester, '1st Trimester');
      expect(shsState.schoolYear, '2026-2027');
    });

    test('Resubmit skips password validation on step 2', () {
      const resubmitState = RegistrationState(
        currentStep: 2,
        existingUid: 'user_123',
        email: 'student@example.com',
        password: '', // empty password on resubmit
      );

      expect(resubmitState.isResubmit, isTrue);
      expect(resubmitState.validateCurrentStep(), isNull);

      const newRegistrationState = RegistrationState(
        currentStep: 2,
        email: 'student@example.com',
        password: '',
      );
      expect(newRegistrationState.isResubmit, isFalse);
      expect(newRegistrationState.validateCurrentStep(), contains('Password must be at least 8 characters'));
    });
  });

  group('Gemini AI Verification Result Model Tests', () {
    test('AiVerificationResult parses JSON and maps AUTO_APPROVE correctly', () {
      final json = {
        'isActualStiId': true,
        'isBlurry': false,
        'isSelfieValidFace': true,
        'nameMatches': true,
        'extractedName': 'Juan Dela Cruz',
        'idPhotoFaceDescription': 'Male face with short hair',
        'selfiePhotoFaceDescription': 'Matching male face',
        'comparisonAnalysis': 'Features align cleanly',
        'isSamePerson': true,
        'facialDiscrepancies': 'None',
        'faceMatchConfidence': 0.94,
        'decision': 'AUTO_APPROVE',
        'reason': 'Official STI ID Card and student name verified by AI.',
      };

      final result = AiVerificationResult.fromJson(json);
      expect(result.isActualStiId, isTrue);
      expect(result.isBlurry, isFalse);
      expect(result.isSelfieValidFace, isTrue);
      expect(result.nameMatches, isTrue);
      expect(result.decision, AiDecision.autoApprove);
      expect(result.faceMatchConfidence, 0.94);
    });

    test('AiVerificationResult parses AUTO_REJECT correctly', () {
      final json = {
        'isActualStiId': false,
        'isBlurry': false,
        'isSelfieValidFace': true,
        'nameMatches': false,
        'extractedName': '',
        'idPhotoFaceDescription': '',
        'selfiePhotoFaceDescription': '',
        'comparisonAnalysis': '',
        'isSamePerson': false,
        'facialDiscrepancies': 'Not an STI document',
        'faceMatchConfidence': 0.0,
        'decision': 'AUTO_REJECT',
        'reason': 'Uploaded document is not an official STI Student ID card.',
      };

      final result = AiVerificationResult.fromJson(json);
      expect(result.isActualStiId, isFalse);
      expect(result.decision, AiDecision.autoReject);
    });
  });
}
