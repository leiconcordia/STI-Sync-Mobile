# Student QR Ticket System — Defense & Architecture Guide

> **Target Audience:** Capstone Panel Defense & Developer Architecture Reference  
> **Location:** `lib/features/qr_ticket/`  

---

## 1. Overview & System Purpose

The **Student QR Ticket System** generates personal, dynamic QR tickets for students to present at event entry/exit gates. It integrates directly with the payables/financial system to lock QR access if event fees are unpaid, ensuring financial gate control.

---

## 2. Core Workflows & Step-by-Step Validations

### 2.1 Ticket Generation Eligibility Checklist

A student can view and render their QR ticket on `QrTicketScreen` (`/ticket/:eventId`) ONLY when **all 3 conditions** are satisfied:

```
                  [Check Event Config]
                           │
             ┌─────────────┴─────────────┐
             ▼                           ▼
  enableQRTickets == true     attendanceEnabled == true
             │                           │
             └─────────────┬─────────────┘
                           ▼
                 [Check Payables Gate]
                           │
             ┌─────────────┴─────────────┐
             ▼                           ▼
  Payables Disabled/Free       Payables Enabled
  (qrTicketUnlocked = true)    (qrTicketUnlocked = true in /payables)
             │                           │
             └─────────────┬─────────────┘
                           ▼
               [RENDER QR CODE TICKET]
```

1. `event.enableQRTickets == true`
2. `event.attendanceEnabled == true`
3. `qrTicketUnlocked == true` (from `/payables/{payableId}` or event has `studentPayablesEnabled == false`)

---

### 2.2 Locked QR Card State

If `qrTicketUnlocked == false` (e.g. event fee or required payable is unpaid):
- `QrTicketScreen` renders `LockedQrCard` widget instead of the QR code.
- Displays payment instructions: amount due, payment status, and organization contact info.
- **Security Rule:** The QR payload is NOT generated or rendered on the widget tree when locked, preventing screen grabs or memory inspection.

---

### 2.3 QR Payload Structure & Rendering

- **Package:** `qr_flutter`
- **Payload Format (JSON string):**
  ```json
  {
    "eventId": "EVT-10293",
    "studentId": "02000123456",
    "studentAuthUid": "W5r4d6e9q1p8v2m...",
    "generatedAt": 1753705000000
  }
  ```
- **Field Definitions:**
  - `eventId`: Target event document ID.
  - `studentId`: Human-readable 11-digit STI student number.
  - `studentAuthUid`: Firebase Auth UID (primary key for database lookup).
  - `generatedAt`: Client generation timestamp (Unix ms).

---

### 2.4 Offline Ticket Capability

- When the officer downloads event participant data for offline scanning (`OfflineAttendanceRepository.downloadParticipantsForEvent`), the `qrTicketUnlocked` status for each student is cached locally in the Drift `cached_payables` and `cached_participants` SQLite tables.
- Consequently, even if the student or scanner is offline, locked tickets remain locked, and unlocked tickets scan cleanly.

---

## 3. Defense Testing Quick Reference

| Test Case Scenario | Action / Action Trigger | System Behavior / Expected Outcome |
|---|---|---|
| **Free Event QR View** | Student opens QR ticket for event with no fee | Ticket renders immediately with student details and active QR code. |
| **Unpaid Event Fee QR View** | Student opens ticket for event with unpaid fee | Ticket displays `LockedQrCard` showing amount due. QR code is hidden. |
| **Paid Fee Refresh** | Officer marks payable as paid -> Student refreshes | `qrTicketUnlocked` updates to `true`, `LockedQrCard` unlocks and renders QR code. |
| **Offline Locked Ticket** | Turn OFF Wi-Fi -> Open locked ticket | Locked state persists offline using cached Drift payables status. |
