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
| `payables` | Read own payment status & event fees | `snapshots()` stream |
| `announcements` | Read all targeted at student/org/department/year level | `snapshots()` stream |
| `issued_certificates` | Read own issued certificates | `snapshots()` stream |
| `organizations` | Read org info & departmental/cross-departmental scope | One-time `get()` / Stream |
| `organization_officers` | Resolve current student's officer record IDs | `snapshots()` stream |
| `organization_members` | Read & write membership join requests | Stream + write |

---

## 2. Collection Schemas (Mobile View)

### 2.1 `students/{studentId}`

**Document ID** = Firebase Auth UID of the student.

Shared schema with the STI Sync web admin. **Do not rename fields — they must match the web app's `students` collection exactly.**

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
  /// Student-facing Event Fee. Copied to payables.assignedAmount & amountDue when enabled.
  final double? adminFeeOverride;
  final double? totalExpectedCollection;

  // Budget (student read-only display)
  final List<BudgetItemModel> budgetItems;
  final double totalApprovedBudget;

  // ─── Settings ───
  final bool enableQRTickets;
  final bool mandatoryAttendance;
  final bool lockAfterApproval;
  final String scannerActivationCode;
  /// Organization-officer document IDs assigned as scanners.
  final List<String> scannerUserIds;

  // ─── Lifecycle ───
  final String proposalStatus; // 'draft' | 'pending_review' | 'approved' | 'rejected' | 'cancelled'
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

class BudgetItemModel {
  final String id;
  final String item;
  final String description;
  final double quantity;
  final double unitCost;
  final double approvedAmount;
  final String status; // approved | reduced | rejected | pending
}
```

**Firestore path:** `/events/{eventId}`  
**Mobile query (student — approved events they are eligible for):**
```dart
// Only show approved events the student is eligible for
_firestore
  .collection(FirestorePaths.events)
  .where('proposalStatus', isEqualTo: 'approved')
  .where('targetYearLevels', arrayContains: student.yearLevel.toString())
  .orderBy('createdAt', descending: true)
  .snapshots()
```

**Mobile query (scanner officer — events where this user is assigned as scanner):**
```dart
_firestore
  .collection(FirestorePaths.events)
  .where('proposalStatus', isEqualTo: 'approved')
  .where('scannerUserIds', arrayContainsAny: targetOfficerIds)
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
  final String scannedBy;        // UID of officer who scanned (or student UID for self check-in)
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

---

### 2.4 `payables/{payableId}`

```dart
/// Tracks a student's payment obligation and QR ticket access control status for an event or org due.
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
  final double amountDue;                 // Assigned fee or remaining balance
  final String status;                    // 'pending' | 'partial' | 'paid' | 'overdue' | 'waived'
  final String paymentStatus;             // Legacy compatibility field ('unpaid' | 'paid' | 'waived' | 'refunded')
  final DateTime? dueDate;

  // ─── QR Ticket Gate Access Control (CRITICAL) ───
  /// Explicit gate control flag set by SAO Admin / Officers.
  /// When false: student is BLOCKED from QR gate check-in and QR ticket overlay is locked.
  /// When true: student may scan in at the gate.
  /// Never allow attendance write when this is false.
  final bool qrTicketUnlocked;

  final DateTime? paidAt;
  final String? recordedBy;               // Officer or SAO Admin UID who recorded payment
  final String? paymentMethod;            // 'cash' | 'gcash' | 'bank_transfer'
  final String? paymentReference;         // Transaction ID or receipt number
  final List<dynamic>? transactions;      // Embedded payment transactions

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
/// An announcement published by SAO or Organization Officers.
class AnnouncementModel {
  final String id;
  final String title;
  final String content;                   // Plain text message content
  final String priority;                  // 'Normal' | 'Important' | 'Urgent'
  final String audience;                  // 'campus-wide' | 'all-organizations' | 'specific' | 'targeted'
  final List<String> targetOrgIds;        // Specific target org IDs
  final List<String> targetOrgNames;      // Denormalized target org names
  final bool pinned;                      // Pinned announcements float to top of feed
  final String semesterId;
  final String schoolYear;
  final String authorName;                // Author display name
  final String authorUid;                 // FK → /sas_admins or /students
  final String? organizationId;          // Authoring Org ID (if officer-authored)
  final String? organizationName;        // Authoring Org Name
  final String? authorRole;              // e.g., "SAO Admin", "IT Guild President"
  final String? linkedEventId;           // Optional FK → /events
  final String? linkedEventTitle;        // Optional Event Title for direct navigation
  final List<String> targetDepartments;  // Target department names or IDs
  final List<String> targetYearLevels;   // Target year levels e.g. ["1st Year", "2nd Year"]
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

**Firestore path:** `/announcements/{announcementId}`  
**Mobile query** (announcements for this student):
```dart
// Stream announcements ordered by createdAt DESC (pinned sorting applied locally in UI)
_firestore
  .collection(FirestorePaths.announcements)
  .orderBy('createdAt', descending: true)
  .snapshots()
```

---

### 2.6 `issued_certificates/{certificateId}`

```dart
/// A certificate issued to a student post-event.
class IssuedCertificateModel {
  final String id;
  final String certificateNumber;       // e.g. "CERT-2026-0001"
  final String templateId;              // FK → /certificate_templates
  final String eventId;                 // FK → /events
  final String eventName;               // Denormalized
  final String studentId;               // FK → /students
  final String studentName;             // Denormalized
  final DateTime issueDate;
  final String? pdfUrl;                 // Exported PDF document URL
  final String? qrCodeUrl;              // Verification QR code URL
  final String organizationId;          // FK → /organizations
}
```

**Firestore path:** `/issued_certificates/{certificateId}`  
**Mobile query:**
```dart
_firestore
  .collection(FirestorePaths.issuedCertificates)
  .where('studentId', isEqualTo: currentStudentId)
  .orderBy('issueDate', descending: true)
  .snapshots()
```

---

### 2.7 `organizations/{organizationId}`

```dart
/// Organization details and departmental eligibility scope.
class OrganizationModel {
  final String id;
  final String name;
  final String acronym;
  final String description;
  final String departmentId;           // FK → /departments or 'cross-departmental'
  final String scope;                  // 'departmental' | 'cross-departmental'
  final List<String>? allowedDepartmentIds; // Target department IDs if scope === 'departmental'
  final List<String>? allowedCourseIds;     // Target course IDs if scope === 'departmental'
  final String academicYear;
  final String semester;
  final String status;                 // 'active' | 'inactive' | 'suspended'
  final int memberCount;
  final String? logoUrl;               // Cloudinary / Storage URL
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

**Firestore path:** `/organizations/{organizationId}`  
**Access:** Read org list for Org Explorer & membership eligibility filtering based on `scope` and `departmentId`.

---

### 2.8 `organization_officers/{officerId}`

```dart
/// Represents an officer assignment for an organization.
class OrganizationOfficerModel {
  final String id;              // Document ID (organization_officers doc ID)
  final String organizationId;  // FK → /organizations
  final String studentId;       // FK → /students (Firebase Auth UID)
  final String position;        // e.g. "President", "Secretary"
  final String status;          // 'active' | 'inactive'
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

**Firestore path:** `/organization_officers/{officerId}`  
**Mobile read query:** Resolves officer record IDs for the logged-in student.

---

### 2.9 `organization_members/{memberId}`

```dart
/// Shared web + mobile schema for organization membership records.
class OrganizationMemberDocument {
  final String id;              // Document ID (member ID)
  final String organizationId;  // FK → /organizations
  final String studentId;       // Official STI Student ID (e.g. "02000108642")
  final String studentAuthUid;  // Firebase Auth UID (doc ID in /students)
  final String studentName;     // Full student name (e.g. "Sophia Bennette")
  final String email;           // Student email
  final String contactNumber;   // Contact phone number
  final String course;          // e.g. "BSIT"
  final String department;      // Department name
  final String year;            // e.g. "2nd Year"
  final String status;          // 'pending' (mobile request) | 'active' (approved) | 'inactive'
  final String paymentStatus;   // 'outstanding' | 'paid'
  final bool isOfficer;         // true if appointed as an officer
  final String addedBy;         // 'self' (mobile app) or admin studentId (web)
  final DateTime dateJoined;    // Timestamp
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

**Firestore path:** `/organization_members/{memberId}`  
**Mobile write (Join Request):**  
`status: 'pending'`, `isOfficer: false`, `paymentStatus: 'outstanding'`, `addedBy: 'self'`, `dateJoined: serverTimestamp()`.

---

## 3. Firestore Path Constants

Keep all paths in `lib/core/constants/firestore_paths.dart`:

```dart
class FirestorePaths {
  // Top-level collections
  static const String students           = 'students';
  static const String events             = 'events';
  static const String attendance         = 'attendance';
  static const String payables           = 'payables';
  static const String announcements      = 'announcements';
  static const String issuedCertificates = 'issued_certificates';
  static const String organizations      = 'organizations';
  static const String organizationOfficers = 'organization_officers';
  static const String organizationMembers = 'organization_members';

  // Admin-only collections
  static const String sasAdmins          = 'sas_admins';
}
```

---

## 4. Security Rules (Mobile Client Perspective)

| Collection | Mobile Read | Mobile Write |
|---|---|---|
| `students` | Own document only (`uid == auth.uid`) | Self-registration (`status == 'PENDING'`) |
| `events` | `proposalStatus == 'approved'` only | None |
| `attendance` | Own records (`studentId == auth.uid`) | Only when `qrTicketUnlocked == true` |
| `payables` | Own records (`studentId == auth.uid`) | None — admin/officer updates status |
| `announcements` | Targeted at `'campus-wide'`, `'all-organizations'`, or student org/dept | None |
| `issued_certificates` | Own records (`studentId == auth.uid`) | None |
| `organizations` | Active orgs | None |
| `organization_members` | Own membership docs (`studentAuthUid == auth.uid`) | Join requests (`status == 'pending'`) |

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

---

## 6. Offline Gate Scanner & SQLite Data Models

### 6.1 `scanner_sessions` (Firestore)

**Path:** `/scanner_sessions/{sessionId}`

Tracks active gate scanner sessions started by officers on their mobile devices.

```typescript
interface ScannerSessionDocument {
  id: string;
  eventId: string;                    // FK → /events
  sessionId: string;                  // FK → events.sessions[].id
  officerUserId: string;              // FK → Firebase Auth UID
  officerName: string;
  gateType: 'time_in' | 'time_out';
  deviceId: string;                   // Unique device identifier
  activatedAt: Timestamp;
  deactivatedAt: Timestamp | null;
  isActive: boolean;
  scanCount: number;                  // Denormalized scan count
  manualCount: number;
  flaggedCount: number;
}
```

### 6.2 `flagged_attendance` (Firestore)

**Path:** `/events/{eventId}/flagged_attendance/{flagId}`

Stores manual or exception gate scans (e.g., student without phone, payment pending walk-ins).

```typescript
interface FlaggedAttendanceDocument {
  id: string;
  eventId: string;
  sessionId: string;
  organizationId: string;
  
  studentId: string | null;
  studentName: string;
  studentNumber: string | null;
  course: string | null;
  yearLevel: number | null;
  
  flagReason: 'no_phone' | 'payment_pending' | 'not_registered' | 'device_error' | 'other';
  flagNote: string | null;
  gateType: 'time_in' | 'time_out';
  
  flaggedBy: string;                  // Officer userId
  flaggedByName: string;
  
  flaggedAt: Timestamp;
  createdAt: Timestamp;
}
```

### 6.3 Local SQLite Tables (Drift)

#### `cached_events`
| Column | Type | Notes |
|---|---|---|
| `id` | TEXT PK | Firestore event ID |
| `title` | TEXT | Event title |
| `eventJson` | TEXT | Full JSON of EventDocument |
| `cachedAt` | INTEGER | Unix ms |
| `expiresAt` | INTEGER | Unix ms — purge after event ends |

#### `cached_participants`
| Column | Type | Notes |
|---|---|---|
| `id` | TEXT PK | studentId |
| `eventId` | TEXT | FK — composite with studentId |
| `studentName` | TEXT | |
| `studentNumber` | TEXT | |
| `course` | TEXT | |
| `yearLevel` | INTEGER | |
| `profilePhotoUrl` | TEXT | Cloudinary URL |
| `qrTicketUnlocked` | INTEGER | 0 or 1 |
| `participantJson` | TEXT | Full snapshot |
| `downloadedAt` | INTEGER | Unix ms |

#### `offline_attendance`
| Column | Type | Notes |
|---|---|---|
| `localId` | TEXT PK | UUID generated offline |
| `eventId` | TEXT | |
| `sessionId` | TEXT | |
| `studentId` | TEXT | |
| `studentName` | TEXT | |
| `gateType` | TEXT | 'time_in' / 'time_out' |
| `scanMethod` | TEXT | 'qr' / 'manual' |
| `scannedBy` | TEXT | Officer userId |
| `scannedAt` | INTEGER | Unix ms |
| `synced` | INTEGER | 0 = pending, 1 = uploaded |
| `syncedAt` | INTEGER | Unix ms or null |
| `conflictResolved` | INTEGER | 0/1 |
| `isFlagged` | INTEGER | 0/1 |
| `flagReason` | TEXT | 'no_phone'\|'payment_pending'\|'not_registered'\|'device_error'\|'other' |
| `flagNote` | TEXT | Optional note |
| `isManual` | INTEGER | 0/1 |

#### `cached_payables`
| Column | Type | Notes |
|---|---|---|
| `id` | TEXT PK | payableId |
| `eventId` | TEXT | |
| `studentId` | TEXT | |
| `qrTicketUnlocked` | INTEGER | 0 or 1 |
| `amountDue` | REAL | |
| `paymentStatus` | TEXT | |
| `cachedAt` | INTEGER | Unix ms |

#### `scanner_assignments`
| Column | Type | Notes |
|---|---|---|
| `eventId` | TEXT PK | Firestore event ID |
| `eventTitle` | TEXT | Denormalized — for offline display |
| `eventFormat` | TEXT | 'On-Campus' \| 'Online' \| 'Hybrid' |
| `sessionIds` | TEXT | JSON array of session ID strings |
| `officerUserId` | TEXT | Firebase Auth UID of the officer |
| `permissions` | TEXT | JSON of EventScanner permission flags |
| `eventEndTime` | INTEGER | Unix ms — last session end |
| `proposalStatus` | TEXT | 'approved' \| 'draft' |
| `dataDownloaded` | INTEGER | 0 or 1 |
| `downloadedAt` | INTEGER | Unix ms or 0 |

// AGENT-UPDATED: 2026-07-11 — Updated scanner_assignments Drift table with eventTitle, eventFormat, eventEndTime, proposalStatus columns (schema v3).

// AGENT-UPDATED: 2026-07-19 — Added isFlagged, flagReason, flagNote, isManual to offline_attendance (schema v8).



