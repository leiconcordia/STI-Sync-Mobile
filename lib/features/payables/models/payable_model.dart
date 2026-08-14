import 'package:cloud_firestore/cloud_firestore.dart';

enum PayableType {
  eventFee('event_fee', 'Event Fee'),
  membershipDue('membership_due', 'Membership Due'),
  orgFine('org_fine', 'Club Fine'),
  adminFine('admin_fine', 'SAO Violation Fine'),
  custom('custom', 'Custom Fee');

  final String value;
  final String label;
  const PayableType(this.value, this.label);

  static PayableType fromString(String? val) {
    if (val == null) return PayableType.eventFee;
    return PayableType.values.firstWhere(
      (e) => e.value.toLowerCase() == val.toLowerCase(),
      orElse: () => PayableType.eventFee,
    );
  }
}

enum PayableStatus {
  pending('pending', 'Pending Payment'),
  partial('partial', 'Partially Paid'),
  paid('paid', 'Fully Paid'),
  overdue('overdue', 'Overdue'),
  waived('waived', 'Waived');

  final String value;
  final String label;
  const PayableStatus(this.value, this.label);

  static PayableStatus fromString(String? val) {
    if (val == null) return PayableStatus.pending;
    return PayableStatus.values.firstWhere(
      (e) => e.value.toLowerCase() == val.toLowerCase(),
      orElse: () => PayableStatus.pending,
    );
  }
}

/// Represents a student payment obligation in Firestore (`/payables/{payableId}`).
class PayableModel {
  final String id;
  final String studentId;                 // Student Auth UID
  final String studentName;               // Denormalized student full name (e.g. "Lei Concordia")
  final String studentSchoolId;           // Official 11-digit STI Student ID (e.g. "02000123456")
  final String? organizationId;           // FK → /organizations (null for School/SAO)
  final String? organizationName;         // Denormalized organization name
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

  PayableType get payableType => PayableType.fromString(type);
  PayableStatus get payableStatus => PayableStatus.fromString(status);

  /// Computed financial & access properties
  double get remainingBalance => (assignedAmount - paidAmount).clamp(0.0, double.infinity);
  bool get isPaid => status == 'paid' || paymentStatus == 'paid' || status == 'waived' || paymentStatus == 'waived' || remainingBalance <= 0;
  bool get isPending => !isPaid;
  bool get isOverdue => dueDate != null && DateTime.now().isAfter(dueDate!) && !isPaid;
  bool get isCampusWide => organizationId == null || organizationId!.trim().isEmpty;

  factory PayableModel.fromFirestore(Map<String, dynamic> data, String docId) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
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
      studentSchoolId: data['studentSchoolId'] as String? ?? data['studentId'] as String? ?? data['schoolId'] as String? ?? '',
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

  factory PayableModel.fromFirestoreDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    return PayableModel.fromFirestore(doc.data() ?? {}, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'studentName': studentName,
      'studentSchoolId': studentSchoolId,
      'organizationId': organizationId,
      'organizationName': organizationName,
      'eventId': eventId,
      'semesterId': semesterId,
      'type': type,
      'label': label,
      'description': description,
      'assignedAmount': assignedAmount,
      'paidAmount': paidAmount,
      'amountDue': amountDue,
      'status': status,
      'paymentStatus': paymentStatus,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'qrTicketUnlocked': qrTicketUnlocked,
      'paidAt': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
      'recordedBy': recordedBy,
      'paymentMethod': paymentMethod,
      'paymentReference': paymentReference,
      'transactions': transactions,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }
}

