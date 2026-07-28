# Scanner & Offline Attendance System — Defense & Architecture Guide

> **Target Audience:** Capstone Panel Defense & Developer Architecture Reference  
> **Location:** `lib/features/scanner/` and `lib/features/sync/`  

---

## 1. Overview & System Purpose

The **Scanner & Offline Attendance System** allows authorized scanner officers to conduct event attendance check-ins using QR code scanning or manual entry, even without an active internet connection. All scans are validated locally against an offline SQLite database (Drift) and automatically synced to Firebase Firestore when connectivity is restored.

---

## 2. Core Workflows & Step-by-Step Validations

### 2.1 QR Code Scanning Validations (`ScannerCameraScreen`)

When a QR code is scanned via the camera, the app executes **4 mandatory validations** in strict sequential order before recording attendance:

```
[QR Code Scanned]
        │
        ▼
1. Format & Payload Check ──► (Invalid format?) ──► [SHOW INVALID OVERLAY]
        │
        ▼
2. Event Match Check ───────► (Wrong eventId?) ──► [SHOW WRONG EVENT OVERLAY]
        │
        ▼
3. Participant Check ───────► (Not in Drift?) ────► [SHOW NOT REGISTERED OVERLAY]
        │
        ▼
4. Payment Gate Check ──────► (Payable locked?) ──► [SHOW PAYMENT REQUIRED OVERLAY]
        │
        ▼
5. Duplicate Check ─────────► (Already scanned?) ─► [SHOW DUPLICATE OVERLAY]
        │
        ▼
[SAVE LOCAL RECORD TO DRIFT] ──► [SHOW SUCCESS OVERLAY]
```

#### Detailed Validation Rules:
1. **Payload Structure Validation:**
   - QR Payload JSON: `{ eventId, studentId, studentAuthUid, generatedAt }`.
   - If JSON decoding fails or `studentAuthUid` / `eventId` is missing -> **Result:** `ScanResultType.invalidFormat` ("Invalid QR Code format").
2. **Event Match Validation:**
   - Evaluates `qrEventId == activeEventId`.
   - If mismatched -> **Result:** `ScanResultType.wrongEvent` ("Wrong Event QR Code"). Prevents cross-event ticket scanning.
3. **Participant Eligibility Validation:**
   - Searches local Drift `cached_participants` by `studentAuthUid` for `eventId`.
   - If student is not found -> **Result:** `ScanResultType.notRegistered` ("Student Not Eligible / Not Registered").
4. **Payment Gate (Payables) Validation:**
   - Checks `cached_payables` or `participant.qrTicketUnlocked`.
   - If `qrTicketUnlocked == false` -> **Result:** `ScanResultType.paymentRequired` ("Payment Required / QR Locked").
5. **Duplicate Check Validation:**
   - Queries `offline_attendance` where `studentId == studentAuthUid`, `sessionId == currentSessionId`, and `gateType == selectedGateType` (`Time-In` or `Time-Out`).
   - If record exists -> **Result:** `ScanResultType.duplicate` ("Already scanned for [Time-In/Time-Out] at [Time]").

---

### 2.2 Late Calculation & Grace Period Rule

- **Formula:** `lateThreshold = sessionTimeInOpen.add(Duration(minutes: gracePeriodMinutes))`
- **Time Source:** Evaluated against `timeInOpen` (or `startTime`) in the active session map.
- **Grace Period Source:** `assignment.gracePeriodMinutes` (default `0`).
- **Evaluation:**
  - `scanTime <= lateThreshold` -> Status: **`Present`**
  - `scanTime > lateThreshold` -> Status: **`Late`**
- **Defense Test Example:**
  - Session `timeInOpen` = 7:00 AM, `gracePeriodMinutes` = 30 mins.
  - Scan at 7:30:00 AM -> **`Present`**
  - Scan at 7:30:01 AM (7:31 AM) -> **`Late`**

---

### 2.3 Manual & Flagged Attendance Workflow (`ManualAttendanceScreen`)

- **Role Enforcement:** Accessible ONLY if scanner permission `allowManualAttendance == true`.
- **Add Unknown Attendee Button:** Displayed **directly below the search bar** at all times (no search required). Officers can immediately tap to add a walk-in attendee.
- **Search Capabilities:** Officer searches local Drift `cached_participants` by student name or student number (works 100% offline).
- **Gate Type Enforcement:** The `Time-Out` gate chip is only visible when the active session has `hasTimeOut == true`. Events with Time-In only will not show the Time-Out option.
- **Flagged Entry Handling:**
  - If a student cannot present a QR code or has issues, officer select a `flagReason`:
    - `'no_phone'` | `'payment_pending'` | `'not_registered'` | `'device_error'` | `'other'`
  - Adds optional `flagNote`.
  - Sets `isFlagged = 1` and `isManual = 1`.
- **Routing:** Flagged entries are synced to the separate Firestore subcollection: `/events/{eventId}/flagged_attendance/{docId}` for administrative review.

---

### 2.4 Unsynced Attendance Logs (`ScannerLogsScreen`) & Strict Manual Sync Policy

- **Manual Sync Only (No Auto-Sync):** Connectivity transitions (offline -> online) or scanning while connected to Wi-Fi will NEVER automatically upload records to Firestore. Cloud syncing ONLY occurs when the officer manually taps the **Sync** button in `ScannerLogsScreen`.
- **Data Filter:** Displays **ONLY pending offline records (`synced == 0`)**.
- **Auto Clearance:** As soon as records are uploaded to Firestore, they automatically disappear from Unsynced Attendance Logs.
- **Hold-to-Delete (Long Press):**
  - Officers can long press any unsynced record to open the *"Delete Unsynced Entry?"* dialog.
  - Deletes the entry from local SQLite (`offline_attendance`) via `attendanceDao.deleteRecordByLocalId(localId)`.

---

### 2.5 Scanner Mode Screen Attendance List (`ScannerModeScreen`)

- **Multi-Session Support & Session Filtering:**
  - The horizontal session selector allows officers to switch between event sessions (e.g. Session 1, Session 2).
  - Tapping a session updates `_selectedSessionId` and dynamically filters the summary stats (`In`, `Out`, `Absent`, `Flagged`) and student attendance list to show records **for that session only**.
  - A student checked in for Session 1 will correctly show as `Absent` (Not Scanned) for Session 2 until scanned for Session 2.
- **Session-Scoped Duplicate Detection:**
  - Duplicate validation (`AttendanceDao.checkDuplicate`) is scoped to `eventId` + `sessionId` + `gateType`.
  - Scanning a student in Session 1 will NOT block that student from scanning in Session 2. Scanning twice for the *same* session and gate type triggers an instant **Duplicate Scan** overlay.
- **Manual Refresh Action & Remote Subcollection Sync:**
  - Contains a Refresh icon button in the header and supports `RefreshIndicator` over the list.
  - **Delete-then-refetch strategy:** First deletes all previously-synced local records (`synced=1`) for the event, then re-fetches both `/events/{eventId}/attendance` AND `/events/{eventId}/flagged_attendance` from Firestore and caches them into Drift SQLite (`synced = 1`). This ensures records deleted from Firestore are properly removed locally on refresh.
- **Attendance List Visibility Rules:**
  - Normal QR scans (`isFlagged=0`) appear immediately in the list regardless of sync status.
  - Flagged/manual entries (`isFlagged=1`) only appear **after sync** (`synced=1`). Locally-created flagged records won't show until uploaded to Firestore.
- **Collapsible Summary Dropdown:** The Attendance Summary stats cards (`In`, `Out`, `Absent`, `Flagged`) are hidden/collapsed by default behind an "Attendance Summary" toggle header with arrow icon (`Icons.keyboard_arrow_down`). Tapping expands/collapses the summary.
- **Real-time Search & Filtering:**
  - Search input filters students dynamically by `studentName` and `studentNumber` with clear query button.
  - Filter chips (`All`, `Checked In`, `Checked Out`, `Absent`, `Flagged`) filter student cards cleanly without bottom keyboard layout overflow (`resizeToAvoidBottomInset: false`).
- **De-duplication & Walk-in Integration:**
  - Combines `cached_participants` with manual walk-in attendees from `offline_attendance` so non-registered walk-ins are never lost after syncing.
  - Students with flagged records render a **Flagged** status badge on their card.
- **Default Status:** Downloaded participants default to **`Absent`** (`Not Scanned`).
- **Dynamic Status Updates:**
  - No scan record -> **`Absent`** (Grey)
  - Time-In record -> **`Present`** (Green) or **`Late`** (Orange)
  - Time-Out record -> **`Checked Out`** (Blue)
- **Realtime Firebase & Local Deletion:**
  - Tapping a participant's attendance card opens the details modal.
  - Tapping **"Delete Record"** calls `OfflineAttendanceRepository.deleteAttendanceRecord()`, deleting the record from **Firebase Firestore** (`/events/{eventId}/attendance` & `/events/{eventId}/flagged_attendance`) AND purging the local SQLite row.

---

### 2.6 Sync Engine (`SyncService`)

- **Auto Sync Trigger:** Listens to `connectivity_plus` stream. When network transitions `offline -> online`, automatically triggers `uploadPendingAttendance()`.
- **Duplicate Prevention:** Queries Firestore `/events/{eventId}/attendance` for existing records matching `(studentId, sessionId, gateType)` before writing.
- **Conflict Handling (`SyncConflictsScreen`):**
  - If duplicates are detected, surfaces a conflict review UI with local vs remote timestamps.
  - Options: **`Skip`** (keep Firestore version, mark local synced) or **`Force Upload`** (overwrite Firestore doc).

---

## 3. Defense Testing Quick Reference

| Test Case Scenario | Action / Action Trigger | System Behavior / Expected Outcome |
|---|---|---|
| **Airplane Mode Scan** | Scan valid student QR in Airplane Mode | Scans successfully, stores in SQLite, status updates in Scanner Mode to Present/Late, adds 1 pending entry to Attendance Logs. |
| **Restore Wi-Fi/Cellular** | Turn Wi-Fi back ON | `SyncService` auto-triggers, uploads pending scans to Firestore subcollections, clears entries from Attendance Logs. |
| **Mismatched Event Ticket** | Scan Event B ticket while scanning Event A | Rejects scan instantly with `wrongEvent` overlay detailing expected vs scanned Event ID. |
| **Locked Payment Scan** | Scan ticket of student with unpaid payables | Rejects scan with `paymentRequired` overlay. |
| **Grace Period Threshold** | Scan 31 minutes after session start (30m grace) | System marks attendance status as `'Late'` instead of `'Present'`. |
| **Delete from Scanner List** | Tap participant -> "Delete Record" | Deletes attendance document from Firestore cloud AND local database. Status resets to Absent. |
| **Hold-to-Delete Unsynced** | Long press record in Attendance Logs | Opens confirmation dialog -> Deletes local SQLite record before sync occurs. |
