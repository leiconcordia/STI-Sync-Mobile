# Mobile Payables & Dynamic Financial Synchronization Guide

> **Target Audience:** Android/Flutter Mobile Developers & Capstone Defense Panel  
> **Location:** `C:\Users\Lei_Concordia\AndroidStudioProjects\STI_Sync\docs\features\`  
> **Related Web Guide:** `docs/financial-system-guide.md`  
> **Implementation Plan:** `docs/financial-sync-implementation-plan.md`  
> **Last Updated:** August 2026  

---

## 1. Overview

This document explains how the **STI Sync Mobile Application** interacts with the financial subsystem, synchronizes real-time student payables, handles dynamic late-registration/active-status payable loading, and enforces gate access control via QR ticket unlocking.

---

## 2. Core Mobile Financial Workflows

### 2.1 Dynamic Payables Discovery for New & Active Students

When a student registers or their account is transitioned to `ACTIVE` by an administrator:
1. The Web backend dynamically evaluates all active semester events matching the student's department, year level, and club memberships.
2. Missing payable documents are created under `/payables` with `status: 'pending'` and `qrTicketUnlocked: false`.
3. The mobile app's real-time Firestore stream (`/payables where studentId == currentUserId`) receives the new documents immediately.
4. An **in-app badge counter** increments on the Payables navigation bar tab, and the **Payables Screen** updates in real-time to show:
   - **Campus-wide / SAO Event Fees** (Blue Badge)
   - **Organization / Club Event Fees** (Purple Badge)
   - **Organization Membership Dues**
   - **Violation Fines** (Absent, Late, Missed Scan)

### 2.2 Schema Reference for Mobile Payables

```dart
class PayableModel {
  final String id;
  final String studentId;
  final String studentName;
  final String studentSchoolId;
  final PayableType type; // eventFee, membershipDue, orgFine, adminFine, custom
  final String label;
  final String description;
  final String? organizationId;   // null for Admin/SAO, string for Club
  final String? organizationName;
  final String semesterId;
  final String? eventId;
  final double assignedAmount;
  final double paidAmount;
  final PayableStatus status;     // pending, partial, paid, overdue, waived
  final DateTime? dueDate;
  final DateTime? paidAt;
  final String? paymentMethod;
  final bool qrTicketUnlocked;    // Strict gate pass unlock flag

  PayableModel({
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
    this.paymentMethod,
    required this.qrTicketUnlocked,
  });

  double get remainingBalance => (assignedAmount - paidAmount).clamp(0.0, double.infinity);
  bool get isPaid => status == PayableStatus.paid || remainingBalance <= 0;
  bool get isOverdue => dueDate != null && DateTime.now().isAfter(dueDate!) && !isPaid;
  bool get isCampusWide => organizationId == null || organizationId!.isEmpty;
}
```

---

## 3. QR Ticket & Gate Access Control

```
                 [Student Opens Event in Mobile]
                               │
                               ▼
                   [Check Event Fee Requirement]
                               │
               ┌───────────────┴───────────────┐
               ▼                               ▼
       [Free Event]                      [Paid Event]
  (studentPayablesEnabled: false)   (studentPayablesEnabled: true)
               │                               │
               ▼                               ▼
     [QR Ticket Displayed]             [Check Payable Stream]
     (Status: "Active Gate Pass")      (qrTicketUnlocked flag)
                                               │
                               ┌───────────────┴───────────────┐
                               ▼                               ▼
                     qrTicketUnlocked == true       qrTicketUnlocked == false
                               │                               │
                               ▼                               ▼
                      [Show Active QR Pass]           [Show Strict Lock Overlay]
                      ("Gate Ready")                  ("Payment Required: 100% Settle")
```

### 3.1 Strict Enforcement Policies
1. **Partial Payments**: Partial payment does **not** unlock the QR code. The QR ticket remains locked until full settlement (`paidAmount >= assignedAmount`) or explicit admin override.
2. **Offline Scanner Fallback**: If an officer scanner device is offline and a student's payable is missing from the local Drift SQLite cache, gate check-in is **strictly rejected** with *"Payment Verification Required Online"*.

---

## 4. Defense & Verification Scenarios

| Scenario | Mobile Action / State | Expected Result |
|---|---|---|
| **Late Registration** | Student registers mid-semester; Admin marks `ACTIVE` | On opening the app, pending payables for all ongoing eligible events immediately appear on the dashboard + badge counter increments. |
| **New Club Member** | Student joins a club in the portal | Membership Due payable appears in the student's Payables list. |
| **Partial Payment** | Student pays ₱25 of ₱50 | Remaining balance shows ₱25; **QR ticket remains strictly LOCKED**. |
| **Payment Recorded at Booth** | Cashier records remaining payment on web portal | Mobile screen receives live update; remaining balance drops to ₱0; QR Ticket unlocks immediately. |
| **Gate Check-in with Unpaid Fee** | Scanner scans locked ticket | Scanner rejects check-in with "Payment Required" warning. |
| **Offline Gate Check with Missing Record** | Offline scanner scans uncached student | Scanner strictly rejects scan: *"Record Not Found in Offline Cache"*. |
