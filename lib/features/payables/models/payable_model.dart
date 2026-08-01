import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a student payment obligation in Firestore (`/payables/{payableId}`).
class PayableModel {
  final String id;
  final String studentId;                 // Student Auth UID
  final String studentName;               // Denormalized student full name (e.g. "Lei Concordia")
  final String studentSchoolId;           // Official 11-digit STI Student ID (e.g. "02000123456")
  final String? organizationId;           // FK → /organizations
  final String? organizationName;
  final String? eventId;                  // FK → /events (for event-specific fees)
  final String semesterId;

  // ─── Fee & Payment Status ───
  final String type;                      // 'membership_due' | 'event_fee' | 'org_fine' | 'admin_fine' | 'custom'
  final String label;                     // e.g. "Event Fee — IT Week 2026"
  final String description;
  final double assignedAmount;            // Total fee in PHP (₱)
  final double paidAmount;                // Amount paid to date in PHP (₱)
  final double amountDue;                 // Remaining balance or assigned fee
  final String status;                    // 'pending' | 'partial' | 'paid' | 'overdue' | 'waived'
  final String paymentStatus;             // Legacy compatibility field ('unpaid' | 'paid' | 'waived' | 'refunded')
  final DateTime? dueDate;

  // ─── Gate Control & Access ───
  final bool qrTicketUnlocked;            // Explicit gate control flag
  final DateTime? paidAt;
  final String? recordedBy;               // Officer or SAO Admin UID who recorded payment
  final String? paymentMethod;            // 'cash' | 'gcash' | 'bank_transfer'
  final String? paymentReference;         // Transaction ID or receipt number
  final List<dynamic>? transactions;      // Embedded payment transactions

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PayableModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.studentSchoolId,
    this.organizationId,
    this.organizationName,
    this.eventId,
    required this.semesterId,
    required this.type,
    required this.label,
    required this.description,
    required this.assignedAmount,
    required this.paidAmount,
    required this.amountDue,
    required this.status,
    required this.paymentStatus,
    this.dueDate,
    required this.qrTicketUnlocked,
    this.paidAt,
    this.recordedBy,
    this.paymentMethod,
    this.paymentReference,
    this.transactions,
    this.createdAt,
    this.updatedAt,
  });

  bool get isPaid => status == 'paid' || paymentStatus == 'paid' || status == 'waived' || paymentStatus == 'waived';
  bool get isPending => !isPaid;
  double get remainingBalance => (assignedAmount - paidAmount) > 0 ? (assignedAmount - paidAmount) : (isPaid ? 0 : amountDue);

  factory PayableModel.fromFirestore(Map<String, dynamic> data, String docId) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    final assigned = (data['assignedAmount'] ?? data['amount'] ?? 0).toDouble();
    final paid = (data['paidAmount'] ?? data['amountPaid'] ?? 0).toDouble();
    final rawDue = (data['amountDue'] ?? (assigned - paid)).toDouble();

    return PayableModel(
      id: docId,
      studentId: data['studentId'] as String? ?? '',
      studentName: data['studentName'] as String? ?? data['name'] as String? ?? 'Student',
      studentSchoolId: data['studentSchoolId'] as String? ?? data['schoolId'] as String? ?? '',
      organizationId: data['organizationId'] as String?,
      organizationName: data['organizationName'] as String?,
      eventId: data['eventId'] as String?,
      semesterId: data['semesterId'] as String? ?? '',
      type: data['type'] as String? ?? 'event_fee',
      label: data['label'] as String? ?? data['title'] as String? ?? 'Payable Fee',
      description: data['description'] as String? ?? '',
      assignedAmount: assigned,
      paidAmount: paid,
      amountDue: rawDue > 0 ? rawDue : (assigned - paid > 0 ? assigned - paid : 0.0),
      status: data['status'] as String? ?? (data['paymentStatus'] as String? ?? 'pending'),
      paymentStatus: data['paymentStatus'] as String? ?? (data['status'] as String? ?? 'unpaid'),
      dueDate: parseDate(data['dueDate']),
      qrTicketUnlocked: data['qrTicketUnlocked'] as bool? ?? false,
      paidAt: parseDate(data['paidAt']),
      recordedBy: data['recordedBy'] as String? ?? data['processedBy'] as String?,
      paymentMethod: data['paymentMethod'] as String?,
      paymentReference: data['paymentReference'] as String?,
      transactions: data['transactions'] as List<dynamic>?,
      createdAt: parseDate(data['createdAt']),
      updatedAt: parseDate(data['updatedAt']),
    );
  }
}
