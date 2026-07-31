# Payables & Gate Control System — Defense & Architecture Guide

> **Target Audience:** Capstone Panel Defense & Developer Architecture Reference  
> **Location:** `lib/features/payables/`  

---

## 1. Overview & System Purpose

The **Payables & Gate Control System** handles financial obligations (event entry fees, organization membership dues, and unexcused absence fines) and controls student gate access via the `qrTicketUnlocked` flag.

---

## 2. Core Workflows & Schema Breakdown

### 2.1 Schema & Document Fields (`/payables/{payableId}`)

```typescript
interface PayableDocument {
  id: string;
  eventId: string;
  studentId: string;
  organizationId: string;
  
  // Student Info
  studentName: string;
  studentNumber: string;
  course: string;
  yearLevel: number;
  
  // Financial Status
  amountDue: number;
  amountPaid: number;
  paymentStatus: 'unpaid' | 'paid' | 'waived' | 'refunded';
  paidAt: Timestamp | null;
  paymentMethod: string | null;
  
  // Gate Control Flag (MANDATORY)
  qrTicketUnlocked: boolean;
}
```

---

### 2.2 Gate Control Integration (`isStudentAllowedEntry`)

Before any QR check-in or manual scan entry is allowed, the system verifies `qrTicketUnlocked`:

```
           [SCAN ATTEMPT]
                 │
                 ▼
       [Query Payable Record]
                 │
      ┌──────────┴──────────┐
      ▼                     ▼
qrTicketUnlocked == true   qrTicketUnlocked == false
      │                     │
      ▼                     ▼
[ALLOW SCAN & CHECK-IN]    [REJECT: "Payment Required"]
```

- If `event.studentPayablesEnabled == false` (Free event): `qrTicketUnlocked` is implicitly `true` for all eligible students.
- If `event.studentPayablesEnabled == true` (Paid event): `qrTicketUnlocked` is `false` until payment status becomes `'paid'` or `'waived'`.
- `events.adminFeeOverride` is the Event Fee shown to students and is copied into `payables.amountDue` when the payable is created. It must never be labelled “Admin Fee” in student UI.
- `suggestedFeePerStudent` and `totalExpectedCollection` are planning fields and are not shown to students.

---

## 3. Defense Testing Quick Reference

| Test Case Scenario | Action / Action Trigger | System Behavior / Expected Outcome |
|---|---|---|
| **Unpaid Gate Attempt** | Scan student ticket with `paymentStatus == 'unpaid'` | Gate rejects scan with `paymentRequired` overlay. |
| **Mark Paid at Booth** | Cashier marks payable paid in web portal -> Re-scan | `qrTicketUnlocked` becomes `true`, gate immediately accepts scan. |
| **Offline Payables Check** | Scan while offline using downloaded SQLite data | Evaluates `cached_payables.qrTicketUnlocked` stored during data download. |
