# STI Sync Mobile — Database Schema Reference

> **Single source of truth** for all Firestore collections the mobile app reads or writes.
> **Agent rule:** Verify every field against this doc before writing a query or model. If a field is missing, update this doc first, then implement.
> **Shared backend:** This app reads from the same Firestore project as the STI Sync Web app. Do NOT redefine existing collections — only document what the mobile app actively uses.

---

## 1. Collections the Mobile App Accesses

| Collection | Mobile Access | Operation Type |
|---|---|---|
| `students` | Read own profile | `snapshots()` stream |
| `events` | Read approved events | `snapshots()` stream |
| `events/{eventId}/event_sessions` | Read sessions per event | `snapshots()` stream |
| `attendance` | Read own records; write on QR scan | Stream + write |
| `payables` | Read own payment status | `snapshots()` stream |
| `announcements` | Read all targeted at student/org | `snapshots()` stream |
| `certificates` | Read own issued certificates | `snapshots()` stream |
| `organizations` | Read org info (name, logo) | One-time `get()` |

---

## 2. Collection Schemas (Mobile View)

### 2.1 `students/{studentId}`

**Document ID** = Firebase Auth UID of the student.

```dart
/// Represents a registered student user in the mobile app.
class StudentModel {
  final String id;               // Firebase Auth UID — also the document ID
  final String studentNumber;    // e.g., "2024-00123"
  final String firstName;        // e.g., "Maria"
  final String lastName;         // e.g., "Santos"
  final String displayName;      // Denormalized full name: "Maria Santos"
  final String email;            // School email — matches Firebase Auth email
  final String courseCode;       // e.g., "BSIT"
  final String courseName;       // e.g., "Bachelor of Science in Information Technology"
  final int yearLevel;           // 1–4
  final String sectionName;      // e.g., "BSIT 1101"
  final String departmentCode;   // e.g., "SCS"
  final String? avatarUrl;       // Firebase Storage URL — nullable
  final List<String> organizationIds; // Orgs the student belongs to
  final bool isActive;           // false = account disabled; block login
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

**Firestore path:** `/students/{uid}`
**Mobile read rule:** Student can only read their own document (`uid == auth.currentUser.uid`).
**Realtime:** Yes — use `.snapshots()` for profile screen so changes from admin are reflected live.

**Indexes required (mobile queries):**
- None — always fetched by document ID.

---

### 2.2 `events/{eventId}`

```dart
/// Represents a published/approved event visible to students.
class EventModel {
  final String id;
  final String title;
  final String description;
  final EventType type;          // academic | socio_civic | cultural | sports | other
  final String? organizationId;  // null = SAO-owned event
  final String organizationName; // Denormalized for display
  final EventStatus status;      // Only 'approved' events are shown in mobile
  final String? coverImageUrl;   // Firebase Storage URL

  // ─── Schedule ───
  final DateTime startDate;
  final DateTime endDate;
  final String venue;

  // ─── Payables ───
  final bool studentPayableEnabled;
  final double studentPayableAmount; // Per-student fee in PHP. 0.0 if not enabled.

  // ─── Participants ───
  final List<String> eligibleYearLevels; // e.g., ["1", "2", "3", "4"]

  // ─── Meta ───
  final String academicYear;     // e.g., "2024-2025"
  final String semester;         // "1st" | "2nd" | "summer"
  final DateTime? publishedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
}

enum EventType { academic, socioCivic, cultural, sports, other }
enum EventStatus { draft, pendingApproval, approved, rejected, completed }
```

**Firestore path:** `/events/{eventId}`
**Mobile query:**
```dart
// Only show approved events the student is eligible for
_firestore
  .collection(FirestorePaths.events)
  .where('status', isEqualTo: 'approved')
  .where('eligibleYearLevels', arrayContains: student.yearLevel.toString())
  .orderBy('startDate', descending: false)
  .snapshots()
```

**Indexes required:**
- `status` ASC, `startDate` ASC
- `status` ASC, `eligibleYearLevels` ARRAY, `startDate` ASC

---

### 2.3 `events/{eventId}/event_sessions/{sessionId}`

Sub-collection of each event. Each session is a scannable time slot.

```dart
/// A single scannable session within an event.
class EventSessionModel {
  final String id;
  final String eventId;          // Parent event ID
  final String label;            // e.g., "Day 1 Morning"
  final DateTime date;
  final String startTime;        // "08:00" — 24hr format
  final String endTime;          // "12:00"
  final String venue;

  // ─── Attendance Window ───
  final DateTime attendanceWindowStart; // When QR scanning opens
  final DateTime attendanceWindowEnd;   // When QR scanning closes

  final DateTime createdAt;
  final DateTime updatedAt;
}
```

**Firestore path:** `/events/{eventId}/event_sessions/{sessionId}`
**Mobile query:** Fetch all sessions for a given event.
```dart
_firestore
  .collection(FirestorePaths.events)
  .doc(eventId)
  .collection(FirestorePaths.eventSessions)
  .orderBy('date')
  .snapshots()
```

---

### 2.4 `attendance/{attendanceId}`

```dart
/// A single attendance check-in record for a student at an event session.
class AttendanceModel {
  final String id;
  final String eventId;
  final String sessionId;
  final String studentId;
  final String studentName;      // Denormalized
  final String studentNumber;    // Denormalized
  final String course;           // Denormalized
  final int yearLevel;           // Denormalized
  final String scannedByUid;    // UID of officer who scanned (or 'self' for student QR)
  final ScanMethod scanMethod;   // qr | manual
  final DateTime checkedInAt;
  final DateTime createdAt;
}

enum ScanMethod { qr, manual }
```

**Firestore path:** `/attendance/{attendanceId}`
**Mobile read query** (student's own attendance history):
```dart
_firestore
  .collection(FirestorePaths.attendance)
  .where('studentId', isEqualTo: currentStudentId)
  .orderBy('checkedInAt', descending: true)
  .snapshots()
```

**Mobile write** (QR self-check-in — only if `qrTicketUnlocked == true`):
```dart
await _firestore.collection(FirestorePaths.attendance).add({
  'eventId': eventId,
  'sessionId': sessionId,
  'studentId': student.id,
  'studentName': student.displayName,
  'studentNumber': student.studentNumber,
  'course': student.courseCode,
  'yearLevel': student.yearLevel,
  'scannedByUid': student.id,
  'scanMethod': 'qr',
  'checkedInAt': FieldValue.serverTimestamp(),
  'createdAt': FieldValue.serverTimestamp(),
});
```

**Indexes required:**
- `studentId` ASC, `checkedInAt` DESC
- `eventId` ASC, `sessionId` ASC, `studentId` ASC

---

### 2.5 `payables/{payableId}`

```dart
/// Tracks a student's payment obligation and QR access status for an event.
class PayableModel {
  final String id;
  final String eventId;
  final String studentId;
  final String organizationId;

  // ─── Denormalized student info ───
  final String studentName;
  final String studentNumber;
  final String course;
  final int yearLevel;

  // ─── Payment ───
  final double amountDue;           // In PHP
  final double amountPaid;          // 0.0 until paid
  final PaymentStatus paymentStatus; // unpaid | paid | waived | refunded
  final DateTime? paidAt;
  final PaymentMethod? paymentMethod; // cash | gcash | bank_transfer
  final String? paymentReference;   // Receipt or transaction ID

  // ─── QR Gate Control (CRITICAL) ───
  /// When false: student is BLOCKED from QR check-in.
  /// When true: student may scan in at the gate.
  /// Never allow attendance write when this is false.
  final bool qrTicketUnlocked;

  final DateTime createdAt;
  final DateTime updatedAt;
}

enum PaymentStatus { unpaid, paid, waived, refunded }
enum PaymentMethod { cash, gcash, bankTransfer }
```

**Firestore path:** `/payables/{payableId}`
**Mobile query** (student's own payables):
```dart
_firestore
  .collection(FirestorePaths.payables)
  .where('studentId', isEqualTo: currentStudentId)
  .orderBy('createdAt', descending: true)
  .snapshots()
```

**QR gate check** (must run before writing attendance):
```dart
// In AttendanceRepository — MANDATORY before any attendance write
Future<bool> isStudentAllowedEntry(String eventId, String studentId) async {
  final snap = await _firestore
    .collection(FirestorePaths.payables)
    .where('eventId', isEqualTo: eventId)
    .where('studentId', isEqualTo: studentId)
    .limit(1)
    .get();

  if (snap.docs.isEmpty) return true; // No payable = free event
  return snap.docs.first.data()['qrTicketUnlocked'] == true;
}
```

**Indexes required:**
- `studentId` ASC, `eventId` ASC
- `eventId` ASC, `qrTicketUnlocked` ASC

---

### 2.6 `announcements/{announcementId}`

```dart
/// An announcement published by SAO to students/organizations.
class AnnouncementModel {
  final String id;
  final String title;
  final String body;
  final String authorName;       // Denormalized
  final AnnouncementPriority priority; // normal | urgent
  final dynamic targetAudience;  // 'all' | 'students' | List<String> (orgIds)
  final List<String> attachmentUrls;
  final List<String> readByUids; // List of UIDs who marked as read
  final DateTime publishedAt;
  final DateTime createdAt;
}

enum AnnouncementPriority { normal, urgent }
```

**Firestore path:** `/announcements/{announcementId}`
**Mobile query** (announcements for this student):
```dart
// Query 1: announcements to 'all'
// Query 2: announcements targeting student's org IDs
// Merge client-side (Firestore does not support OR across different fields in one query)
```

**Indexes required:**
- `publishedAt` DESC
- `targetAudience` ASC, `publishedAt` DESC

---

### 2.7 `certificates/{certificateId}`

```dart
/// A certificate issued to a student for an event.
class CertificateModel {
  final String id;
  final String eventId;
  final String eventTitle;       // Denormalized
  final String studentId;
  final String studentName;      // Denormalized
  final String templateId;
  final String issuedByUid;
  final String issuedByName;     // Denormalized
  final String fileUrl;          // Firebase Storage URL — PDF or image
  final DateTime issuedAt;
  final DateTime createdAt;
}
```

**Firestore path:** `/certificates/{certificateId}`
**Mobile query:**
```dart
_firestore
  .collection(FirestorePaths.certificates)
  .where('studentId', isEqualTo: currentStudentId)
  .orderBy('issuedAt', descending: true)
  .snapshots()
```

---

### 2.8 `organizations/{organizationId}`

Mobile app reads org data for display (name, logo). Students do not write to this collection.

```dart
/// Minimal organization model for display purposes.
class OrganizationModel {
  final String id;
  final String name;
  final String acronym;
  final String? logoUrl;         // Firebase Storage URL
  final String status;           // 'active' | 'inactive' | 'suspended'
}
```

**Firestore path:** `/organizations/{organizationId}`
**Access:** One-time `get()` is acceptable here — org info changes rarely.

---

## 3. Firestore Path Constants

Keep all paths in `lib/core/constants/firestore_paths.dart`. Reference below for completeness:

```dart
class FirestorePaths {
  // Top-level collections
  static const String students       = 'students';
  static const String events         = 'events';
  static const String attendance     = 'attendance';
  static const String payables       = 'payables';
  static const String announcements  = 'announcements';
  static const String certificates   = 'certificates';
  static const String organizations  = 'organizations';

  // Sub-collections
  static const String eventSessions  = 'event_sessions'; // under /events/{id}/

  // Admin-only (mobile reads only — no writes)
  static const String sasAdmins      = 'sas_admins';
}
```

---

## 4. Security Rules (Mobile Client Perspective)

The mobile app operates as an authenticated student. The Firestore rules enforced server-side are:

| Collection | Mobile Read | Mobile Write |
|---|---|---|
| `students` | Own document only (`uid == auth.uid`) | None — admin manages |
| `events` | `status == 'approved'` only | None |
| `event_sessions` | Under any approved event | None |
| `attendance` | Own records (`studentId == auth.uid`) | Only when `qrTicketUnlocked == true` |
| `payables` | Own records (`studentId == auth.uid`) | None — admin marks paid |
| `announcements` | Targeted at `'all'`, `'students'`, or own orgIds | `readByUids` field only (arrayUnion) |
| `certificates` | Own records (`studentId == auth.uid`) | None |
| `organizations` | Active orgs only | None |

---

## 5. Timestamp Convention

```dart
// Reading from Firestore
final date = (data['startDate'] as Timestamp).toDate();

// Writing to Firestore
'createdAt': FieldValue.serverTimestamp(),
'updatedAt': FieldValue.serverTimestamp(),

// Displaying
import 'package:intl/intl.dart';
final display = DateFormat('MMM dd, yyyy hh:mm a').format(date);
```

---

## Changelog

<!-- AGENT-UPDATED: 2026-06-16 — Initial mobile schema created from web backend-schema.md -->
