# STI Sync Mobile — Semester Rollover & Student In-App Re-enrollment Plan

## 1. Overview & Architecture
This document details the mobile (Android) architecture for handling academic semester transitions, active semester synchronization, and student in-app re-enrollment in the **STI Sync Mobile App**.

---

## 2. Active Semester Sync in Mobile

### Firestore Data Model
- Active Semester Document: `/semesters/{semesterId}` where `status == "ACTIVE"`.
- Student Profile Document: `/students/{studentDocId}` or `/users/{uid}`:
  - `schoolYear`: e.g. `"2026-2027"`
  - `semester`: e.g. `"1st Semester"` | `"2nd Semester"`
  - `status`: `"ACTIVE"` | `"PENDING_REENROLLMENT"` | `"INACTIVE"` | `"SUSPENDED"`
  - `yearLevel`: `1` | `2` | `3` | `4`
  - `section`: e.g. `"BSIT 2101"`
  - `courseCode`: e.g. `"BSIT"`

### App Startup / Auth Check
When a student logs in or opens the app:
1. Listen to active semester stream:
   `FirebaseFirestore.getInstance().collection("semesters").whereEqualTo("status", "ACTIVE").limit(1)`
2. Compare active semester with student's profile:
   - If `student.schoolYear != activeSemester.academicYear || student.semester != activeSemester.semester`:
     - Student needs to re-enroll for the newly active semester.
     - Student profile status is treated as `PENDING_REENROLLMENT`.

---

## 3. Student In-App Re-enrollment Flow

### User Experience (Mobile UI)
When the student is detected in `PENDING_REENROLLMENT`:
1. **Welcome Banner / BottomSheet Dialog**:
   - Title: *"Welcome to [activeSemester.semester] (A.Y. [activeSemester.academicYear])!"*
   - Subtitle: *"Please confirm your enrollment and section for this semester before [formatDate(activeSemester.reenrollDeadline)]."*
2. **Form / Confirmation Screen**:
   - **Academic Year & Term**: Auto-populated and locked (e.g. `2026-2027 · 2nd Semester`).
   - **Year Level**: Dropdown or auto-incremented (e.g. 1st Year, 2nd Year).
   - **Course & Section**: Dropdown populated from `/sections` matching the student's department/course.
   - **Confirmation Checkbox**: *"I confirm that I am officially enrolled for this semester."*
3. **Submit Action ("Confirm Re-enrollment")**:
   - Updates student Firestore document:
     ```kotlin
     val updates = mapOf(
         "schoolYear" to activeSemester.academicYear,
         "semester" to activeSemester.semester,
         "yearLevel" to selectedYearLevel,
         "section" to selectedSection,
         "status" to "ACTIVE",
         "updatedAt" to FieldValue.serverTimestamp()
     )
     db.collection("students").document(studentId).update(updates)
     ```
   - Shows celebratory toast / confetti: *"Re-enrollment Confirmed! You have full access to events and QR tickets for this semester."*

---

## 4. Mobile Event & QR Ticket Gate Lock During Pending Re-enrollment

### Access Rules
- If student is in `PENDING_REENROLLMENT`:
  - **Browsing Events Feed**: Allowed (student can see upcoming campus events).
  - **Claiming QR Tickets / Attendance**: Locked with a message:
    > *"Please complete your semester re-enrollment confirmation to unlock your event QR tickets."*
  - **Financial Ledger & Balances**: Outstanding balances from previous semesters remain visible and payable.

---

## 5. Implementation Checklist for Android Studio
- [ ] **ViewModel**: `AcademicSemesterViewModel` / `StudentProfileViewModel` to observe active semester.
- [ ] **UI Component**: `ReEnrollmentBottomSheetDialog.kt` / `ReEnrollmentActivity.kt`.
- [ ] **Repository**: `SemesterRepository.kt` & `StudentRepository.kt` with `confirmReEnrollment()` method.
- [ ] **Gate Check**: In `QrTicketFragment.kt`, check `student.isReEnrolled(activeSemester)` before generating gate QR.
