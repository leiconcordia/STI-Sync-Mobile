import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sti_sync/core/constants/firestore_paths.dart';
import 'package:sti_sync/features/payables/models/payable_model.dart';

class PayablesSummary {
  final double totalAssigned;
  final double totalPaid;
  final double totalOutstanding;
  final double paidPercentage;
  final PayableModel? nextDue;

  const PayablesSummary({
    required this.totalAssigned,
    required this.totalPaid,
    required this.totalOutstanding,
    required this.paidPercentage,
    this.nextDue,
  });

  factory PayablesSummary.fromPayables(List<PayableModel> payables) {
    if (payables.isEmpty) {
      return const PayablesSummary(
        totalAssigned: 0,
        totalPaid: 0,
        totalOutstanding: 0,
        paidPercentage: 1.0,
        nextDue: null,
      );
    }

    double assigned = 0;
    double paid = 0;

    for (final p in payables) {
      assigned += p.assignedAmount > 0 ? p.assignedAmount : p.amountDue + p.paidAmount;
      paid += p.paidAmount;
    }

    final outstanding = (assigned - paid) > 0 ? (assigned - paid) : 0.0;
    final percentage = assigned > 0 ? (paid / assigned).clamp(0.0, 1.0) : 1.0;

    // Find next upcoming due item among pending ones
    final pendingItems = payables.where((p) => p.isPending).toList();
    pendingItems.sort((a, b) {
      if (a.dueDate == null) return 1;
      if (b.dueDate == null) return -1;
      return a.dueDate!.compareTo(b.dueDate!);
    });

    return PayablesSummary(
      totalAssigned: assigned,
      totalPaid: paid,
      totalOutstanding: outstanding,
      paidPercentage: percentage,
      nextDue: pendingItems.isNotEmpty ? pendingItems.first : null,
    );
  }
}

class PayablesRepository {
  final FirebaseFirestore _firestore;

  PayablesRepository(this._firestore);

  /// Streams all payables targeting the specified student in real time.
  Stream<List<PayableModel>> watchStudentPayables(String studentId) {
    if (studentId.isEmpty) {
      return Stream.value([]);
    }

    return _firestore
        .collection(FirestorePaths.payables)
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => PayableModel.fromFirestore(doc.data(), doc.id))
          .toList();

      // Sort client-side by createdAt DESC
      list.sort((a, b) {
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });

      return list;
    });
  }
}
