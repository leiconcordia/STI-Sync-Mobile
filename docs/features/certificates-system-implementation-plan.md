# STI Sync Mobile — Certificate System Implementation Plan

> **Feature Domain:** Digital Certificates & Participation Credentials  
> **Target System:** STI Sync Student Mobile App (Flutter / Android / iOS)  
> **Source Collections:** `/certificates_issued` (web issuance collection), `/certificates`, `/certificate_templates`  
> **Target Audience:** Mobile Engineering Team, Full-Stack Developers  
> **Protocol Reference:** `docs/mobile-agent.md` & `docs/mobile-database-schema.md`

---

## 1. Executive Summary & Objective

In the STI Sync Web Portal (`/officer/certificates` and `/admin/certificates`), officers and administrators generate event certificates in batch. When generated, records are committed to the Firestore collection `certificates_issued`, linking each recipient's `studentId`, `recipientName`, `course`, `eventId`, `eventTitle`, `templateId`, and `issuedAt`.

Currently in the mobile app:
1. The student certificates / awards experience is hardcoded or placeholder-only (dormant "Awards" button in `QuickActionsGrid`).
2. There is no repository, ViewModel, or real-time Firestore stream fetching student credentials.
3. The mobile application needs to fetch **only the logged-in student's certificates** and allow the student to preview and **download/export his or her own single certificate** (not a multi-recipient bulk PDF).

This implementation plan defines the complete end-to-end architecture following the mandatory **MVVM pattern**, **real-time Firestore streams**, **schema binding**, and **single-recipient PDF generation & download**.

---

## 2. Context & Database Schema Binding

### 2.1 Web Issuance Structure (`certificates_issued`)
In `STI Sync Web` (`src/app/modules/certificates/services/certificate.service.ts` & `ExportModal.tsx`), each record written to `certificates_issued` contains:

```typescript
export interface IssuedCertificateRecord {
  id: string;                    // Firestore Document ID
  eventId: string;               // FK → /events
  eventTitle: string;            // Denormalized Event Title (e.g. "IT Guild Tech Summit 2025")
  templateId: string;            // FK → /certificates or /certificate_templates
  templateName: string;          // Denormalized Template Name
  recipientName: string;         // Recipient Student Full Name (e.g. "Juan Dela Cruz")
  studentId: string;             // Student STI ID (e.g. "02000213456") or Auth UID
  course: string;                // Student Course (e.g. "BSIT-3A")
  issuedAt: Timestamp;           // Server timestamp of generation
  issuedBy: string;              // Auth UID of issuing officer or admin
}
```

### 2.2 Template Structure (`certificates` / `certificate_templates`)
The associated visual layout is stored in `/certificates` or `/certificate_templates`:

```typescript
export interface CertificateItem {
  id: string;
  title: string;                 // e.g. "Certificate of Participation"
  category: string;              // "Participation" | "Recognition" | "Achievement" | etc.
  status: string;                // "Published" | "Approved"
  organizationId: string;        // "admin" or orgId
  organizationName: string;      // e.g. "SAO Admin"
  imageUrl?: string;             // Cloudinary / Firebase Storage URL of background template
  designPreset?: string;         // "classic_gold", "modern_blue", etc.
  paperSize?: string;            // "a4" | "letter" | "short" | "long"
  orientation?: string;          // "landscape" | "portrait"
  namePosition: {
    xPercent: number;            // 0 - 100% horizontal coordinate
    yPercent: number;            // 0 - 100% vertical coordinate
    widthPercent: number;        // bounding width percentage
    fontSizePt: number;          // e.g. 32
    fontFamily: string;          // e.g. "Great Vibes", "Montserrat", "Arial"
    fontWeight: string;          // "Regular" | "Bold" | "Italic"
    textColor: string;           // Hex color (e.g. "#001A4D")
    textAlign: string;           // "left" | "center" | "right"
  };
  elements?: CertificateElement[]; // Optional custom draggable elements
  signatoryName?: string;
  signatoryTitle?: string;
  secondarySignatoryName?: string;
  secondarySignatoryTitle?: string;
}
```

### 2.3 Mobile Query Strategy (Strict Scoping)
Per the user requirement: **"download his/her cert not all cert"**:
- Students must only receive and view certificates where `studentId` matches their own official STI Student ID (`student.studentId`) or Auth UID (`student.id`).
- Real-time `snapshots()` stream querying `certificates_issued`:
```dart
_firestore
  .collection(FirestorePaths.certificatesIssued)
  .where('studentId', isEqualTo: currentStudent.studentId)
  .orderBy('issuedAt', descending: true)
  .snapshots()
```
*Note:* An Rx combined stream will query both `student.studentId` and `student.id` to guarantee zero missing certificates regardless of whether attendance was logged via manual entry or QR scan.

---

## 3. Architecture & File Scoping (MVVM)

In accordance with `docs/mobile-agent.md`, all certificate code is strictly scoped to `lib/features/certificates/`:

```
lib/features/certificates/
├── models/
│   ├── issued_certificate_model.dart     # Typed Firestore model for certificates_issued
│   └── certificate_template_model.dart   # Layout & styling model for rendering/PDF
├── repositories/
│   └── certificate_repository.dart       # Pure Firestore operations & streams
├── viewmodels/
│   └── certificate_viewmodel.dart        # StateNotifier / StreamProvider & PDF generation state
├── views/
│   ├── certificates_screen.dart          # Student Certificate Gallery / List View
│   └── certificate_detail_screen.dart    # Full-screen Preview, Metadata & Download Actions
└── widgets/
    ├── certificate_card.dart             # Card UI in gallery with status & quick actions
    └── certificate_preview_canvas.dart   # Dynamic layout preview rendering template + student name
```

### Layer Responsibilities

| Layer | Responsibility | Constraints |
|---|---|---|
| **Model** | Serializes/deserializes Firestore data with `fromFirestore` and `toMap`. | Immutable, pure Dart. |
| **Repository** | Queries `certificates_issued` and `certificates` / `certificate_templates`. | Only layer importing `cloud_firestore`. |
| **ViewModel** | Exposes streams to UI, manages filter state (e.g., all vs. by year/org), triggers PDF building. | No direct Firestore calls. Exposes Riverpod providers. |
| **View** | Renders certificate list, empty states, and detail viewer. | Watches ViewModel, triggers download callbacks. |
| **PDF Service** | Renders single-student A4 Landscape/Portrait PDF using `pdf` & `printing`. | Generates in-memory bytes and invokes system download / share sheet. |

---

## 4. Single-Recipient PDF Generation & Download Engine

Unlike the Web Admin which exports a combined multi-page document for all event attendees, the mobile app creates a **dedicated, high-definition, single-page vector PDF for the logged-in student**:

```
[Student Clicks "Download Certificate"]
               │
               ▼
[Fetch Template Image Bytes (Cloudinary/Storage)]
               │
               ▼
[Initialize pdf.Document (A4 / Letter, Landscape/Portrait)]
               │
               ▼
[Draw Template Background Image full bleed]
               │
               ▼
[Overlay Recipient Name at xPercent, yPercent, fontSizePt, textColor]
               │
               ▼
[Overlay Dynamic Elements (Event Title, Date, Signatures, Verification Badge)]
               │
               ▼
[Invoke Printing.sharePdf() / Printing.layoutPdf()]
(Allows student to direct-save to device, open in PDF viewer, or print)
```

### Required Dependencies
- `pdf: ^3.11.1` — Vector PDF document construction.
- `printing: ^5.13.2` — Cross-platform Android/iOS native print, preview, and "Save to Downloads / Share" integration.

---

## 5. Step-by-Step Implementation Roadmap

### Phase 1: Documentation & Schema Updates
1. **Update `docs/mobile-database-schema.md`**:
   - Register collection `/certificates_issued` with exact fields matching the web app.
   - Document foreign key references to `/certificates` / `/certificate_templates`.
2. **Update `docs/mobile-agent.md`**:
   - Register `docs/features/certificates-system.md` in Phase 3 Doc Routing.
   - Verify `/certificates` and `/certificates/:certificateId` in Section 4 named routes.
3. **Create `docs/features/certificates-system.md`**:
   - Write comprehensive domain documentation covering issuance lifecycle, security rules, and PDF rendering engine.

### Phase 2: Core Constants & Dependencies
1. Update `pubspec.yaml` with `pdf` and `printing` packages.
2. Run `flutter pub get`.
3. Update `lib/core/constants/firestore_paths.dart`:
   - Add `static const String certificatesIssued = 'certificates_issued';`
   - Add `static const String certificateTemplates = 'certificate_templates';`

### Phase 3: Data Layer (Models & Repository)
1. **`IssuedCertificateModel`** (`lib/features/certificates/models/issued_certificate_model.dart`):
   - Fields: `id`, `eventId`, `eventTitle`, `templateId`, `templateName`, `recipientName`, `studentId`, `course`, `issuedAt`, `issuedBy`.
2. **`CertificateTemplateModel`** (`lib/features/certificates/models/certificate_template_model.dart`):
   - Fields: `id`, `title`, `imageUrl`, `paperSize`, `orientation`, `namePosition`, `signatoryName`, `signatoryTitle`, etc.
3. **`CertificateRepository`** (`lib/features/certificates/repositories/certificate_repository.dart`):
   - `streamMyCertificates(String studentId, String authUid)`
   - `getTemplateById(String templateId)`
   - `getCertificateById(String certificateId)`

### Phase 4: Business Logic Layer (ViewModel & Providers)
1. **`CertificateViewModel`** (`lib/features/certificates/viewmodels/certificate_viewmodel.dart`):
   - Exposes reactive stream of certificates.
   - Download method: `downloadStudentCertificate(BuildContext context, IssuedCertificateModel cert, CertificateTemplateModel? template)`.
   - Generates single A4 landscape PDF and initiates system download/share sheet.
2. Register providers in `lib/shared/providers/providers.dart`.

### Phase 5: Presentation Layer (Views & Widgets)
1. **`CertificateCard`** (`lib/features/certificates/widgets/certificate_card.dart`):
   - Displays event name, issued date, recipient details, and "View & Download" button.
2. **`CertificatePreviewCanvas`** (`lib/features/certificates/widgets/certificate_preview_canvas.dart`):
   - Visual on-screen preview widget with proper aspect ratio (A4 landscape ~ 1.414:1) showing the certificate layout.
3. **`CertificatesScreen`** (`lib/features/certificates/views/certificates_screen.dart`):
   - Search/filter bar by event title or category.
   - Real-time list of student certificates with pull-to-refresh.
   - Empty state illustration when no certificates have been issued yet.
4. **`CertificateDetailScreen`** (`lib/features/certificates/views/certificate_detail_screen.dart`):
   - High-fidelity preview.
   - Metadata card (Event, Organization, Issued Date, Certificate Reference ID).
   - Sticky primary button: "Download PDF (Single Certificate)".

### Phase 5: Navigation & Dashboard Wiring
1. Update `lib/core/router/app_router.dart`:
   - Add GoRoute `/certificates` -> `CertificatesScreen`.
   - Add GoRoute `/certificates/:certificateId` -> `CertificateDetailScreen`.
2. Update `QuickActionsGrid` (`lib/features/dashboard/widgets/quick_actions_grid.dart`):
   - Tap handler on "Awards" / "Certificates" navigating to `/certificates`.

---

## 6. Verification & Quality Acceptance

| Test Case | Scenario | Expected Result |
|---|---|---|
| **Query Isolation** | Student A logs in. Certificates for Student B exist in `certificates_issued`. | Student A only sees certificates where `studentId == Student A's ID`. |
| **Live Sync** | Admin issues certificates in Web Portal for an event. | Mobile app updates in real-time without app restart (`snapshots()` stream). |
| **Single Cert Export** | Student clicks "Download Certificate". | Generates a 1-page PDF for that student only, matching the template dimensions. |
| **Offline Resilience** | Device enters offline mode after viewing certificates. | Firestore cache preserves list; proper offline indicator when download requires network. |
| **Orientation & Layout** | Template has landscape orientation and specific text offsets. | Canvas and generated PDF accurately align the student's name and event title. |
