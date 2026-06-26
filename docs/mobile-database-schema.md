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
| `attendance` | Read own records; write on QR scan | Stream + write |
| `payables` | Read own payment status | `snapshots()` stream |
| `announcements` | Read all targeted at student/org | `snapshots()` stream |
| `certificates` | Read own issued certificates | `snapshots()` stream |
| `organizations` | Read org info (name, logo) | One-time `get()` |

---

## 2. Collection Schemas (Mobile View)

### 2.1 `students/{studentId}`

**Document ID** = Firebase Auth UID of the student.

Shared schema with the STI Sync web admin. **Do not rename fields — they must match
the web app's `students` collection exactly.**

| Field | Dart type | Firestore type | Notes |
|---|---|---|---|
| `id` | `String` | string | Firebase Auth UID (= doc id) |
| `authUid` | `String` | string | Same as id — explicit copy |
| `lastName` | `String` | string | Trimmed |
| `firstName` | `String` | string | Trimmed |
| `middleName` | `String` | string | `""` if none |
| `studentId` | `String` | string | Official STI ID, exactly 11 digits |
| `dateOfBirth` | `String` | string | ISO `YYYY-MM-DD` |
| `sex` | `String` | string | `"Male"` or `"Female"` |
| `contactNumber` | `String` | string | 10 digits starting with `9`, no +63 |
| `courseId` | `String` | string | FK → `courses` |
| `courseName` | `String` | string | Denormalized |
| `courseCode` | `String` | string | e.g. `"BSIT"` |
| `departmentId` | `String` | string | FK → `departments` |
| `departmentName` | `String` | string | Denormalized |
| `yearLevel` | `String` | string | `"1st Year"` … `"4th Year"` |
| `section` | `String` | string | e.g. `"BSIT-2A"` |
| `schoolYear` | `String` | string | e.g. `"2026-2027"` |
| `semester` | `String` | string | `"1st Semester"` or `"2nd Semester"` |
| `email` | `String` | string | Lowercased, matches Auth email |
| `profilePhotoUrl` | `String` | string | Cloudinary `secure_url`, `""` if none |
| `schoolIdPhotoUrl` | `String` | string | Cloudinary `secure_url`, `""` if none |
| `status` | `String` | string | `ACTIVE\|PENDING\|RETURNED\|INACTIVE\|SUSPENDED\|ARCHIVED` |
| `registrationSource` | `String` | string | `"SELF_REGISTER"` (app) or `"MANUAL"` (web admin) |
| `addedBy` | `String` | string | `"self"` for self-registration |
| `rejectionReason` | `String?` | string? | Only present when status = `RETURNED` |
| `createdAt` | `DateTime` | Timestamp | `FieldValue.serverTimestamp()` on create |
| `updatedAt` | `DateTime` | Timestamp | `FieldValue.serverTimestamp()` on every write |

**Derived Fields (Not stored in Firestore):**
- `registrationNumber`: Formatted as `REG-{createdAt.year}-{docId.substring(0,4).toUpperCase()}` (e.g. `REG-2026-A3F9`). Used in UI to track pending registrations.

**Self-registration writes** `status: "PENDING"` and `registrationSource: "SELF_REGISTER"`.
The web admin's Pending Verification queue filters `status == "PENDING"`.

**Firestore path:** `/students/{uid}`
**Mobile read rule:** Student can only read their own document (`uid == auth.currentUser.uid`).
**Realtime:** Yes — use `.snapshots()` so admin status changes propagate live.

**Indexes required (mobile queries):**
- None — always fetched by document ID.

---

### 2.2 `events/{eventId}`

```dart
/// Represents a published/approved event visible to students.
class EventModel {
  final String id;
  final String referenceId;
  final String title;
  final String? tagline;
  final String description;
  final List<String> objectives;
  final String? bannerImageUrl;
  final String? thumbnailUrl;

  // ─── Classification ───
  final String eventTypeId;
  final String eventCategoryId;
  final String hostingOrgId;

  // ─── Academic Context ───
  final String semesterId;
  final String schoolYear;

  // ─── Schedule ───
  final List<EventSessionModel> sessions; // Embedded array of sessions
  final String venueId;
  final String eventFormat; // 'On-Campus' | 'Online' | 'Hybrid'

  // ─── Participants ───
  final List<String> targetYearLevels;
  final List<String> targetDepartmentIds;
  final int expectedParticipantCount;

  // ─── Attendance ───
  final bool attendanceEnabled;
  final double? minAttendancePercent;
  final int? lateThresholdMinutes;
  final int? gracePeriodMinutes;
  final double? latePenaltyAmount;

  // ─── Certificates ───
  final bool certificatesEnabled;
  final bool autoIssueCertificates;
  final String? certificateSignatory;

  // ─── Payables ───
  final bool studentPayablesEnabled;
  final double? suggestedFeePerStudent;
  final double? adminFeeOverride;
  final double? totalExpectedCollection;

  // ─── Settings ───
  final bool enableQRTickets;
  final bool mandatoryAttendance;
  final bool lockAfterApproval;
  final String scannerActivationCode;

  // ─── Lifecycle ───
  final String proposalStatus; // draft | approved
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class EventSessionModel {
  final String id;
  final String title;
  final String date;            // ISO YYYY-MM-DD
  final String startTime;       // HH:mm
  final String endTime;         // HH:mm
  final String timeInOpen;
  final String timeInClose;
  final bool hasTimeOut;
  final String? timeOutOpen;
  final String? timeOutClose;
}
```

**Firestore path:** `/events/{eventId}`
**Mobile query:**
```dart
// Only show approved events the student is eligible for
_firestore
  .collection(FirestorePaths.events)
  .where('proposalStatus', isEqualTo: 'approved')
  .where('targetYearLevels', arrayContains: student.yearLevel.toString())
  .orderBy('createdAt', descending: true)
  .snapshots()
```

---

### 2.3 `attendance/{attendanceId}`

```dart
/// A single attendance check-in record for a student at an event session.
class AttendanceModel {
  final String id;
  final String eventId;
  final String sessionId;
  final String studentId;
  final String organizationId;

  final String studentName;      // Denormalized
  final String studentNumber;    // Denormalized
  final String course;           // Denormalized
  final int yearLevel;           // Denormalized
  
  final String scanMethod;       // 'qr' | 'manual'
  final String scannedBy;        // UID of officer who scanned
  final String scannedByName;    // Denormalized scanner name
  final String gateType;         // 'entry' | 'exit'
  
  final DateTime scannedAt;
  final DateTime createdAt;
  final DateTime serverTimestamp;
}
```

**Firestore path:** `/attendance/{attendanceId}`
**Mobile read query** (student's own attendance history):
```dart
_firestore
  .collection(FirestorePaths.attendance)
  .where('studentId', isEqualTo: currentStudentId)
  .orderBy('scannedAt', descending: true)
  .snapshots()
```

**Mobile write** (QR self-check-in — only if `qrTicketUnlocked == true`):
```dart
await _firestore.collection(FirestorePaths.attendance).add({
  'eventId': eventId,
  'sessionId': sessionId,
  'studentId': student.id,
  'organizationId': organizationId,
  'studentName': student.displayName,
  'studentNumber': student.studentNumber,
  'course': student.courseCode,
  'yearLevel': student.yearLevel,
  'scanMethod': 'qr',
  'scannedBy': student.id,
  'scannedByName': student.displayName,
  'gateType': 'entry', // or 'exit'
  'scannedAt': FieldValue.serverTimestamp(),
  'createdAt': FieldValue.serverTimestamp(),
  'serverTimestamp': FieldValue.serverTimestamp(),
});
```

---

### 2.4 `payables/{payableId}`

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
  final String paymentStatus;       // 'unpaid' | 'paid' | 'waived' | 'refunded'
  final DateTime? paidAt;
  final String? paymentMethod;      // 'cash' | 'gcash' | 'bank_transfer'
  final String? paymentReference;   // Receipt or transaction ID
  final String? processedBy;

  // ─── QR Gate Control (CRITICAL) ───
  /// When false: student is BLOCKED from QR check-in.
  /// When true: student may scan in at the gate.
  /// Never allow attendance write when this is false.
  final bool qrTicketUnlocked;

  final List<dynamic> transactions; // Embedded payment transactions

  final DateTime createdAt;
  final DateTime updatedAt;
}
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

---

### 2.5 `announcements/{announcementId}`

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

---

### 2.6 `certificates/{certificateId}`

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

### 2.7 `organizations/{organizationId}`

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
| `events` | `proposalStatus == 'approved'` only | None |
| `attendance` | Own records (`studentId == auth.uid`) | Only when `qrTicketUnlocked == true` |
| `payables` | Own records (`studentId == auth.uid`) | None — admin marks paid |
| `announcements` | Targeted at `'all'`, `'students'`, or own orgIds | `readByUids` field only (arrayUnion) |
| `certificates` | Own records (`studentId == auth.uid`) | None |
| `organizations` | Active orgs only | None |

---

## 5. Timestamp Convention

```dart
// Reading from Firestore
final date = (data['createdAt'] as Timestamp).toDate();

// Writing to Firestore
'createdAt': FieldValue.serverTimestamp(),
'updatedAt': FieldValue.serverTimestamp(),

// Displaying
import 'package:intl/intl.dart';
final display = DateFormat('MMM dd, yyyy hh:mm a').format(date);
```

// AGENT-UPDATED: 2026-06-26 — Added offline_attendance, 
// cached_participants, scanner_sessions collections

### 1.12 `scanner_sessions` (Firestore)

**Path:** `/scanner_sessions/{sessionId}`

> Created when a scanner activates for an event session. 
> Tracks which device/officer is scanning which session.

interface ScannerSessionDocument {
  id: string;
  eventId: string;                    // FK → /events
  sessionId: string;                  // FK → events.sessions[].id
  officerUserId: string;              // FK → Firebase Auth UID
  officerName: string;
  gateType: 'time_in' | 'time_out';
  deviceId: string;                   // unique device identifier
  activatedAt: Timestamp;
  deactivatedAt: Timestamp | null;
  isActive: boolean;
  scanCount: number;                  // denormalized count
  manualCount: number;
  flaggedCount: number;
}

### 1.13 `flagged_attendance` (Firestore)

**Path:** `/flagged_attendance/{flagId}`

> Separate collection for manual/flagged entries. 
> Only scanners with allowManualAttendance can write here.

interface FlaggedAttendanceDocument {
  id: string;
  eventId: string;
  sessionId: string;
  organizationId: string;
  
  // Student info — may be incomplete for unknown walkins
  studentId: string | null;
  studentName: string;
  studentNumber: string | null;
  course: string | null;
  yearLevel: number | null;
  
  // Flag details
  flagReason: 'no_phone' | 'payment_pending' | 
              'not_registered' | 'device_error' | 'other';
  flagNote: string | null;
  gateType: 'time_in' | 'time_out';
  
  // Scanner
  flaggedBy: string;                  // officer userId
  flaggedByName: string;
  
  // Timestamps
  flaggedAt: Timestamp;
  createdAt: Timestamp;
}

### Local SQLite Tables (Drift)

#### `cached_events`
| Column | Type | Notes |
|---|---|---|
| id | TEXT PK | Firestore event ID |
| title | TEXT | |
| eventJson | TEXT | Full JSON of EventDocument |
| cachedAt | INTEGER | Unix ms |
| expiresAt | INTEGER | Unix ms — purge after event ends |

#### `cached_participants`
| Column | Type | Notes |
|---|---|---|
| id | TEXT PK | studentId |
| eventId | TEXT | FK — composite with studentId |
| studentName | TEXT | |
| studentNumber | TEXT | |
| course | TEXT | |
| yearLevel | INTEGER | |
| profilePhotoUrl | TEXT | Cloudinary URL |
| qrTicketUnlocked | INTEGER | 0 or 1 |
| participantJson | TEXT | Full snapshot |
| downloadedAt | INTEGER | Unix ms |

#### `offline_attendance`
| Column | Type | Notes |
|---|---|---|
| localId | TEXT PK | UUID generated offline |
| eventId | TEXT | |
| sessionId | TEXT | |
| studentId | TEXT | |
| studentName | TEXT | |
| gateType | TEXT | 'time_in' / 'time_out' |
| scanMethod | TEXT | 'qr' / 'manual' |
| scannedBy | TEXT | officer userId |
| scannedAt | INTEGER | Unix ms |
| synced | INTEGER | 0 = pending, 1 = uploaded |
| syncedAt | INTEGER | Unix ms or null |
| conflictResolved | INTEGER | 0/1 |

#### `cached_payables`
| Column | Type | Notes |
|---|---|---|
| id | TEXT PK | payableId |
| eventId | TEXT | |
| studentId | TEXT | |
| qrTicketUnlocked | INTEGER | 0 or 1 |
| amountDue | REAL | |
| paymentStatus | TEXT | |
| cachedAt | INTEGER | Unix ms |

#### `scanner_assignments`
| Column | Type | Notes |
|---|---|---|
| eventId | TEXT PK | |
| sessionIds | TEXT | JSON array |
| officerUserId | TEXT | |
| permissions | TEXT | JSON of EventScanner object |
| dataDownloaded | INTEGER | 0/1 |
| downloadedAt | INTEGER | Unix ms |
