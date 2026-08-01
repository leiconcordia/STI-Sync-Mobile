# Mobile App Compatibility Task List — Web v2 Sync & Schema Alignments

> **Path:** `docs/tasks-mobile-web-compatibility.md`  
> **Target App:** STI Sync Android (Flutter / Dart)  
> **Shared Backend:** Firebase Firestore & Cloud Storage (shared with STI Sync Web v2)  
> **Status:** Pending Mobile Implementation  

---

## Executive Summary & Context

The STI Sync Web application has undergone major updates to support **Event Payables, Gate Access Control (QR Ticket Locks), Denormalized Student Payables, Targeted Announcements with Event Linking, and Organization Departmental Scopes**.

Because both Web and Mobile apps share the same Firebase Firestore backend, the mobile app (Student & Officer views) must be updated to align with these schema additions and business logic rules.

---

## Detailed Task Matrix

| Task ID | Component / Feature | Impact Level | Summary of Required Changes |
| :--- | :--- | :--- | :--- |
| **MOB-PAY-01** | `PayableModel` & Firestore Parsing | **CRITICAL** | Parse `qrTicketUnlocked` (bool), `studentName`, `studentSchoolId`, `assignedAmount`, `paidAmount`, `status` in Dart. |
| **MOB-GATE-01** | Student Event Ticket & QR Overlay | **CRITICAL** | Lock QR code display on student event ticket screen if `qrTicketUnlocked == false` or payment is pending. |
| **MOB-GATE-02** | Officer Gate Scanner Permission Check | **CRITICAL** | Enforce `qrTicketUnlocked == true` during officer QR code attendance scan; block gate entry if locked. |
| **MOB-ANN-01** | `AnnouncementModel` & Feed Scoping | **HIGH** | Support `organizationId`, `linkedEventId`, `linkedEventTitle`, `targetDepartments`, `targetYearLevels`, `authorRole`. |
| **MOB-ANN-02** | Announcement Linked Event Navigation | **MEDIUM** | Render clickable linked event button in announcement cards navigating to `EventDetailScreen`. |
| **MOB-ORG-01** | Organization Scope & Eligibility | **MEDIUM** | Filter departmental vs. cross-departmental clubs in student Org Explorer based on student's `departmentId`. |
| **MOB-ATT-01** | Defensive Attendance Event Title Guard | **LOW** | Prevent null pointer crashes on attendance event title matching using safe String fallbacks. |

---

## 1. Feature Breakdown & Implementation Tasks

### 1.1 Task MOB-PAY-01: Update `PayableModel` & Firestore Deserializer

#### Context
Web v2 denormalizes student identity directly into `/payables/{payableId}` and adds an explicit gate control flag: `qrTicketUnlocked`.

#### Schema Updates (`/payables/{payableId}`)
```dart
class PayableModel {
  final String id;
  final String studentId;
  final String studentName;        // e.g. "Lei Concordia"
  final String studentSchoolId;    // Official 11-digit STI ID e.g. "02000123456"
  final String? organizationId;
  final String? eventId;
  final String type;               // 'event_fee', 'membership_due', 'org_fine', etc.
  final String label;              // e.g. "Event Fee — IT Week 2026"
  final double assignedAmount;
  final double paidAmount;
  final String status;             // 'pending', 'partial', 'paid', 'waived'
  final bool qrTicketUnlocked;     // TRUE = Gate QR Code unlocked for scanning
  final DateTime? dueDate;
  final DateTime? paidAt;
  final String? paymentMethod;

  PayableModel.fromFirestore(Map<String, dynamic> data, String id)
    : id = id,
      studentId = data['studentId'] ?? '',
      studentName = data['studentName'] ?? data['name'] ?? 'Student',
      studentSchoolId = data['studentSchoolId'] ?? data['schoolId'] ?? '',
      organizationId = data['organizationId'],
      eventId = data['eventId'],
      type = data['type'] ?? 'event_fee',
      label = data['label'] ?? data['title'] ?? '',
      assignedAmount = (data['assignedAmount'] ?? data['amount'] ?? 0).toDouble(),
      paidAmount = (data['paidAmount'] ?? data['amountPaid'] ?? 0).toDouble(),
      status = data['status'] ?? 'pending',
      qrTicketUnlocked = data['qrTicketUnlocked'] ?? false,
      dueDate = (data['dueDate'] as Timestamp?)?.toDate(),
      paidAt = (data['paidAt'] as Timestamp?)?.toDate(),
      paymentMethod = data['paymentMethod'];
}
```

---

### 1.2 Task MOB-GATE-01: Student Event Ticket Screen & QR Code Lock Overlay

#### Context
When an event requires payment (`studentPayablesEnabled == true` & fee > 0), the student's QR code ticket must remain **LOCKED** until `qrTicketUnlocked == true` (updated by SAO Admin / Officer upon payment or override).

#### Requirements
1. Query `/payables` where `studentId == currentStudentUid` and `eventId == currentEventId`.
2. Check `payable.qrTicketUnlocked`:
   - **If `qrTicketUnlocked == true` OR event is free**: Render student's QR code for gate entry.
   - **If `qrTicketUnlocked == false`**: Display a locked overlay on top of the QR code canvas:
     - Icon: `Icons.lock_rounded` (Amber / Red badge)
     - Message: *"🔒 QR Ticket Locked — Payment Pending"*
     - Subtitle: *"Please pay your event fee at the SAO office or Cashier to unlock your gate scan ticket."*

---

### 1.3 Task MOB-GATE-02: Officer Gate Scanner Access Control Verification

#### Context
When an officer scans a student's event QR code at gate check-in, the mobile scanner must verify payment / QR access status before recording attendance.

#### Scan Verification Workflow
```dart
Future<ScanResult> processGateScan(String scannedStudentUid, String eventId) async {
  // 1. Fetch event payables for scanned student
  final payablesQuery = await FirebaseFirestore.instance
      .collection('payables')
      .where('eventId', isEqualTo: eventId)
      .where('studentId', isEqualTo: scannedStudentUid)
      .get();

  if (payablesQuery.docs.isNotEmpty) {
    final payableData = payablesQuery.docs.first.data();
    final bool qrTicketUnlocked = payableData['qrTicketUnlocked'] ?? false;
    final String status = payableData['status'] ?? 'pending';

    // 2. Gate Lock Enforcement
    if (!qrTicketUnlocked && status != 'paid' && status != 'waived') {
      return ScanResult.denied(
        reason: "GATE ACCESS DENIED\nUnpaid Event Fee / QR Code Locked",
        studentName: payableData['studentName'] ?? 'Student',
      );
    }
  }

  // 3. Proceed with standard attendance logging...
  return recordAttendance(scannedStudentUid, eventId);
}
```

---

### 1.4 Task MOB-ANN-01 & MOB-ANN-02: Targeted Announcements & Linked Event Navigation

#### Context
Web v2 supports org-authored announcements, department/year level targeting, and direct linking to approved events.

#### Schema Additions (`/announcements/{announcementId}`)
```dart
class AnnouncementModel {
  final String id;
  final String title;
  final String content;
  final String priority;              // 'Normal', 'Important', 'Urgent'
  final String audience;              // 'campus-wide', 'all-organizations', 'targeted'
  final String? organizationId;       // Authoring Org ID
  final String? organizationName;     // Authoring Org Name
  final String? authorRole;           // e.g. "SAO Admin", "IT Guild President"
  final String? linkedEventId;        // Optional FK → /events
  final String? linkedEventTitle;     // Optional Event Title
  final List<String> targetDepartments; // e.g. ["IT Department"]
  final List<String> targetYearLevels;  // e.g. ["3rd Year", "4th Year"]
}
```

#### UI Enhancements in Mobile Announcement Feed
1. **Targeting Filter**: Stream announcements where `audience == 'campus-wide'` OR `targetDepartments.contains(student.departmentId)` OR `targetYearLevels.contains(student.yearLevel)`.
2. **Linked Event Button**: If `linkedEventId != null`, display a card action button:
   - Button: `📅 View Linked Event: ${linkedEventTitle}`
   - Action: Navigates directly to `EventDetailScreen(eventId: linkedEventId)`.

---

### 1.5 Task MOB-ORG-01: Departmental vs. Cross-Departmental Organization Scopes

#### Context
Organizations in Web v2 carry `scope: 'departmental' | 'cross-departmental'`.

#### Mobile Behavior
1. **Departmental Clubs (e.g. IT GUILD)**: Display badge: `🏢 IT Department Only`. Only allow join requests if student's `departmentId` matches `allowedDepartmentIds` or org's `departmentId`.
2. **Cross-Departmental Clubs (e.g. Red Cross Youth - RCY)**: Display badge: `🌐 Open to All Departments`. Allow join requests from any student regardless of course/department.

---

## Verification & Alignment Checklist

- [x] `PayableModel` parses `qrTicketUnlocked` correctly from Firestore.
- [x] Student event details screen blocks QR code rendering when `qrTicketUnlocked == false`.
- [x] Officer scanner app rejects gate check-in attempts for locked QR codes with clear error messages.
- [x] Mobile announcement stream parses `linkedEventId` and navigates to the target event.
- [x] Departmental organization badges render in Student Organization Explorer.
