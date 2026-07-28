# Events & Participant Eligibility System — Defense & Architecture Guide

> **Target Audience:** Capstone Panel Defense & Developer Architecture Reference  
> **Location:** `lib/features/events/` and `lib/features/scanner/`  

---

## 1. Overview & System Purpose

The **Events & Participant Eligibility System** manages event discovery, session scheduling, role-based scanner assignments, and department/year-level participant targeting.

---

## 2. Core Workflows & Step-by-Step Validations

### 2.1 Student Event Eligibility Filter Rules

For a student to see an event on their feed or participate:
1. **Proposal Status Check:** `proposalStatus == 'approved'`. Draft or pending events are hidden.
2. **Department Filter:** `student.departmentId` MUST be included in `event.targetDepartmentIds`.
3. **Year Level Filter:** `student.yearLevel` (e.g. `'1'`, `'2'`, `'3'`, `'4'`) MUST be included in `event.targetYearLevels`.

```dart
// Mobile Eligibility Query logic
final isEligible = event.proposalStatus == 'approved' &&
    event.targetDepartmentIds.contains(student.departmentId) &&
    event.targetYearLevels.contains(student.yearLevel.toString());
```

---

### 2.2 Scanner Role Assignment & Permissions

Scanner assignments are stored in the Firestore `events` collection inside a `scanners[]` array and denormalized into `scannerUserIds[]`.

#### Permissions Breakdown (`ScannerAssignmentModel.permissions`):
- `canCheckIn` (`bool`): Enables Time-In scan mode. If `false`, Time-In is disabled.
- `canCheckOut` (`bool`): Enables Time-Out scan mode. If `false`, Time-Out is disabled.
- `allowManualAttendance` (`bool`): Controls visibility of the `Add Person` FAB and `/scanner/:eventId/manual` screen.
- `canViewList` (`bool`): Enables participant attendance list viewing.
- `canEditRecords` (`bool`): Allows record modification/deletion.

---

### 2.3 Automatic Expiration & Local Data Cleanup (`EventCleanupService`)

- **Expiration Condition:** An event is considered ended when `DateTime.now()` is after `eventEndTime + 12 hours`.
- **Periodic Cleanup Task:** `EventCleanupService` runs every 30 minutes in the background while the app is foregrounded.
- **Cleanup Actions (`purgeEventData`):**
  1. Purges cached participant rows in Drift `cached_participants`.
  2. Purges cached payables in Drift `cached_payables`.
  3. Purges **synced** attendance records in Drift `offline_attendance` (`synced == 1`).
  4. Removes assignment row from `scanner_assignments`.
- **Purpose:** Keeps local SQLite database lean and protects student privacy after event completion.

---

## 3. Defense Testing Quick Reference

| Test Case Scenario | Action / Action Trigger | System Behavior / Expected Outcome |
|---|---|---|
| **Department Mismatch** | BSIT student views Event targeted ONLY at BSBA | Event does NOT appear in student's event feed. |
| **Scanner Manual Permission OFF** | Officer with `allowManualAttendance: false` logs in | `Add Person` FAB is hidden. Route `/manual` is blocked. |
| **Event Concluded Cleanup** | 12 hours pass after event last session end | `EventCleanupService` automatically purges local cached participant data. |
