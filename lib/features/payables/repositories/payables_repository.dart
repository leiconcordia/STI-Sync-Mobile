import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';
import 'package:sti_sync/core/constants/firestore_paths.dart';
import 'package:sti_sync/core/local/app_database.dart';
import 'package:sti_sync/features/payables/models/payable_model.dart';

class PayablesSummary {
  final double totalAssigned;
  final double totalPaid;
  final double totalOutstanding;
  final double paidPercentage;
  final int pendingCount;
  final int overdueCount;
  final PayableModel? nextDue;

  const PayablesSummary({
    required this.totalAssigned,
    required this.totalPaid,
    required this.totalOutstanding,
    required this.paidPercentage,
    required this.pendingCount,
    required this.overdueCount,
    this.nextDue,
  });

  factory PayablesSummary.fromPayables(List<PayableModel> payables) {
    if (payables.isEmpty) {
      return const PayablesSummary(
        totalAssigned: 0,
        totalPaid: 0,
        totalOutstanding: 0,
        paidPercentage: 1.0,
        pendingCount: 0,
        overdueCount: 0,
        nextDue: null,
      );
    }

    double assigned = 0;
    double paid = 0;
    int pendingCount = 0;
    int overdueCount = 0;

    for (final p in payables) {
      final itemTotal = p.assignedAmount > 0 ? p.assignedAmount : (p.amountDue + p.paidAmount);
      assigned += itemTotal;
      paid += p.paidAmount;
      if (!p.isPaid) {
        pendingCount++;
      }
      if (p.isOverdue) {
        overdueCount++;
      }
    }

    final outstanding = (assigned - paid).clamp(0.0, double.infinity);
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
      pendingCount: pendingCount,
      overdueCount: overdueCount,
      nextDue: pendingItems.isNotEmpty ? pendingItems.first : null,
    );
  }
}

class OfflinePayableNotFoundException implements Exception {
  final String message;
  OfflinePayableNotFoundException(this.message);
  @override
  String toString() => message;
}

class PayablesRepository {
  final FirebaseFirestore _firestore;
  final AppDatabase _db;

  PayablesRepository(this._firestore, this._db);

  /// Streams all payables targeting the specified student in real time.
  /// Automatically persists the stream snapshots into the local Drift SQLite cache.
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

      // Background Drift cache
      _cachePayablesLocally(list);

      return list;
    });
  }

  /// Streams payable for a specific student and event
  Stream<PayableModel?> watchEventPayable(String studentId, String eventId) {
    if (studentId.isEmpty || eventId.isEmpty) {
      return Stream.value(null);
    }

    return _firestore
        .collection(FirestorePaths.payables)
        .where('studentId', isEqualTo: studentId)
        .where('eventId', isEqualTo: eventId)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return PayableModel.fromFirestore(
        snapshot.docs.first.data(),
        snapshot.docs.first.id,
      );
    });
  }

  /// One-time fetch of student payables from Firestore
  Future<List<PayableModel>> fetchStudentPayables(String studentId) async {
    if (studentId.isEmpty) return [];
    final snap = await _firestore
        .collection(FirestorePaths.payables)
        .where('studentId', isEqualTo: studentId)
        .get();

    final list = snap.docs
        .map((doc) => PayableModel.fromFirestore(doc.data(), doc.id))
        .toList();
    _cachePayablesLocally(list);
    return list;
  }

  /// Verifies gate access for student / event.
  /// Enforces Strict Option A:
  /// - Online: Firestore check
  /// - Offline: Local Drift cache check. If missing, throws [OfflinePayableNotFoundException].
  Future<bool> verifyQrTicketAccess({
    required String studentId,
    required String eventId,
    required bool isOnline,
  }) async {
    if (isOnline) {
      final snap = await _firestore
          .collection(FirestorePaths.payables)
          .where('studentId', isEqualTo: studentId)
          .where('eventId', isEqualTo: eventId)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) {
        // Check if event is free or has no fee
        final eventDoc = await _firestore
            .collection(FirestorePaths.events)
            .doc(eventId)
            .get();
        if (eventDoc.exists) {
          final eventData = eventDoc.data() ?? {};
          final bool payablesEnabled = eventData['studentPayablesEnabled'] ?? false;
          final double fee = ((eventData['adminFeeOverride'] ?? eventData['feeAmount'] ?? 0) as num).toDouble();
          if (!payablesEnabled || fee <= 0) {
            return true; // Free event
          }
        }
        return false;
      }

      final payable = PayableModel.fromFirestore(snap.docs.first.data(), snap.docs.first.id);
      return payable.qrTicketUnlocked || (payable.isPaid && payable.remainingBalance <= 0);
    } else {
      // ─── STRICT OFFLINE VERIFICATION (Option A) ───
      final cached = await _db.payablesDao.getPayable(studentId, eventId);
      if (cached == null) {
        throw OfflinePayableNotFoundException(
          'Payment record missing in offline cache. Online verification required.',
        );
      }
      return cached.qrTicketUnlocked == 1 || cached.paymentStatus == 'paid' || cached.paymentStatus == 'free';
    }
  }

  void _cachePayablesLocally(List<PayableModel> payables) {
    if (payables.isEmpty) return;
    try {
      final companions = payables.map((p) {
        return CachedPayablesCompanion(
          id: drift.Value(p.id),
          studentId: drift.Value(p.studentId),
          studentName: drift.Value(p.studentName),
          studentSchoolId: drift.Value(p.studentSchoolId),
          type: drift.Value(p.type),
          label: drift.Value(p.label),
          description: drift.Value(p.description),
          organizationId: drift.Value(p.organizationId),
          organizationName: drift.Value(p.organizationName),
          eventId: drift.Value(p.eventId),
          semesterId: drift.Value(p.semesterId),
          assignedAmount: drift.Value(p.assignedAmount),
          paidAmount: drift.Value(p.paidAmount),
          amountDue: drift.Value(p.remainingBalance),
          status: drift.Value(p.status),
          paymentStatus: drift.Value(p.paymentStatus),
          qrTicketUnlocked: drift.Value(p.qrTicketUnlocked ? 1 : (p.isPaid ? 1 : 0)),
          dueDate: drift.Value(p.dueDate?.millisecondsSinceEpoch),
          paidAt: drift.Value(p.paidAt?.millisecondsSinceEpoch),
          cachedAt: drift.Value(DateTime.now().millisecondsSinceEpoch),
        );
      }).toList();

      _db.payablesDao.batchUpsertPayables(companions);
    } catch (e) {
      debugPrint('PayablesRepository: Error caching payables locally: $e');
    }
  }
}

