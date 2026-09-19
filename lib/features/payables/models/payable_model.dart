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
  waived('waived', 'Waived'),
  refundPending('refund_pending', 'Refund Pending'),
  refunded('refunded', 'Refund Disbursed');

  final String value;
  final String label;
  const PayableStatus(this.value, this.label);

  static PayableStatus fromString(String? val) {
    if (val == null) return PayableStatus.pending;
    final normalized = val.toLowerCase().replaceAll('-', '_');
    return PayableStatus.values.firstWhere(
      (e) => e.value.toLowerCase() == normalized,
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
  final String status;                    // 'pending' | 'partial' | 'paid' | 'overdue' | 'waived' | 'refund_pending' | 'refunded'
  final String paymentStatus;             // Legacy compatibility field ('unpaid' | 'paid' | 'waived' | 'refunded')
  final DateTime? dueDate;

  // ─── Cancellation, Waiver & Refund Context ───
  final DateTime? waivedAt;
  final String? waivedReason;
  final String? waivedBy;
  final double? refundDue;
  final String? refundReason;
  final String? refundMethod;
  final DateTime? refundedAt;
  final String? refundedBy;
  final String? refundReceiptNumber;

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
    this.waivedAt,
    this.waivedReason,
    this.waivedBy,
    this.refundDue,
    this.refundReason,
    this.refundMethod,
    this.refundedAt,
    this.refundedBy,
    this.refundReceiptNumber,
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

  // Status checkers
  bool get isWaived =>
      status.toLowerCase() == 'waived' ||
      paymentStatus.toLowerCase() == 'waived' ||
      waivedAt != null;

  bool get isRefundPending =>
      status.toLowerCase() == 'refund_pending' ||
      paymentStatus.toLowerCase() == 'refund_pending' ||
      status.toLowerCase().contains('pending_refund') ||
      (refundDue != null && refundDue! > 0 && !isRefunded);

  bool get isRefunded =>
      status.toLowerCase() == 'refunded' ||
      paymentStatus.toLowerCase() == 'refunded' ||
      status.toLowerCase() == 'refund' ||
      paymentStatus.toLowerCase() == 'refund' ||
      refundedAt != null;

  /// True if this item represents a zero-liability / resolved state for student clearance.
  bool get isCleared => isPaid || isWaived || isRefundPending || isRefunded;

  /// True if payment is actively owed by the student (blocks clearance).
  bool get blocksClearance => !isCleared;

  /// Computed financial & access properties
  double get remainingBalance {
    if (isWaived || isRefundPending || isRefunded) return 0.0;
    return (assignedAmount - paidAmount).clamp(0.0, double.infinity);
  }

  bool get isPaid =>
      status == 'paid' ||
      paymentStatus == 'paid' ||
      isWaived ||
      isRefunded ||
      (!isRefundPending && (assignedAmount > 0 && paidAmount >= assignedAmount));

  bool get isPending => !isPaid && !isWaived && !isRefundPending && !isRefunded;
  bool get isOverdue => dueDate != null && DateTime.now().isAfter(dueDate!) && isPending;
  bool get isCampusWide {
    if (organizationId == null) return true;
    final org = organizationId!.trim().toLowerCase();
    return org.isEmpty ||
        org == 'sas' ||
        org == 'sao' ||
        org == 'sas_admin' ||
        org == 'sao_admin' ||
        org == 'admin' ||
        org == 'sti' ||
        org == 'sti_college';
  }

  String get organizerDisplayName =>
      organizationName?.trim().isNotEmpty == true
          ? organizationName!
          : (isCampusWide ? 'STI College / SAO' : 'Student Organization');

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
      organizationId: data['organizationId'] as String? ?? data['organization_id'] as String? ?? data['orgId'] as String?,
      organizationName: data['organizationName'] as String? ??
          data['orgName'] as String? ??
          data['organization_name'] as String? ??
          data['org_name'] as String? ??
          data['organizationTitle'] as String?,
      eventId: data['eventId'] as String?,
      semesterId: data['semesterId'] as String? ?? '',
      type: data['type'] as String? ?? 'event_fee',
      label: data['label'] as String? ?? data['title'] as String? ?? 'Payable Fee',
      description: data['description'] as String? ?? '',
      assignedAmount: assigned,
      paidAmount: paid,
      amountDue: rawDue > 0 ? rawDue : (assigned - paid > 0 ? assigned - paid : 0.0),
      status: (data['status'] as String? ?? data['paymentStatus'] as String? ?? 'pending').toLowerCase(),
      paymentStatus: (data['paymentStatus'] as String? ?? data['status'] as String? ?? 'unpaid').toLowerCase(),
      dueDate: parseDate(data['dueDate']),
      waivedAt: parseDate(data['waivedAt'] ?? data['waived_at']),
      waivedReason: (data['waivedReason'] ?? data['waived_reason']) as String?,
      waivedBy: (data['waivedBy'] ?? data['waived_by']) as String?,
      refundDue: ((data['refundDue'] ?? data['refundAmount'] ?? data['refundedAmount'] ?? data['amountRefunded']) as num?)?.toDouble() ??
          (((data['status'] ?? data['paymentStatus'])?.toString().toLowerCase().contains('refund') == true) ? (paid > 0 ? paid : assigned) : null),
      refundReason: (data['refundReason'] ?? data['refund_reason'] ?? data['reason']) as String?,
      refundMethod: (data['refundMethod'] ?? data['refund_method'] ?? data['disbursementMethod']) as String?,
      refundedAt: parseDate(data['refundedAt'] ?? data['refunded_at'] ?? data['refundDate'] ?? data['refund_date']),
      refundedBy: (data['refundedBy'] ?? data['refunded_by']) as String?,
      refundReceiptNumber: (data['refundReceiptNumber'] ?? data['refund_receipt_number'] ?? data['refundReceipt'] ?? data['receiptNumber'] ?? data['referenceNumber']) as String?,
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
      'waivedAt': waivedAt != null ? Timestamp.fromDate(waivedAt!) : null,
      'waivedReason': waivedReason,
      'waivedBy': waivedBy,
      'refundDue': refundDue,
      'refundReason': refundReason,
      'refundMethod': refundMethod,
      'refundedAt': refundedAt != null ? Timestamp.fromDate(refundedAt!) : null,
      'refundedBy': refundedBy,
      'refundReceiptNumber': refundReceiptNumber,
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

