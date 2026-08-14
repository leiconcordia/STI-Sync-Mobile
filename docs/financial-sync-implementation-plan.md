# STI Sync Mobile — Comprehensive Financial & Payables Real-Time Sync Implementation Plan

> **Document Type:** Mobile Architecture & Technical Implementation Plan  
> **Target Platform:** Android (Flutter / Dart)  
> **Location:** `C:\Users\Lei_Concordia\AndroidStudioProjects\STI_Sync\docs\financial-sync-implementation-plan.md`  
> **Shared Backend:** Firebase Firestore & Drift (SQLite Local Database)  
> **Related Web Documentation:** `c:\VSCODE PROJECTS\STI Sync Web\docs\financial-system-guide.md`  
> **Last Updated:** August 2026  

---

## 1. Executive Summary & Problem Context

The STI Sync Web Portal has upgraded its financial subsystem to enforce **strict financial independence** between Admin (School/SAO) and Organizations (Clubs), and introduced **dynamic late-registration & active-state student payable synchronization**.

### The Core Problem Solved
Previously, payables were generated only once when an event was published. Students who registered late, students who were in `PENDING` verification and approved to `ACTIVE` mid-semester, or students newly enrolled in a club never received existing payables or membership dues.

With the new web engine:
1. When a student becomes `ACTIVE` or joins a club/department, the backend retroactively generates their missing `/payables` records.
2. The mobile app must reactively stream these documents, display them in a dedicated **Payables Center**, link them to event tickets, and lock/unlock QR gate access via `qrTicketUnlocked`.

---

## 2. Confirmed Core Business Rules & System Policies

1. **Partial Payment QR Unlock Policy (Option A — Strict)**:
   - Partial payments (e.g. paying ₱30 of ₱50) will **NOT** automatically unlock the QR ticket.
   - `qrTicketUnlocked` remains `false` until **100% of the balance is paid** (`paidAmount >= assignedAmount` or `status == 'paid'`), OR unless an Admin/Officer explicitly overrides and toggles the unlock switch on the web portal.
2. **Offline Scanner Enforcement Policy (Option A — Strict)**:
   - When an officer scanner device is offline, it queries local Drift SQLite `cached_payables`.
   - If a student's payable record is missing from the local SQLite cache (e.g., student registered after the offline cache download), the scanner **strictly rejects entry** with the error: *"Payment Verification Required Online — Record Not Found in Offline Cache"*.
3. **New Payable Notification & Badge System**:
   - **In-App Badging**: A real-time badge count appears on the Payables navigation bar tab indicating unviewed/unsettled obligations.
   - **Local / Push Notifications**: Whenever a new payable is assigned dynamically to the student, a notification is triggered: *"New Obligation: [Label] (₱[Amount]) has been added to your payables."*

---

## 3. Architecture & Data Flow

```
                                 [FIREBASE FIRESTORE]
                                   /payables/{id}
                                         │
                 ┌───────────────────────┴───────────────────────┐
                 │                                               │
                 ▼ (Real-time .snapshots())                      ▼ (One-time get / Offline sync)
      ┌───────────────────────┐                       ┌───────────────────────┐
      │   PAYABLES REPOSITORY │                       │  DRIFT LOCAL DATABASE │
      │ (PayablesRepository)  │ ── [Cache Sync] ────► │   (cached_payables)   │
      └──────────┬────────────┘                       └───────────┬───────────┘
                 │                                                │
                 ▼                                                ▼ (Offline Fallback)
      ┌───────────────────────┐                       ┌───────────────────────┐
      │   RIVERPOD PROVIDERS  │                       │  OFFLINE SCANNER      │
      │ • studentPayables     │                       │  VERIFICATION GUARD   │
      │ • eventPayableFamily  │                       │ (Strict Cache Check)  │
      │ • payablesSummary     │                       └───────────────────────┘
      │ • unreadPayablesBadge │
      └──────────┬────────────┘
                 │
       ┌─────────┴─────────┐
       ▼                   ▼
┌──────────────┐   ┌──────────────┐
│ PAYABLES     │   │ EVENT TICKET │
│ CENTER UI    │   │ QR PASS VIEW │
└──────────────┘   └──────────────┘
```

---

## 4. Detailed Data Models & Drift Schema

### 4.1 Domain Model (`lib/features/payables/domain/models/payable_model.dart`)

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
  final String? organizationId;      // null = School/SAO, non-null = Specific Club
  final String? organizationName;    // Denormalized name e.g. "IT Guild"
  final String semesterId;
  final String? eventId;             // FK to /events (if event-related)
  final double assignedAmount;
  final double paidAmount;
  final PayableStatus status;
  final DateTime? dueDate;
  final DateTime? paidAt;
  final String? recordedBy;
  final String? paymentMethod;
  final bool qrTicketUnlocked;       // Explicit gate pass unlock flag
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

  /// Computed financial properties
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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'studentName': studentName,
      'studentSchoolId': studentSchoolId,
      'type': type.value,
      'label': label,
      'description': description,
      'organizationId': organizationId,
      'organizationName': organizationName,
      'semesterId': semesterId,
      'eventId': eventId,
      'assignedAmount': assignedAmount,
      'paidAmount': paidAmount,
      'status': status.value,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'paidAt': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
      'recordedBy': recordedBy,
      'paymentMethod': paymentMethod,
      'qrTicketUnlocked': qrTicketUnlocked,
    };
  }
}
```

---

### 4.2 Drift Local SQLite Table (`lib/core/database/tables/cached_payables_table.dart`)

```dart
import 'package:drift/drift.dart';

@DataClassName('CachedPayable')
class CachedPayables extends Table {
  TextColumn get id => text()();
  TextColumn get studentId => text()();
  TextColumn get studentName => text()();
  TextColumn get studentSchoolId => text()();
  TextColumn get type => text()();
  TextColumn get label => text()();
  TextColumn get organizationId => text().nullable()();
  TextColumn get organizationName => text().nullable()();
  TextColumn get eventId => text().nullable()();
  TextColumn get semesterId => text()();
  RealColumn get assignedAmount => real()();
  RealColumn get paidAmount => real()();
  TextColumn get status => text()();
  BoolColumn get qrTicketUnlocked => boolean().withDefault(const Constant(false))();
  DateTimeColumn get dueDate => dateTime().nullable()();
  DateTimeColumn get paidAt => dateTime().nullable()();
  DateTimeColumn get cachedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
```

---

## 5. Repository & State Management (Riverpod)

### 5.1 Payables Repository (`lib/features/payables/data/repositories/payables_repository.dart`)

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/payable_model.dart';
import '../../../../core/database/app_database.dart';

abstract class PayablesRepository {
  Stream<List<PayableModel>> watchStudentPayables(String studentId);
  Stream<PayableModel?> watchEventPayable(String studentId, String eventId);
  Future<List<PayableModel>> fetchStudentPayables(String studentId);
  Future<bool> verifyQrTicketAccess({
    required String studentId,
    required String eventId,
    required bool isOnline,
  });
}

class PayablesRepositoryImpl implements PayablesRepository {
  final FirebaseFirestore _firestore;
  final AppDatabase _db;

  PayablesRepositoryImpl(this._firestore, this._db);

  @override
  Stream<List<PayableModel>> watchStudentPayables(String studentId) {
    return _firestore
        .collection('payables')
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map((snapshot) {
          final payables = snapshot.docs.map((doc) => PayableModel.fromFirestore(doc)).toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          
          // Cache locally to Drift in background
          _cachePayablesLocally(payables);
          return payables;
        });
  }

  @override
  Stream<PayableModel?> watchEventPayable(String studentId, String eventId) {
    return _firestore
        .collection('payables')
        .where('studentId', isEqualTo: studentId)
        .where('eventId', isEqualTo: eventId)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          return PayableModel.fromFirestore(snapshot.docs.first);
        });
  }

  @override
  Future<List<PayableModel>> fetchStudentPayables(String studentId) async {
    final snap = await _firestore
        .collection('payables')
        .where('studentId', isEqualTo: studentId)
        .get();
    return snap.docs.map((doc) => PayableModel.fromFirestore(doc)).toList();
  }

  @override
  Future<bool> verifyQrTicketAccess({
    required String studentId,
    required String eventId,
    required bool isOnline,
  }) async {
    if (isOnline) {
      final snap = await _firestore
          .collection('payables')
          .where('studentId', isEqualTo: studentId)
          .where('eventId', isEqualTo: eventId)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) return true; // Free event (no payable required)
      final payable = PayableModel.fromFirestore(snap.docs.first);
      return payable.qrTicketUnlocked;
    } else {
      // ─── STRICT OFFLINE VERIFICATION (Option A) ───
      final cached = await (_db.select(_db.cachedPayables)
            ..where((tbl) => tbl.studentId.equals(studentId) & tbl.eventId.equals(eventId))
            ..limit(1))
          .getSingleOrNull();

      if (cached == null) {
        // Strict: Missing from offline cache => Reject
        throw OfflinePayableNotFoundException(
          'Payment record missing in offline cache. Online verification required.',
        );
      }
      return cached.qrTicketUnlocked;
    }
  }

  void _cachePayablesLocally(List<PayableModel> payables) {
    _db.batch((batch) {
      for (final p in payables) {
        batch.insert(
          _db.cachedPayables,
          CachedPayablesCompanion.insert(
            id: p.id,
            studentId: p.studentId,
            studentName: p.studentName,
            studentSchoolId: p.studentSchoolId,
            type: p.type.value,
            label: p.label,
            organizationId: Value(p.organizationId),
            organizationName: Value(p.organizationName),
            eventId: Value(p.eventId),
            semesterId: p.semesterId,
            assignedAmount: p.assignedAmount,
            paidAmount: p.paidAmount,
            status: p.status.value,
            qrTicketUnlocked: Value(p.qrTicketUnlocked),
            dueDate: Value(p.dueDate),
            paidAt: Value(p.paidAt),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }
}

class OfflinePayableNotFoundException implements Exception {
  final String message;
  OfflinePayableNotFoundException(this.message);
  @override
  String toString() => message;
}
```

---

### 5.2 Riverpod Providers (`lib/features/payables/presentation/providers/payables_providers.dart`)

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/payable_model.dart';
import '../repositories/payables_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/database/database_provider.dart';

final payablesRepositoryProvider = Provider<PayablesRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return PayablesRepositoryImpl(FirebaseFirestore.instance, db);
});

/// Streams all payables for currently authenticated student
final studentPayablesStreamProvider = StreamProvider.autoDispose<List<PayableModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();
  final repo = ref.watch(payablesRepositoryProvider);
  return repo.watchStudentPayables(user.uid);
});

/// Family stream for specific event's payable
final eventPayableFamilyProvider = StreamProvider.autoDispose.family<PayableModel?, String>((ref, eventId) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(null);
  final repo = ref.watch(payablesRepositoryProvider);
  return repo.watchEventPayable(user.uid, eventId);
});

/// Filter selection state: 'all' | 'event_fee' | 'membership_due' | 'fine'
final payablesFilterProvider = StateProvider.autoDispose<String>((ref) => 'all');

/// Filtered payables list
final filteredPayablesProvider = Provider.autoDispose<List<PayableModel>>((ref) {
  final payablesAsync = ref.watch(studentPayablesStreamProvider);
  final filter = ref.watch(payablesFilterProvider);

  return payablesAsync.maybeWhen(
    data: (payables) {
      if (filter == 'all') return payables;
      if (filter == 'event_fee') {
        return payables.where((p) => p.type == PayableType.eventFee).toList();
      }
      if (filter == 'membership_due') {
        return payables.where((p) => p.type == PayableType.membershipDue).toList();
      }
      if (filter == 'fine') {
        return payables.where((p) => p.type == PayableType.orgFine || p.type == PayableType.adminFine).toList();
      }
      return payables;
    },
    orElse: () => [],
  );
});

/// Financial summary statistics & badge counts
final payablesSummaryProvider = Provider.autoDispose<{
  double totalOutstanding;
  double totalPaid;
  int pendingCount;
  int overdueCount;
}>((ref) {
  final payables = ref.watch(studentPayablesStreamProvider).valueOrNull ?? [];
  double totalOutstanding = 0;
  double totalPaid = 0;
  int pendingCount = 0;
  int overdueCount = 0;

  for (final p in payables) {
    totalOutstanding += p.remainingBalance;
    totalPaid += p.paidAmount;
    if (!p.isPaid) pendingCount++;
    if (p.isOverdue) overdueCount++;
  }

  return {
    'totalOutstanding': totalOutstanding,
    'totalPaid': totalPaid,
    'pendingCount': pendingCount,
    'overdueCount': overdueCount,
  };
});

/// Unsettled payables count for Navigation Bar Badge
final unreadPayablesBadgeProvider = Provider.autoDispose<int>((ref) {
  final summary = ref.watch(payablesSummaryProvider);
  return summary['pendingCount'] as int;
});
```

---

## 6. Officer Gate Scanner Guard (`lib/features/scanner/presentation/controllers/scanner_controller.dart`)

Strict validation before recording attendance at gate check-in:

```dart
Future<ScanResult> processGateScan({
  required String eventId,
  required String studentAuthUid,
  required bool isOnline,
}) async {
  // 1. Check if event has a fee
  final event = await _eventRepo.getEventById(eventId);
  if (event.studentPayablesEnabled && (event.feeAmount ?? 0) > 0) {
    try {
      // 2. Strict Access Control Check
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
    } on OfflinePayableNotFoundException catch (e) {
      // ─── STRICT OFFLINE REJECTION (Option A) ───
      return ScanResult.rejected(
        reason: 'Payment Verification Required Online: No record found in offline cache.',
        showPaymentPrompt: false,
      );
    }
  }

  // 3. Proceed to log attendance
  return _attendanceRepo.recordCheckIn(eventId: eventId, studentId: studentAuthUid);
}
```

---

## 7. Testing & Defense Verification Matrix

| Step | Action | Expected Mobile Behavior |
|---|---|---|
| **1. Dynamic New Student Registration** | Register new student on mobile; Admin marks `ACTIVE` in web portal | Student opens mobile app; `/payables` instantly populates with all ongoing semester events and dues without re-registration. |
| **2. Dynamic Club Membership** | Officer adds student to club in web portal | Mobile app immediately displays `Membership Due` with club name badge + Navigation Bar Badge increments. |
| **3. Partial Payment Strict Lock (Option A)** | Student pays ₱25 of ₱50 | `paidAmount` becomes ₱25, `remainingBalance` is ₱25; **QR ticket remains strictly LOCKED**. |
| **4. Full Payment Instant Unlock** | Student settles remaining ₱25 | Screen updates in real-time within <1s; Lock overlay disappears; **QR ticket renders active and ready for scanning**. |
| **5. Strict Offline Scanner Missing Check (Option A)** | Scanner device offline; Scans newly activated student not in cache | Scanner displays red screen: *"PAYMENT VERIFICATION REQUIRED ONLINE — Record Not Found in Offline Cache"*. |
| **6. Offline Scanner Cached Paid Check** | Scanner device offline; Scans student with cached `qrTicketUnlocked == true` | Scanner accepts attendance and writes to Drift `offline_attendance`. |

---

## 8. Implementation Checklist

- [ ] **Phase 1: Domain & Data Layer**
  - [ ] Implement `PayableType` and `PayableStatus` enums.
  - [ ] Implement `PayableModel` with full serialization and computed getters.
  - [ ] Add `CachedPayables` table to Drift database and execute code generation.
  - [ ] Implement `PayablesRepository` with strict offline verification support.
- [ ] **Phase 2: State Management (Riverpod) & Badges**
  - [ ] Create `studentPayablesStreamProvider`.
  - [ ] Create `eventPayableFamilyProvider`.
  - [ ] Create `payablesSummaryProvider` and `unreadPayablesBadgeProvider`.
- [ ] **Phase 3: Presentation UI & Notifications**
  - [ ] Build `PayablesScreen` with summary hero card, badge indicators, and filter chips.
  - [ ] Build `PayableCardWidget` with SAO vs Club badges.
  - [ ] Build `PaymentInstructionsBottomSheet`.
  - [ ] Update `EventDetailScreen` with reactive QR lock/unlock overlay (strict 100% full payment lock rule).
  - [ ] Update `ScannerController` with Option A strict online/offline gate check.
- [ ] **Phase 4: Verification & Defense Validation**
  - [ ] Test real-time sync with Web portal payment recording.
  - [ ] Test offline gate scan validation using local Drift cache.
