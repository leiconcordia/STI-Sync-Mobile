import 'package:flutter_test/flutter_test.dart';
import 'package:sti_sync/features/events/models/event_model.dart';
import 'package:sti_sync/features/payables/models/payable_model.dart';
import 'package:sti_sync/features/payables/repositories/payables_repository.dart';
import 'package:sti_sync/features/scanner/models/scanner_assignment_model.dart';

void main() {
  group('Event Lifecycle & Cancellation Tests', () {
    test('EventModel correctly identifies cancelled status via isCancelled, status, and proposalStatus', () {
      final baseMap = <String, dynamic>{
        'referenceId': 'EV-001',
        'title': 'Tech Fest 2026',
        'description': 'Annual IT tech festival',
        'hostingOrgId': 'org_1',
        'semesterId': 'sem_1',
        'schoolYear': '2026-2027',
        'venueId': 'venue_1',
        'eventFormat': 'On-Campus',
        'status': 'approved',
        'proposalStatus': 'approved',
        'isCancelled': false,
        'sessions': [
          {
            'id': 's1',
            'title': 'Session 1',
            'date': '2026-10-10',
            'startTime': '08:00',
            'endTime': '17:00',
            'timeInOpen': '07:30',
            'timeInClose': '09:00',
            'hasTimeOut': true,
          }
        ],
      };

      final activeEvent = EventModel.fromMap('ev_active', baseMap);
      expect(activeEvent.isEffectivelyCancelled, isFalse);
      expect(activeEvent.mobileStatus, MobileEventDisplayStatus.upcoming);

      final cancelledByFlag = EventModel.fromMap('ev_cancelled_flag', {
        ...baseMap,
        'isCancelled': true,
        'cancellationReason': 'Bad weather / typhoon signal #2',
        'refundPolicy': 'Full refund at SAO',
      });
      expect(cancelledByFlag.isEffectivelyCancelled, isTrue);
      expect(cancelledByFlag.mobileStatus, MobileEventDisplayStatus.cancelled);

      final cancelledByStatus = EventModel.fromMap('ev_cancelled_status', {
        ...baseMap,
        'status': 'cancelled',
      });
      expect(cancelledByStatus.isEffectivelyCancelled, isTrue);
      expect(cancelledByStatus.mobileStatus, MobileEventDisplayStatus.cancelled);

      final cancelledByProposalStatus = EventModel.fromMap('ev_cancelled_proposal', {
        ...baseMap,
        'proposalStatus': 'cancelled',
      });
      expect(cancelledByProposalStatus.isEffectivelyCancelled, isTrue);
      expect(cancelledByProposalStatus.mobileStatus, MobileEventDisplayStatus.cancelled);
    });

    test('EventModel toMap and fromMap preserve cancellation fields', () {
      final eventMap = <String, dynamic>{
        'referenceId': 'EV-002',
        'title': 'Sports Fest',
        'description': 'Intramural games',
        'hostingOrgId': 'org_1',
        'semesterId': 'sem_1',
        'schoolYear': '2026-2027',
        'venueId': 'venue_1',
        'eventFormat': 'On-Campus',
        'status': 'cancelled',
        'proposalStatus': 'cancelled',
        'isCancelled': true,
        'cancellationReason': 'Campus renovation delay',
        'refundPolicy': 'Claim at Org Booth',
        'cancelledByName': 'SAO Dean',
        'sessions': <Map<String, dynamic>>[],
      };

      final event = EventModel.fromMap('event_cancelled', eventMap);
      final map = event.toMap();
      expect(map['isCancelled'], isTrue);
      expect(map['status'], 'cancelled');
      expect(map['cancellationReason'], 'Campus renovation delay');
      expect(map['refundPolicy'], 'Claim at Org Booth');
      expect(map['cancelledByName'], 'SAO Dean');

      final restored = EventModel.fromMap('event_cancelled', map);
      expect(restored.isEffectivelyCancelled, isTrue);
      expect(restored.cancellationReason, 'Campus renovation delay');
      expect(restored.refundPolicy, 'Claim at Org Booth');
      expect(restored.cancelledByName, 'SAO Dean');
    });
  });

  group('Payable Model Waiver & Refund Clearance Logic Tests', () {
    test('Waived payable does not block clearance and has 0 balance', () {
      final waivedPayable = PayableModel(
        id: 'pay_waived',
        studentId: 'stud_1',
        studentName: 'Juan Dela Cruz',
        studentSchoolId: '02000111222',
        organizationId: 'org_1',
        semesterId: 'sem_1',
        type: 'event_fee',
        label: 'Tech Fest Registration',
        description: 'Registration fee',
        assignedAmount: 150.0,
        paidAmount: 0.0,
        amountDue: 0.0,
        status: 'waived',
        paymentStatus: 'unpaid',
        qrTicketUnlocked: false,
        waivedReason: 'Event cancelled by administration',
        waivedAt: DateTime.now(),
      );

      expect(waivedPayable.isWaived, isTrue);
      expect(waivedPayable.isCleared, isTrue);
      expect(waivedPayable.blocksClearance, isFalse);
      expect(waivedPayable.remainingBalance, 0.0);
    });

    test('Refund pending payable does not block clearance and tracks refund due', () {
      final refundPendingPayable = PayableModel(
        id: 'pay_refund_pending',
        studentId: 'stud_1',
        studentName: 'Juan Dela Cruz',
        studentSchoolId: '02000111222',
        organizationId: 'org_1',
        semesterId: 'sem_1',
        type: 'event_fee',
        label: 'Gala Night Ticket',
        description: 'Ticket purchase',
        assignedAmount: 250.0,
        paidAmount: 250.0,
        amountDue: 0.0,
        status: 'refund_pending',
        paymentStatus: 'paid',
        qrTicketUnlocked: false,
        refundDue: 250.0,
        refundReason: 'Event cancelled',
      );

      expect(refundPendingPayable.isRefundPending, isTrue);
      expect(refundPendingPayable.isCleared, isTrue);
      expect(refundPendingPayable.blocksClearance, isFalse);
      expect(refundPendingPayable.remainingBalance, 0.0);
    });

    test('Refunded payable is settled and does not block clearance', () {
      final refundedPayable = PayableModel(
        id: 'pay_refunded',
        studentId: 'stud_1',
        studentName: 'Juan Dela Cruz',
        studentSchoolId: '02000111222',
        organizationId: 'org_1',
        semesterId: 'sem_1',
        type: 'event_fee',
        label: 'Gala Night Ticket',
        description: 'Ticket purchase',
        assignedAmount: 250.0,
        paidAmount: 250.0,
        amountDue: 0.0,
        status: 'refunded',
        paymentStatus: 'paid',
        qrTicketUnlocked: false,
        refundDue: 250.0,
        refundMethod: 'cash',
        refundReceiptNumber: 'REF-2026-0042',
        refundedAt: DateTime.now(),
      );

      expect(refundedPayable.isRefunded, isTrue);
      expect(refundedPayable.isCleared, isTrue);
      expect(refundedPayable.blocksClearance, isFalse);
      expect(refundedPayable.remainingBalance, 0.0);
    });

    test('PayablesSummary excludes waived, refund_pending, and refunded from debt', () {
      final List<PayableModel> payables = [
        PayableModel(
          id: 'pay_1',
          studentId: 'stud_1',
          studentName: 'Juan',
          studentSchoolId: '02000111222',
          organizationId: 'org_1',
          semesterId: 'sem_1',
          type: 'membership_due',
          label: 'Active Due',
          description: '',
          assignedAmount: 100.0,
          paidAmount: 0.0,
          amountDue: 100.0,
          status: 'pending',
          paymentStatus: 'unpaid',
          qrTicketUnlocked: false,
        ),
        PayableModel(
          id: 'pay_2',
          studentId: 'stud_1',
          studentName: 'Juan',
          studentSchoolId: '02000111222',
          organizationId: 'org_1',
          semesterId: 'sem_1',
          type: 'event_fee',
          label: 'Cancelled Event - Waived',
          description: '',
          assignedAmount: 150.0,
          paidAmount: 0.0,
          amountDue: 0.0,
          status: 'waived',
          paymentStatus: 'unpaid',
          qrTicketUnlocked: false,
        ),
        PayableModel(
          id: 'pay_3',
          studentId: 'stud_1',
          studentName: 'Juan',
          studentSchoolId: '02000111222',
          organizationId: 'org_1',
          semesterId: 'sem_1',
          type: 'event_fee',
          label: 'Cancelled Event - Refund Pending',
          description: '',
          assignedAmount: 200.0,
          paidAmount: 200.0,
          amountDue: 0.0,
          status: 'refund_pending',
          paymentStatus: 'paid',
          qrTicketUnlocked: false,
          refundDue: 200.0,
        ),
        PayableModel(
          id: 'pay_4',
          studentId: 'stud_1',
          studentName: 'Juan',
          studentSchoolId: '02000111222',
          organizationId: 'org_1',
          semesterId: 'sem_1',
          type: 'event_fee',
          label: 'Cancelled Event - Disbursed',
          description: '',
          assignedAmount: 300.0,
          paidAmount: 300.0,
          amountDue: 0.0,
          status: 'refunded',
          paymentStatus: 'paid',
          qrTicketUnlocked: false,
        ),
      ];

      final summary = PayablesSummary.fromPayables(payables);

      // Only pay_1 should count towards totalOutstanding and pendingCount!
      expect(summary.totalOutstanding, 100.0);
      expect(summary.pendingCount, 1);
    });
  });

  group('Scanner Assignment Cancellation Tests', () {
    test('ScannerAssignmentModel disables scanning if event is cancelled', () {
      final assignment = ScannerAssignmentModel(
        eventId: 'ev_123',
        eventTitle: 'Cancelled Workshop',
        sessions: [
          {'id': 's1', 'date': '2026-10-10', 'startTime': '09:00', 'endTime': '16:00'}
        ],
        officerUserId: 'off_1',
        permissions: {'fullAccess': true, 'canCheckIn': true, 'canCheckOut': true},
        eventEndTime: DateTime.now().add(const Duration(hours: 2)),
        proposalStatus: 'approved',
        isCancelled: true,
        cancellationReason: 'Speaker unavailable',
      );

      expect(assignment.isEffectivelyCancelled, isTrue);
      expect(assignment.canScan, isFalse);
    });
  });
}
