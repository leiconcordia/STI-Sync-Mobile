# STI Sync Mobile — Certificate & Credential System Specification

> **Feature Domain:** Digital Certificates & Participation Credentials  
> **Target Systems:** STI Sync Student Mobile App & Web Admin/Officer Synchronization  
> **Firestore Collections:** `/certificates_issued`, `/certificates`, `/certificate_templates`  
> **Status:** Active

---

## 1. Overview & Business Rules

When student organization officers or SAO administrators batch-issue certificates in the Web Portal, records are committed to the Firestore collection `/certificates_issued`.

### Core Business Rules:
1. **Student Isolation**: In the mobile application, students can only query and retrieve their **own** issued certificates (`studentId == currentStudent.studentId` or `studentId == currentStudent.id`).
2. **Single-Recipient Export**: Unlike the Web Portal batch export (which compiles all event recipients into one combined multi-page PDF), the student mobile client exports **exclusively his or her own single certificate** in high-definition A4 or Letter format.
3. **Template Dynamic Binding**: Each issued certificate references a `templateId`. The mobile app resolves this template from `/certificates` or `/certificate_templates`, extracting the template background image, orientation, and layout coordinates (`namePosition`, `elements`).
4. **Realtime Updates**: The certificates gallery uses Firestore `snapshots()` streams so that as soon as an event officer generates certificates on the web, the student sees their new certificate immediately without refreshing.

---

## 2. Firestore Document Structure

### 2.1 `/certificates_issued/{id}`
```typescript
interface IssuedCertificateRecord {
  id: string;               // Document ID
  eventId: string;          // FK → /events
  eventTitle: string;       // e.g. "Tech Summit 2026"
  templateId: string;       // FK → /certificates or /certificate_templates
  templateName: string;     // e.g. "Standard Participation"
  recipientName: string;    // e.g. "Juan Dela Cruz"
  studentId: string;        // STI Student ID (e.g. "02000213456") or Auth UID
  course: string;           // e.g. "BSIT-3A"
  issuedAt: Timestamp;      // Timestamp of issuance
  issuedBy: string;         // Auth UID of issuer
}
```

### 2.2 `/certificates/{id}` or `/certificate_templates/{id}`
```typescript
interface CertificateTemplate {
  id: string;
  title: string;            // Template title
  category: string;         // "Participation", "Recognition", etc.
  imageUrl: string;         // Cloudinary / Firebase Storage URL
  paperSize: string;        // "a4", "letter", "short", "long"
  orientation: string;      // "landscape", "portrait"
  namePosition: {
    xPercent: number;       // 0 - 100%
    yPercent: number;       // 0 - 100%
    fontSizePt: number;
    textColor: string;      // Hex color
    fontFamily: string;
    fontWeight: string;
    textAlign: string;
  };
  elements?: Array<{
    id: string;
    text: string;
    xPercent: number;
    yPercent: number;
    fontSizePt: number;
    textColor: string;
  }>;
  signatoryName?: string;
  signatoryTitle?: string;
}
```

---

## 3. Architecture & File Structure (MVVM)

```
lib/features/certificates/
├── models/
│   ├── issued_certificate_model.dart     # Typed Firestore model
│   └── certificate_template_model.dart   # Layout styling & element coordinates
├── repositories/
│   └── certificate_repository.dart       # Pure Firestore operations & streams
├── viewmodels/
│   └── certificate_viewmodel.dart        # Real-time state & single-cert PDF generation
├── views/
│   ├── certificates_screen.dart          # Certificate gallery & search
│   └── certificate_detail_screen.dart    # Full preview & download action
└── widgets/
    ├── certificate_card.dart             # Gallery card widget
    └── certificate_preview_canvas.dart   # Visual on-screen layout renderer
```

---

## 4. Single-Recipient PDF Generation Engine

The mobile client leverages `pdf` and `printing`:
1. Downloads background template image bytes if available.
2. Constructs a 1-page vector `pdf.Document` configured with the template dimensions (A4/Letter, Landscape/Portrait).
3. Renders background template image, recipient name at `namePosition`, and event title / dates / signatories.
4. Invokes `Printing.sharePdf()` / `Printing.layoutPdf()`, allowing the student to save to device storage, print, or share.
