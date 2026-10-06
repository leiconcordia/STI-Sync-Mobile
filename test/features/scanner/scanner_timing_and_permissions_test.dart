import 'package:flutter_test/flutter_test.dart';
import 'package:sti_sync/features/scanner/models/scanner_assignment_model.dart';
import 'package:sti_sync/features/scanner/utils/session_timing_evaluator.dart';

void main() {
  group('Scanner 3-Checkbox Permission Tests', () {
    test('Permissions are strictly independent and ignore fullAccess bypass', () {
      // Officer has fullAccess: true, but all 3 checkboxes false
      final noCheckboxes = ScannerAssignmentModel(
        eventId: 'event_1',
        eventTitle: 'General Assembly',
        sessions: const [],
        officerUserId: 'officer_1',
        permissions: const {
          'fullAccess': true,
          'canCheckIn': false,
          'canCheckOut': false,
          'allowManualAttendance': false,
        },
        eventEndTime: DateTime.now().add(const Duration(hours: 4)),
        proposalStatus: 'approved',
      );

      expect(noCheckboxes.canCheckIn, false);
      expect(noCheckboxes.canCheckOut, false);
      expect(noCheckboxes.allowManualAttendance, false);
    });

    test('Each checkbox activates only its own feature', () {
      final checkInOnly = ScannerAssignmentModel(
        eventId: 'event_1',
        eventTitle: 'General Assembly',
        sessions: const [],
        officerUserId: 'officer_1',
        permissions: const {
          'canCheckIn': true,
          'canCheckOut': false,
          'allowManualAttendance': false,
        },
        eventEndTime: DateTime.now().add(const Duration(hours: 4)),
        proposalStatus: 'approved',
      );

      expect(checkInOnly.canCheckIn, true);
      expect(checkInOnly.canCheckOut, false);
      expect(checkInOnly.allowManualAttendance, false);

      final checkOutOnly = checkInOnly.copyWith(
        permissions: {
          'canCheckIn': false,
          'canCheckOut': true,
          'allowManualAttendance': false,
        },
      );

      expect(checkOutOnly.canCheckIn, false);
      expect(checkOutOnly.canCheckOut, true);
      expect(checkOutOnly.allowManualAttendance, false);

      final manualOnly = checkInOnly.copyWith(
        permissions: {
          'canCheckIn': false,
          'canCheckOut': false,
          'allowManualAttendance': true,
        },
      );

      expect(manualOnly.canCheckIn, false);
      expect(manualOnly.canCheckOut, false);
      expect(manualOnly.allowManualAttendance, true);
      expect(manualOnly.allowFlagged, true);
    });
  });

  group('SessionTimingEvaluator Time-In Tests', () {
    final session = {
      'id': 'sess_1',
      'date': '2026-08-15',
      'startTime': '08:00 AM',
      'endTime': '12:00 PM',
      'timeInOpen': '07:30 AM',
      'timeInClose': '09:00 AM',
      'gracePeriodMinutes': 15,
      'lateThresholdMinutes': 60,
    };

    test('Locks out when current time is before timeInOpen', () {
      final checkTime = DateTime(2026, 8, 15, 7, 15); // 7:15 AM
      final result = SessionTimingEvaluator.evaluateTimeIn(
        session,
        checkTime: checkTime,
      );

      expect(result.status, GateWindowStatus.notStarted);
      expect(result.isOpen, false);
      expect(result.message.contains('Opens at 7:30 AM'), true);
    });

    test('Opens and marks Present during grace period (On-Time)', () {
      final checkTime = DateTime(2026, 8, 15, 8, 10); // 8:10 AM (<= 8:15 AM grace threshold)
      final result = SessionTimingEvaluator.evaluateTimeIn(
        session,
        checkTime: checkTime,
      );

      expect(result.status, GateWindowStatus.open);
      expect(result.isOpen, true);
      expect(result.attendanceStatus, 'Present');
    });

    test('Opens and marks Late after grace period but before timeInClose', () {
      final checkTime = DateTime(2026, 8, 15, 8, 30); // 8:30 AM (> 8:15 AM, <= 9:00 AM close)
      final result = SessionTimingEvaluator.evaluateTimeIn(
        session,
        checkTime: checkTime,
      );

      expect(result.status, GateWindowStatus.open);
      expect(result.isOpen, true);
      expect(result.attendanceStatus, 'Late');
    });

    test('Locks out and marks Closed after timeInClose / late threshold', () {
      final checkTime = DateTime(2026, 8, 15, 9, 5); // 9:05 AM (> 9:00 AM cutoff)
      final result = SessionTimingEvaluator.evaluateTimeIn(
        session,
        checkTime: checkTime,
      );

      expect(result.status, GateWindowStatus.closed);
      expect(result.isOpen, false);
      expect(result.message.contains('Closed at 9:00 AM'), true);
    });
  });

  group('SessionTimingEvaluator Time-Out Tests', () {
    test('Disabled if hasTimeOut is not true', () {
      final noTimeOutSession = {
        'id': 'sess_1',
        'date': '2026-08-15',
        'startTime': '08:00 AM',
        'endTime': '12:00 PM',
        'hasTimeOut': false,
      };

      final result = SessionTimingEvaluator.evaluateTimeOut(noTimeOutSession);
      expect(result.status, GateWindowStatus.disabled);
      expect(result.isOpen, false);
    });

    test('Respects timeOutOpen and timeOutClose windows', () {
      final timeOutSession = {
        'id': 'sess_1',
        'date': '2026-08-15',
        'startTime': '08:00 AM',
        'endTime': '12:00 PM',
        'timeOutOpen': '11:30 AM',
        'timeOutClose': '01:00 PM',
        'hasTimeOut': true,
      };

      // Before timeOutOpen
      final beforeResult = SessionTimingEvaluator.evaluateTimeOut(
        timeOutSession,
        checkTime: DateTime(2026, 8, 15, 11, 0), // 11:00 AM
      );
      expect(beforeResult.status, GateWindowStatus.notStarted);
      expect(beforeResult.isOpen, false);

      // During Time-Out
      final openResult = SessionTimingEvaluator.evaluateTimeOut(
        timeOutSession,
        checkTime: DateTime(2026, 8, 15, 12, 15), // 12:15 PM
      );
      expect(openResult.status, GateWindowStatus.open);
      expect(openResult.isOpen, true);
      expect(openResult.attendanceStatus, 'Present');

      // After timeOutClose
      final closedResult = SessionTimingEvaluator.evaluateTimeOut(
        timeOutSession,
        checkTime: DateTime(2026, 8, 15, 13, 30), // 1:30 PM
      );
      expect(closedResult.status, GateWindowStatus.closed);
      expect(closedResult.isOpen, false);
    });
  });

  group('Session Title Resolution & Offline Restore Tests', () {
    test('Resolves session title from title, sessionTitle, name, or index fallback', () {
      final sessionWithTitle = {'id': 's1', 'title': 'Morning Plenary'};
      final sessionWithSessionTitle = {'id': 's2', 'sessionTitle': 'Afternoon Workshop'};
      final sessionWithName = {'id': 's3', 'name': 'Evening Gala'};
      final sessionWithNoName = {'id': 's4'};

      String resolveTitle(Map<String, dynamic> s, int index) {
        final rawTitle = (s['title'] ??
                s['sessionTitle'] ??
                s['name'] ??
                s['sessionName'] ??
                s['label']) as String?;
        return (rawTitle != null && rawTitle.trim().isNotEmpty)
            ? rawTitle.trim()
            : 'Session ${index + 1}';
      }

      expect(resolveTitle(sessionWithTitle, 0), 'Morning Plenary');
      expect(resolveTitle(sessionWithSessionTitle, 1), 'Afternoon Workshop');
      expect(resolveTitle(sessionWithName, 2), 'Evening Gala');
      expect(resolveTitle(sessionWithNoName, 3), 'Session 4');
    });
  });
}
