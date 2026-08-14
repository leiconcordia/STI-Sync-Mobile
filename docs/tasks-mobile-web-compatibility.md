# Mobile App Compatibility Task List — Web v2 Sync & Schema Alignments

> **Path:** `docs/tasks-mobile-web-compatibility.md`  
> **Target App:** STI Sync Android (Flutter / Dart)  
> **Shared Backend:** Firebase Firestore & Cloud Storage (shared with STI Sync Web v2)  
> **Related Architecture Guides:** `docs/financial-sync-implementation-plan.md`, `docs/features/financial-mobile-sync-guide.md`  
> **Status:** Web Backend Implemented — Mobile Implementation Ready  

---

## Executive Summary & Context

The STI Sync Web application has undergone major updates to support **Event Payables, Independent Admin/Club Ledgers, Gate Access Control (QR Ticket Locks), Denormalized Student Payables, and Dynamic Late-Registration Sync**.

Because both Web and Mobile apps share the same Firebase Firestore backend, the mobile app (Student & Officer views) must be updated to align with these schema additions and business logic rules.

---

## Detailed Task Matrix

| Task ID | Component / Feature | Impact Level | Summary of Required Changes | Status |
| :--- | :--- | :--- | :--- | :--- |
| **MOB-PAY-01** | `PayableModel` & Enums | **CRITICAL** | Parse `qrTicketUnlocked` (bool), `PayableType`, `PayableStatus`, `assignedAmount`, `paidAmount`. | **Specified** |
| **MOB-PAY-02** | Drift Local Database Cache | **CRITICAL** | Create `CachedPayables` table in Drift for offline gate access control. | **Specified** |
| **MOB-PAY-03** | Riverpod State Providers | **HIGH** | `studentPayablesStreamProvider`, `eventPayableFamilyProvider`, `unreadPayablesBadgeProvider`. | **Specified** |
| **MOB-PAY-04** | Payables Center UI | **HIGH** | Build `PayablesScreen` with SAO vs. Club badges and payment bottom sheet. | **Specified** |
| **MOB-GATE-01** | Student Event Ticket & QR Overlay | **CRITICAL** | Enforce strict Option A 100% full payment lock on `QrTicketScreen`. | **Specified** |
| **MOB-GATE-02** | Officer Gate Scanner Guard | **CRITICAL** | Enforce Option A strict online/offline cache verification before recording attendance. | **Specified** |
| **MOB-ANN-01** | `AnnouncementModel` & Feed Scoping | **HIGH** | Support `organizationId`, `linkedEventId`, `linkedEventTitle`, `targetDepartments`, `targetYearLevels`. | **Specified** |
| **MOB-ANN-02** | Announcement Linked Event Navigation | **MEDIUM** | Render clickable linked event button in announcement cards navigating to `EventDetailScreen`. | **Specified** |
| **MOB-ORG-01** | Organization Scope & Eligibility | **MEDIUM** | Filter departmental vs. cross-departmental clubs in student Org Explorer. | **Specified** |

---

## 1. Feature Breakdown & Implementation Code Specifications

### 1.1 Task MOB-PAY-01: `PayableModel` & Domain Enums

#### File: `lib/features/payables/domain/models/payable_model.dart`
```dart
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
    return PayableType.values.firstWhere(
      (e) => e.value == val,
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
    return PayableStatus.values.firstWhere(
      (e) => e.value == val,
      orElse: () => PayableStatus.pending,
    );
  }
}

class PayableModel {
  final String id;
  final String studentId;
  final String studentName;
  final String studentSchoolId;
  final PayableType type;
  final String label;
  final String description;
  final String? organizationId;
  final String? organizationName;
  final String semesterId;
  final String? eventId;
  final double assignedAmount;
  final double paidAmount;
  final PayableStatus status;
  final DateTime? dueDate;
  final DateTime? paidAt;
  final String? recordedBy;
  final String? paymentMethod;
  final bool qrTicketUnlocked;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PayableModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.studentSchoolId,
    required this.type,
    required this.label,
    required this.description,
    this.organizationId,
    this.organizationName,
    required this.semesterId,
    this.eventId,
    required this.assignedAmount,
    required this.paidAmount,
    required this.status,
    this.dueDate,
    this.paidAt,
    this.recordedBy,
    this.paymentMethod,
    required this.qrTicketUnlocked,
    required this.createdAt,
    required this.updatedAt,
  });

  double get remainingBalance => (assignedAmount - paidAmount).clamp(0.0, double.infinity);
  bool get isPaid => status == PayableStatus.paid || remainingBalance <= 0;
  bool get isOverdue => dueDate != null && DateTime.now().isAfter(dueDate!) && !isPaid;
  bool get isCampusWide => organizationId == null || organizationId!.isEmpty;

  factory PayableModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return PayableModel(
      id: doc.id,
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? 'Student',
      studentSchoolId: data['studentSchoolId'] ?? data['studentId'] ?? '',
      type: PayableType.fromString(data['type']),
      label: data['label'] ?? 'Payable',
      description: data['description'] ?? '',
      organizationId: data['organizationId'],
      organizationName: data['organizationName'],
      semesterId: data['semesterId'] ?? '',
      eventId: data['eventId'],
      assignedAmount: (data['assignedAmount'] ?? data['amount'] ?? 0).toDouble(),
      paidAmount: (data['paidAmount'] ?? 0).toDouble(),
      status: PayableStatus.fromString(data['status']),
      dueDate: (data['dueDate'] as Timestamp?)?.toDate(),
      paidAt: (data['paidAt'] as Timestamp?)?.toDate(),
      recordedBy: data['recordedBy'],
      paymentMethod: data['paymentMethod'],
      qrTicketUnlocked: data['qrTicketUnlocked'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
```

---

### 1.2 Task MOB-GATE-01: Strict QR Gate Lock Overlay on `QrTicketScreen`

#### Requirements
1. If event has `studentPayablesEnabled == true` and `fee > 0`:
   - Watch `eventPayableFamilyProvider(eventId)`.
   - If `payable == null` or `payable.qrTicketUnlocked == false`:
     - Render `LockedQrCard` with payment instructions.
     - **Security:** Do NOT render or generate the QR code payload on the widget tree.
2. When cashier records 100% full payment on the Web portal:
   - Live Firestore stream automatically sets `qrTicketUnlocked = true`.
   - `QrTicketScreen` unlocks immediately in real-time.

---

### 1.3 Task MOB-GATE-02: Officer Gate Scanner Access Verification

#### Scan Verification Rule (Option A — Strict):
```dart
Future<ScanResult> processGateScan({
  required String eventId,
  required String studentAuthUid,
  required bool isOnline,
}) async {
  final event = await _eventRepo.getEventById(eventId);
  if (event.studentPayablesEnabled && (event.feeAmount ?? 0) > 0) {
    try {
      final isAllowed = await _payablesRepo.verifyQrTicketAccess(
        studentId: studentAuthUid,
        eventId: eventId,
        isOnline: isOnline,
      );

      if (!isAllowed) {
        return ScanResult.rejected(
          reason: 'Payment Required: Student has unpaid event balance.',
          showPaymentPrompt: true,
        );
      }
    } on OfflinePayableNotFoundException catch (_) {
      return ScanResult.rejected(
        reason: 'Payment Verification Required Online: Record not found in offline cache.',
        showPaymentPrompt: false,
      );
    }
  }

  return _attendanceRepo.recordCheckIn(eventId: eventId, studentId: studentAuthUid);
}
```
