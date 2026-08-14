# Payables & Gate Control System — Defense & Architecture Guide

> **Target Audience:** Capstone Panel Defense & Developer Architecture Reference  
> **Location:** `lib/features/payables/`  
> **Related Files:** `docs/financial-sync-implementation-plan.md`, `docs/features/financial-mobile-sync-guide.md`  
> **Last Updated:** August 2026  

---

## 1. Overview & System Purpose

The **Payables & Gate Control System** handles financial obligations across both **Admin (Campus-Wide/SAO)** and **Student Organizations (Clubs)**:
- **Event Entry Fees** (School-wide vs. Club-specific)
- **Organization Membership Dues**
- **Unexcused Absence & Late Fines**

It dynamically synchronizes payables to new and newly-activated students and controls student gate access via the `qrTicketUnlocked` flag.

---

## 2. Core Workflows & Schema Breakdown

### 2.1 Schema & Document Fields (`/payables/{payableId}`)

```typescript
export type PayableType = 
  | 'membership_due'   // Belongs to Club (organizationId)
  | 'event_fee'        // Belongs to School OR Club (determined by organizationId)
  | 'org_fine'         // Belongs to Club
  | 'admin_fine'       // Belongs to School (organizationId: null)
  | 'custom';

export interface PayableDocument {
  id: string;

  // ─── Who Owes ───
  studentId: string;           // Auth UID
  studentName: string;         // Denormalized student name
  studentSchoolId: string;     // Official 11-digit STI ID

  // ─── What Is Owed ───
  type: PayableType;
  label: string;
  description: string;

  // ─── Context ───
  organizationId: string | null;   // null = Admin/SAO; string = Specific Club
  organizationName: string | null;
  semesterId: string;
  eventId: string | null;

  // ─── Money ───
  assignedAmount: number;
  paidAmount: number;
  status: 'pending' | 'partial' | 'paid' | 'overdue' | 'waived';
  dueDate: Timestamp | null;

  // ─── Gate Control Flag (MANDATORY) ───
  qrTicketUnlocked: boolean;       // true = student event QR ticket unlocked for gate scan
  paidAt: Timestamp | null;
  recordedBy: string | null;
  paymentMethod: string | null;

  // ─── Audit ───
  createdBy: string;
  createdAt: Timestamp;
  updatedAt: Timestamp;
}
```

---

## 3. Confirmed Business & Gate Control Rules

### 3.1 Strict QR Gate Control (Option A)
- **Free Events (`studentPayablesEnabled == false`)**: `qrTicketUnlocked` is implicitly `true`. QR ticket renders immediately.
- **Paid Events (`studentPayablesEnabled == true`)**:
  - `qrTicketUnlocked` is `false` upon creation.
  - **Partial Payments**: If a student pays ₱25 of a ₱50 fee, `qrTicketUnlocked` remains **`false`**.
  - **100% Settlement**: Only when `paidAmount >= assignedAmount` (`status == 'paid'`) or when an Admin/Officer explicitly triggers a manual override toggle does `qrTicketUnlocked` become **`true`**.
- **Locked State Security**: While locked, `QrTicketScreen` displays `LockedQrCard`. The QR code payload is **never generated or rendered on the widget tree**, preventing screenshots or unauthorized scans.

### 3.2 Offline Scanner Enforcement (Option A)
- Scanner devices cache participant data in Drift SQLite `cached_participants` and `cached_payables`.
- During offline gate scanning:
  - If a student is found with `qrTicketUnlocked == true`: Scan accepted $\rightarrow$ Logged to `offline_attendance`.
  - If a student is **missing from the local offline cache**: Scan is **strictly rejected** with *"Payment Verification Required Online"*.

---

## 4. Defense Testing Quick Reference

| Test Case Scenario | Action / Action Trigger | System Behavior / Expected Outcome |
|---|---|---|
| **Late Registration Discovery** | Student registers mid-semester; Admin or Mobile AI sets `ACTIVE` | Mobile payables stream immediately populates all applicable ongoing event fees and dues. |
| **Partial Payment Attempt** | Student pays partial fee at cashier | Remaining balance updates on mobile; **QR ticket remains strictly LOCKED**. |
| **Full Settle at Booth** | Cashier records remaining payment on web portal | Mobile screen receives live Firestore update in <1s; `qrTicketUnlocked` becomes `true`; QR pass unlocks. |
| **Offline Gate Scan** | Scanner device offline; Scans valid unlocked QR pass | Scanner validates Drift `cached_payables` and approves entry. |
| **Offline Missing Student** | Scanner device offline; Scans uncached student | Scanner rejects scan: *"Record Not Found in Offline Cache"*. |
