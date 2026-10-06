import 'dart:convert';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sti_sync/core/local/app_database.dart';
import 'package:sti_sync/features/auth/models/student_model.dart';
import 'package:sti_sync/features/events/models/event_model.dart';
import 'package:drift/drift.dart' as drift;

void main() {
  group('QR Offline Serialization & Event Eligibility Tests', () {
    test('EventModel.toJson() serializes without Timestamp exceptions and round-trips via fromMap', () {
      final now = DateTime.now();
      final event = EventModel(
        id: 'event_test_123',
        referenceId: 'REF-001',
        title: 'Tech Summit 2026',
        description: 'Annual gathering of IT students',
        objectives: const ['Learn', 'Network'],
        eventTypeId: 'type_1',
        eventCategoryId: 'cat_1',
        hostingOrgId: 'org_cits',
        semesterId: 'sem_1',
        schoolYear: '2026-2027',
        sessions: const [
          EventSessionModel(
            id: 'sess_1',
            title: 'Morning Keynote',
            date: '2026-10-15',
            startTime: '08:00',
            endTime: '12:00',
            timeInOpen: '07:30',
            timeInClose: '09:00',
            hasTimeOut: true,
          ),
        ],
        venueId: 'gym',
        eventFormat: 'On-Campus',
        targetAudienceScope: 'all',
        targetYearLevels: const ['4th Year', '4'],
        targetDepartmentIds: const ['dept_it'],
        expectedParticipantCount: 150,
        attendanceEnabled: true,
        certificatesEnabled: true,
        autoIssueCertificates: false,
        studentPayablesEnabled: false,
        budgetItems: const [],
        totalApprovedBudget: 5000,
        enableQRTickets: true,
        mandatoryAttendance: true,
        lockAfterApproval: true,
        scannerActivationCode: '123456',
        scannerUserIds: const ['scanner_1'],
        status: 'approved',
        proposalStatus: 'approved',
        isCancelled: false,
        visibilityStart: now,
        createdBy: 'admin_1',
        createdAt: now,
        updatedAt: now,
        completedAt: now.add(const Duration(hours: 4)),
      );

      // Must not throw when encoding to JSON
      final jsonString = event.toJson();
      expect(jsonString, isA<String>());
      expect(jsonString.contains('Tech Summit 2026'), isTrue);

      final map = jsonDecode(jsonString) as Map<String, dynamic>;
      final restored = EventModel.fromMap(event.id, map);
      expect(restored.id, 'event_test_123');
      expect(restored.title, 'Tech Summit 2026');
      expect(restored.proposalStatus, 'approved');
      expect(restored.sessions.length, 1);
      expect(restored.sessions.first.title, 'Morning Keynote');
    });

    test('isStudentEligible rejects draft and pending proposals', () {
      final now = DateTime.now();
      final student = StudentModel(
        id: 'stud_1',
        authUid: 'stud_1',
        lastName: 'Dela Cruz',
        firstName: 'Juan',
        middleName: '',
        studentId: '02000123456',
        dateOfBirth: '2004-01-01',
        sex: 'Male',
        contactNumber: '9123456789',
        courseId: 'bsit',
        courseName: 'BS Information Technology',
        courseCode: 'BSIT',
        departmentId: 'dept_it',
        departmentName: 'Information Technology',
        yearLevel: '4th Year',
        section: '4A',
        schoolYear: '2026-2027',
        semester: '1st Semester',
        email: 'juan@sti.edu.ph',
        profilePhotoUrl: '',
        schoolIdPhotoUrl: '',
        status: 'ACTIVE',
        registrationSource: 'SELF_REGISTER',
        addedBy: 'self',
        createdAt: now,
        updatedAt: now,
        academicLevel: 'TERTIARY',
      );

      final baseMap = <String, dynamic>{
        'title': 'Hackathon',
        'description': 'Code challenge',
        'eventTypeId': 'type_1',
        'eventCategoryId': 'cat_1',
        'hostingOrgId': '',
        'semesterId': 'sem_1',
        'schoolYear': '2026-2027',
        'venueId': 'lab',
        'eventFormat': 'On-Campus',
        'sessions': <Map<String, dynamic>>[],
      };

      final draftEvent = EventModel.fromMap('e_draft', {
        ...baseMap,
        'proposalStatus': 'draft',
        'status': 'draft',
      });
      expect(draftEvent.isStudentEligible(student), isFalse);

      final pendingEvent = EventModel.fromMap('e_pending', {
        ...baseMap,
        'proposalStatus': 'pending',
        'status': 'pending',
      });
      expect(pendingEvent.isStudentEligible(student), isFalse);

      final approvedEvent = EventModel.fromMap('e_approved', {
        ...baseMap,
        'isPublished': true,
        'proposalStatus': 'approved',
        'status': 'approved',
      });
      expect(approvedEvent.isStudentEligible(student), isTrue);

      final completedEvent = EventModel.fromMap('e_completed', {
        ...baseMap,
        'isPublished': true,
        'proposalStatus': 'completed',
        'status': 'completed',
      });
      expect(completedEvent.isStudentEligible(student), isTrue);
    });
  });

  group('Drift DAOs Multiple Elements Safety Tests', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('PayablesDao.getPayableByEvent does not throw Bad State when multiple elements exist', () async {
      await db.payablesDao.batchUpsertPayables([
        CachedPayablesCompanion.insert(
          id: 'pay_1',
          studentId: 'student_1',
          eventId: const drift.Value('event_multi'),
          assignedAmount: const drift.Value(100.0),
          paidAmount: const drift.Value(100.0),
          amountDue: const drift.Value(0.0),
          qrTicketUnlocked: const drift.Value(1),
          cachedAt: const drift.Value(1000),
        ),
        CachedPayablesCompanion.insert(
          id: 'pay_2',
          studentId: 'student_2',
          eventId: const drift.Value('event_multi'),
          assignedAmount: const drift.Value(150.0),
          paidAmount: const drift.Value(0.0),
          amountDue: const drift.Value(150.0),
          qrTicketUnlocked: const drift.Value(0),
          cachedAt: const drift.Value(2000),
        ),
      ]);

      // Query without studentId must return first element without throwing Too many elements
      final payable = await db.payablesDao.getPayableByEvent('event_multi');
      expect(payable, isNotNull);

      // Query with specific studentId must return that student's payable
      final student2Payable = await db.payablesDao.getPayableByEvent('event_multi', 'student_2');
      expect(student2Payable, isNotNull);
      expect(student2Payable!.studentId, 'student_2');
      expect(student2Payable.amountDue, 150.0);

      // isUnlocked must also safely evaluate
      final unlocked = await db.payablesDao.isUnlocked('student_1', 'event_multi');
      expect(unlocked, isTrue);

      final locked = await db.payablesDao.isUnlocked('student_2', 'event_multi');
      expect(locked, isFalse);
    });

    test('EventsDao.getEvent and watchEvent safely handle multiple rows if any', () async {
      await db.eventsDao.upsertEvent(
        CachedEventsCompanion.insert(
          id: 'ev_1',
          title: 'Event 1',
          eventJson: '{"id":"ev_1"}',
          cachedAt: 1000,
          expiresAt: 9999999999,
        ),
      );

      final event = await db.eventsDao.getEvent('ev_1');
      expect(event, isNotNull);
      expect(event!.title, 'Event 1');

      final streamed = await db.eventsDao.watchEvent('ev_1').first;
      expect(streamed, isNotNull);
      expect(streamed!.title, 'Event 1');
    });

    test('AttendanceDao.checkDuplicate safely handles multiple matches', () async {
      await db.into(db.offlineAttendance).insert(
        OfflineAttendanceCompanion.insert(
          localId: 'loc_1',
          eventId: 'event_1',
          sessionId: 'sess_1',
          studentId: '02000123456',
          studentName: 'Juan',
          gateType: 'Time-In',
          scanMethod: 'qr',
          scannedBy: 'scanner_1',
          scannedAt: 1000,
          synced: 0,
          conflictResolved: 0,
        ),
      );

      await db.into(db.offlineAttendance).insert(
        OfflineAttendanceCompanion.insert(
          localId: 'loc_2',
          eventId: 'event_1',
          sessionId: 'sess_1',
          studentId: '02000123456',
          studentName: 'Juan',
          gateType: 'Time-In',
          scanMethod: 'qr',
          scannedBy: 'scanner_1',
          scannedAt: 2000,
          synced: 0,
          conflictResolved: 0,
        ),
      );

      // Must not throw "Bad state: Too many elements"
      final duplicate = await db.attendanceDao.checkDuplicate(
        studentId: '02000123456',
        eventId: 'event_1',
        sessionId: 'sess_1',
        gateType: 'Time-In',
      );

      expect(duplicate, isNotNull);
      expect(duplicate!.studentId, '02000123456');
    });
  });
}
