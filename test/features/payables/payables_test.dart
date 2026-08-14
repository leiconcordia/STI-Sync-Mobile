import 'package:flutter_test/flutter_test.dart';
import 'package:sti_sync/features/payables/models/payable_model.dart';
import 'package:sti_sync/features/payables/repositories/payables_repository.dart';

void main() {
  group('PayableModel and Financial Logic Tests', () {
    test('PayableType and PayableStatus parsing', () {
      expect(PayableType.fromString('event_fee'), PayableType.eventFee);
      expect(PayableType.fromString('membership_due'), PayableType.membershipDue);
      expect(PayableType.fromString('org_fine'), PayableType.orgFine);
      expect(PayableType.fromString('admin_fine'), PayableType.adminFine);
      expect(PayableType.fromString('unknown'), PayableType.eventFee);

      expect(PayableStatus.fromString('pending'), PayableStatus.pending);
      expect(PayableStatus.fromString('partial'), PayableStatus.partial);
      expect(PayableStatus.fromString('paid'), PayableStatus.paid);
      expect(PayableStatus.fromString('overdue'), PayableStatus.overdue);
      expect(PayableStatus.fromString('waived'), PayableStatus.waived);
    });

    test('Strict Partial Payment Lock: Remaining balance and isPaid calculation', () {
      final partialPayable = PayableModel(
        id: 'pay_1',
        studentId: 'stud_123',
        studentName: 'Lei Concordia',
        studentSchoolId: '02000123456',
        organizationId: 'club_itg',
        organizationName: 'IT Guild',
        semesterId: 'sem_1',
        type: 'membership_due',
        label: 'IT Guild Membership Fee',
        description: 'Semester 1 membership fee',
        assignedAmount: 100.0,
        paidAmount: 40.0,
        amountDue: 60.0,
        status: 'partial',
        paymentStatus: 'unpaid',
        qrTicketUnlocked: false,
        paidAt: null,
      );

      expect(partialPayable.remainingBalance, 60.0);
      expect(partialPayable.isPaid, false);
      expect(partialPayable.isPending, true);
      expect(partialPayable.isCampusWide, false);
      expect(partialPayable.payableType, PayableType.membershipDue);
      expect(partialPayable.payableStatus, PayableStatus.partial);
    });

    test('Full Payment Unlock: Remaining balance 0 and isPaid true', () {
      final fullPayable = PayableModel(
        id: 'pay_2',
        studentId: 'stud_123',
        studentName: 'Lei Concordia',
        studentSchoolId: '02000123456',
        organizationId: null, // Campus wide / SAO
        organizationName: null,
        semesterId: 'sem_1',
        type: 'event_fee',
        label: 'College Week 2026',
        description: 'Access to College Week',
        assignedAmount: 150.0,
        paidAmount: 150.0,
        amountDue: 0.0,
        status: 'paid',
        paymentStatus: 'paid',
        qrTicketUnlocked: true,
        paidAt: DateTime.now(),
      );

      expect(fullPayable.remainingBalance, 0.0);
      expect(fullPayable.isPaid, true);
      expect(fullPayable.isPending, false);
      expect(fullPayable.isCampusWide, true);
      expect(fullPayable.qrTicketUnlocked, true);
    });

    test('PayablesSummary computes outstanding, paid percentage, and counts correctly', () {
      final p1 = PayableModel(
        id: 'pay_1',
        studentId: 'stud_1',
        studentName: 'Lei',
        studentSchoolId: '02000',
        semesterId: 'sem_1',
        type: 'event_fee',
        label: 'Fee 1',
        description: '',
        assignedAmount: 100.0,
        paidAmount: 100.0,
        amountDue: 0.0,
        status: 'paid',
        paymentStatus: 'paid',
        qrTicketUnlocked: true,
      );

      final p2 = PayableModel(
        id: 'pay_2',
        studentId: 'stud_1',
        studentName: 'Lei',
        studentSchoolId: '02000',
        semesterId: 'sem_1',
        type: 'membership_due',
        label: 'Fee 2',
        description: '',
        assignedAmount: 100.0,
        paidAmount: 50.0,
        amountDue: 50.0,
        status: 'partial',
        paymentStatus: 'unpaid',
        qrTicketUnlocked: false,
        dueDate: DateTime.now().add(const Duration(days: 5)),
      );

      final p3 = PayableModel(
        id: 'pay_3',
        studentId: 'stud_1',
        studentName: 'Lei',
        studentSchoolId: '02000',
        semesterId: 'sem_1',
        type: 'admin_fine',
        label: 'Fine 1',
        description: 'Late violation',
        assignedAmount: 50.0,
        paidAmount: 0.0,
        amountDue: 50.0,
        status: 'pending',
        paymentStatus: 'unpaid',
        qrTicketUnlocked: false,
        dueDate: DateTime.now().subtract(const Duration(days: 2)), // Overdue
      );

      final summary = PayablesSummary.fromPayables([p1, p2, p3]);

      expect(summary.totalAssigned, 250.0);
      expect(summary.totalPaid, 150.0);
      expect(summary.totalOutstanding, 100.0);
      expect(summary.paidPercentage, 150.0 / 250.0);
      expect(summary.pendingCount, 2);
      expect(summary.overdueCount, 1);
      expect(summary.nextDue?.id, 'pay_3');
    });

    test('Firestore serialization and deserialization preserves all fields', () {
      final now = DateTime.now();
      final map = {
        'studentId': 'student_abc',
        'studentName': 'Maria Santos',
        'studentSchoolId': '02000987654',
        'organizationId': 'club_acm',
        'organizationName': 'ACM Student Chapter',
        'eventId': 'event_tech_summit',
        'semesterId': 'sem_2026_1',
        'type': 'membership_due',
        'label': 'ACM Membership 2026',
        'description': 'Annual dues',
        'assignedAmount': 200,
        'paidAmount': 100,
        'amountDue': 100,
        'status': 'partial',
        'paymentStatus': 'unpaid',
        'qrTicketUnlocked': false,
        'paymentMethod': 'gcash',
        'paymentReference': 'GCASH-998877',
      };

      final payable = PayableModel.fromFirestore(map, 'doc_123');

      expect(payable.id, 'doc_123');
      expect(payable.studentId, 'student_abc');
      expect(payable.studentName, 'Maria Santos');
      expect(payable.studentSchoolId, '02000987654');
      expect(payable.organizationId, 'club_acm');
      expect(payable.assignedAmount, 200.0);
      expect(payable.paidAmount, 100.0);
      expect(payable.remainingBalance, 100.0);
      expect(payable.isPaid, false);
      expect(payable.paymentMethod, 'gcash');
      expect(payable.paymentReference, 'GCASH-998877');

      final serialized = payable.toMap();
      expect(serialized['id'], 'doc_123');
      expect(serialized['assignedAmount'], 200.0);
      expect(serialized['paymentMethod'], 'gcash');
    });
  });
}
