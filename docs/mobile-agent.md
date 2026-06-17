# STI Sync Mobile — Agent Routing Protocol

> **App:** STI Sync Student Mobile App (Flutter / Android Studio)
> **Platform:** Android (primary), iOS (secondary)
> **Read this file first on every prompt.** This is the single entry point for all feature implementation. It routes you to the exact files, schemas, and architecture rules you need — nothing more.

---

## 0. Golden Rules

1. **Never scan source files blindly.** All context lives in `docs/`. Read only what the routing table sends you to.
2. **MVVM is non-negotiable.** Every feature = Model + ViewModel + View. No business logic in widgets.
3. **Firestore is the only database.** All data is read/written through the repository layer — never directly from a ViewModel or widget.
4. **Realtime first.** Any data that can change while the app is open (events, attendance status, payment status, announcements) must use `snapshots()` streams — no one-time `get()` calls for live data.
5. **After every implementation, update the relevant docs.** See Section 8.

---

## 1. Context Routing — Mandatory Pre-Execution Phase

### Phase 1: Request Analysis
Parse the prompt and extract:
- **Entity** — what Firestore collection is being touched? (e.g., `events`, `payables`, `attendance`, `announcements`, `students`)
- **Screen** — what screen or feature is being built?
- **Operation** — read (display), write (action), or stream (live data)?

### Phase 2: Schema Binding
1. Open `docs/mobile-database-schema.md`.
2. Find the collection that matches the entity.
3. Verify every field referenced in the feature exists in the schema.
4. **If a field does not exist → halt, propose the addition, update `mobile-database-schema.md` first, then implement.**

### Phase 3: Doc Routing

| Condition | Load These Docs |
|---|---|
| UI-only change (widget, style, layout) | `mobile-agent.md` (this file) |
| Any Firestore read or write | `mobile-database-schema.md` |
| New screen or navigation change | `mobile-agent.md` Section 4 (routes) |
| New entity or schema change | Update `mobile-database-schema.md` first |
| Auth / login flow | `mobile-database-schema.md` (students collection) |

### Phase 4: File Scoping
Navigate to `lib/features/<entity>/` — your exclusive working directory.
Do **not** put business logic in `lib/screens/`, widget files, or `main.dart`.

---

## 2. Architecture — MVVM

```
Widget (View)
    │
    │  watches / reads
    ▼
ViewModel (ChangeNotifier / Riverpod StateNotifier)
    │
    │  calls
    ▼
Repository
    │
    │  wraps
    ▼
Firestore / Firebase Auth / Firebase Storage
```

### Layer Rules

| Layer | Location | Allowed To |
|---|---|---|
| **View** | `lib/features/<entity>/views/` | Render UI, call ViewModel methods, read ViewModel state |
| **ViewModel** | `lib/features/<entity>/viewmodels/` | Hold UI state, call Repository, expose streams/futures |
| **Repository** | `lib/features/<entity>/repositories/` | Query Firestore, return typed models, throw typed exceptions |
| **Model** | `lib/features/<entity>/models/` | Data classes with `fromFirestore()` and `toMap()` |
| **Widget** | `lib/features/<entity>/widgets/` | Reusable sub-widgets scoped to this feature |
| **Shared Widget** | `lib/shared/widgets/` | Cross-feature reusable UI (buttons, loaders, empty states) |

**Hard rule:** A View must never import `cloud_firestore` directly. A ViewModel must never import `cloud_firestore` directly. Only Repositories touch Firestore.

---

## 3. Directory Structure Contract

```
lib/
├── main.dart                          # App entry point — FirebaseApp.initializeApp()
├── app.dart                           # MaterialApp + router configuration
│
├── core/
│   ├── firebase/
│   │   └── firebase_service.dart      # FirebaseFirestore.instance, FirebaseAuth.instance,
│   │                                  # FirebaseStorage.instance — exported singletons
│   ├── router/
│   │   └── app_router.dart            # GoRouter route definitions (all named routes here)
│   ├── theme/
│   │   ├── app_colors.dart            # Color constants
│   │   ├── app_text_styles.dart       # TextStyle constants
│   │   └── app_theme.dart             # ThemeData
│   ├── constants/
│   │   └── firestore_paths.dart       # All collection/document path strings
│   ├── exceptions/
│   │   └── app_exception.dart         # Typed exception classes
│   └── utils/
│       ├── date_formatter.dart        # Timestamp → readable string helpers
│       └── validators.dart            # Form field validators
│
├── features/
│   ├── auth/
│   │   ├── models/
│   │   │   └── student_model.dart
│   │   ├── repositories/
│   │   │   └── auth_repository.dart
│   │   ├── viewmodels/
│   │   │   ├── auth_viewmodel.dart
│   │   │   └── registration_viewmodel.dart   # 6-step registration flow state
│   │   ├── views/
│   │   │   ├── login_screen.dart
│   │   │   ├── splash_screen.dart
│   │   │   ├── welcome_screen.dart
│   │   │   └── registration/
│   │   │       ├── registration_flow_screen.dart  # shell: header + sticky Continue bar
│   │   │       ├── steps/                          # one widget per step (1..6)
│   │   │       │   ├── personal_info_step.dart
│   │   │       │   ├── academic_details_step.dart
│   │   │       │   ├── credentials_step.dart
│   │   │       │   ├── profile_photo_step.dart
│   │   │       │   ├── school_id_step.dart
│   │   │       │   └── review_step.dart
│   │   │       └── widgets/
│   │   │           └── registration_widgets.dart  # shared field/header widgets
│   │   └── widgets/
│   │       └── login_form.dart
│   │   // AGENT-UPDATED: 2026-06-16 — added registration flow (route `register`)
│   │
│   ├── dashboard/
│   │   ├── models/
│   │   │   └── dashboard_summary_model.dart
│   │   ├── repositories/
│   │   │   └── dashboard_repository.dart
│   │   ├── viewmodels/
│   │   │   └── dashboard_viewmodel.dart
│   │   ├── views/
│   │   │   └── dashboard_screen.dart
│   │   └── widgets/
│   │       ├── upcoming_event_card.dart
│   │       ├── announcement_banner.dart
│   │       └── payment_status_chip.dart
│   │
│   ├── events/
│   │   ├── models/
│   │   │   └── event_model.dart
│   │   ├── repositories/
│   │   │   └── event_repository.dart
│   │   ├── viewmodels/
│   │   │   └── event_viewmodel.dart
│   │   ├── views/
│   │   │   ├── events_screen.dart
│   │   │   └── event_detail_screen.dart
│   │   └── widgets/
│   │       ├── event_card.dart
│   │       └── event_status_badge.dart
│   │
│   ├── attendance/
│   │   ├── models/
│   │   │   └── attendance_model.dart
│   │   ├── repositories/
│   │   │   └── attendance_repository.dart
│   │   ├── viewmodels/
│   │   │   └── attendance_viewmodel.dart
│   │   ├── views/
│   │   │   ├── attendance_screen.dart
│   │   │   └── qr_scanner_screen.dart
│   │   └── widgets/
│   │       └── attendance_record_tile.dart
│   │
│   ├── payables/
│   │   ├── models/
│   │   │   └── payable_model.dart
│   │   ├── repositories/
│   │   │   └── payable_repository.dart
│   │   ├── viewmodels/
│   │   │   └── payable_viewmodel.dart
│   │   ├── views/
│   │   │   ├── payables_screen.dart
│   │   │   └── payment_detail_screen.dart
│   │   └── widgets/
│   │       ├── payment_status_card.dart
│   │       └── qr_ticket_widget.dart
│   │
│   ├── announcements/
│   │   ├── models/
│   │   │   └── announcement_model.dart
│   │   ├── repositories/
│   │   │   └── announcement_repository.dart
│   │   ├── viewmodels/
│   │   │   └── announcement_viewmodel.dart
│   │   ├── views/
│   │   │   ├── announcements_screen.dart
│   │   │   └── announcement_detail_screen.dart
│   │   └── widgets/
│   │       └── announcement_tile.dart
│   │
│   ├── certificates/
│   │   ├── models/
│   │   │   └── certificate_model.dart
│   │   ├── repositories/
│   │   │   └── certificate_repository.dart
│   │   ├── viewmodels/
│   │   │   └── certificate_viewmodel.dart
│   │   ├── views/
│   │   │   ├── certificates_screen.dart
│   │   │   └── certificate_detail_screen.dart
│   │   └── widgets/
│   │       └── certificate_card.dart
│   │
│   └── profile/
│       ├── models/
│       │   └── profile_model.dart
│       ├── repositories/
│       │   └── profile_repository.dart
│       ├── viewmodels/
│       │   └── profile_viewmodel.dart
│       ├── views/
│       │   └── profile_screen.dart
│       └── widgets/
│           └── profile_avatar.dart
│
└── shared/
    ├── widgets/
    │   ├── app_button.dart
    │   ├── app_loader.dart
    │   ├── empty_state_widget.dart
    │   ├── error_widget.dart
    │   └── network_image_widget.dart
    └── providers/
        └── providers.dart             # All Riverpod providers registered here
```

---

## 4. Named Routes (GoRouter)

All routes are defined in `lib/core/router/app_router.dart`.

| Name | Path | Screen |
|---|---|---|
| `splash` | `/` | `SplashScreen` |
| `login` | `/login` | `LoginScreen` |
| `register` | `/register` | `RegistrationFlowScreen` (6-step student registration) |
| `dashboard` | `/dashboard` | `DashboardScreen` |
| `events` | `/events` | `EventsScreen` |
| `eventDetail` | `/events/:eventId` | `EventDetailScreen` |
| `attendance` | `/attendance` | `AttendanceScreen` |
| `qrScanner` | `/attendance/scan/:sessionId` | `QrScannerScreen` |
| `payables` | `/payables` | `PayablesScreen` |
| `paymentDetail` | `/payables/:payableId` | `PaymentDetailScreen` |
| `announcements` | `/announcements` | `AnnouncementsScreen` |
| `announcementDetail` | `/announcements/:announcementId` | `AnnouncementDetailScreen` |
| `certificates` | `/certificates` | `CertificatesScreen` |
| `profile` | `/profile` | `ProfileScreen` |

When adding a new route: update this table AND `app_router.dart`.

---

## 5. Image & File Uploads — Cloudinary (Mandatory)

All user-uploaded images and documents (profile photos, school ID photos, any future
document submissions) **must** go through `lib/services/cloudinary_service.dart`.

| Setting | Value |
|---|---|
| Cloud name | `djwlkcgnx` |
| Upload preset | `sti_sync_uploads` (unsigned — no API key needed) |
| Endpoint | `https://api.cloudinary.com/v1_1/djwlkcgnx/auto/upload` |
| Folders | profile photo → `students/profile`; school ID → `students/school-id`; extras → `students/documents` |

**Hard rules:**
- Firestore stores **only the `secure_url` string** returned by Cloudinary. Never store local file paths, byte data, or temporary URIs.
- **Never embed the Cloudinary API Key or API Secret** anywhere in the app. The unsigned preset requires only the cloud name and preset name.
- Every upload screen calls `CloudinaryService.uploadFile(file, folder: '...')` — never inline multipart code.
- Validate before upload: images must be JPG/PNG/WebP, max 5 MB. Show upload progress. Block submit while upload is in flight.

This rule applies to **all future upload features** (profile edits, certificate downloads, document re-submissions, etc.), not just registration.

// AGENT-UPDATED: 2026-06-17 — Added Cloudinary upload mandate section

---

## 6. Technology Mandates

### 6.1 State Management
- **Required:** Riverpod (`flutter_riverpod`) for all state.
- **ViewModel pattern:** `StateNotifier<YourState>` with a corresponding `StateNotifierProvider`.
- **FORBIDDEN:** `setState` in screens (only allowed in isolated local-UI widgets like a text field focus state), `Provider` package, `Bloc`, `GetX`, `MobX`.

```dart
// ✅ Correct — ViewModel
class EventViewModel extends StateNotifier<EventState> {
  final EventRepository _repo;
  EventViewModel(this._repo) : super(const EventState.loading());

  Stream<List<EventModel>> watchUpcomingEvents(String studentId) {
    return _repo.watchUpcomingEvents(studentId);
  }
}

// ✅ Correct — Provider
final eventViewModelProvider = StateNotifierProvider<EventViewModel, EventState>(
  (ref) => EventViewModel(ref.watch(eventRepositoryProvider)),
);
```

### 6.2 Firestore Stream Convention
All live data uses `.snapshots()`. Never use `.get()` for data that updates while the app is open.

```dart
// ✅ Correct — Repository
Stream<List<EventModel>> watchUpcomingEvents(String studentId) {
  return _firestore
    .collection('events')
    .where('status', isEqualTo: 'approved')
    .where('startDate', isGreaterThan: Timestamp.now())
    .orderBy('startDate')
    .snapshots()
    .map((snap) => snap.docs.map((d) => EventModel.fromFirestore(d)).toList());
}

// ✅ Correct — View (consuming stream)
ref.watch(eventRepositoryProvider).watchUpcomingEvents(studentId)

// ❌ Wrong — one-time fetch for live data
await _firestore.collection('events').get();
```

### 6.3 Model Convention
Every model must implement `fromFirestore` and `toMap`:

```dart
class EventModel {
  final String id;
  final String title;
  final EventStatus status;
  final DateTime startDate;

  const EventModel({
    required this.id,
    required this.title,
    required this.status,
    required this.startDate,
  });

  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EventModel(
      id: doc.id,
      title: data['title'] as String,
      status: EventStatus.values.byName(data['status'] as String),
      startDate: (data['startDate'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'status': status.name,
    'startDate': Timestamp.fromDate(startDate),
  };
}
```

### 6.4 Firestore Path Convention
All Firestore collection/document paths are string constants in `lib/core/constants/firestore_paths.dart`. Never hardcode path strings in repositories.

```dart
// lib/core/constants/firestore_paths.dart
class FirestorePaths {
  static const String students = 'students';
  static const String events = 'events';
  static const String eventSessions = 'event_sessions'; // sub-collection
  static const String attendance = 'attendance';
  static const String payables = 'payables';
  static const String announcements = 'announcements';
  static const String certificates = 'certificates';
  static const String organizations = 'organizations';
}
```

### 6.5 Error Handling
All repository methods throw typed exceptions from `lib/core/exceptions/app_exception.dart`. ViewModels catch these and expose them as state.

```dart
// ✅ Repository
Future<void> markAttendance(...) async {
  try {
    await _firestore.collection(FirestorePaths.attendance).add({...});
  } on FirebaseException catch (e) {
    throw AppException(code: e.code, message: e.message ?? 'Firestore error');
  }
}

// ✅ ViewModel
Future<void> checkIn(...) async {
  state = const AttendanceState.loading();
  try {
    await _repo.markAttendance(...);
    state = const AttendanceState.success();
  } on AppException catch (e) {
    state = AttendanceState.error(e.message);
  }
}
```

### 6.6 Navigation
Use `GoRouter` with named routes only. Never use `Navigator.push` with a widget constructor directly.

```dart
// ✅ Correct
context.goNamed('eventDetail', pathParameters: {'eventId': event.id});

// ❌ Wrong
Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailScreen(event: event)));
```

### 6.7 QR Gate Access Rule (Critical)
Before writing any attendance record, **always** check `qrTicketUnlocked` from the student's `/payables` document for that event. If `false`, block the check-in and show a payment-required screen. This logic lives in `attendance_repository.dart`.

---

## 7. Coding Style Rules

- Dart file names: `snake_case.dart`
- Class names: `PascalCase`
- Variables and methods: `camelCase`
- Constants: `camelCase` (Dart convention — no ALL_CAPS except for enum values)
- Every public method must have a doc comment (`///`)
- Every model field must have an inline comment explaining the value
- `const` constructors wherever possible
- No `dynamic` types — all Firestore data must be cast explicitly
- `required` keyword on all non-nullable constructor params

---

## 8. Self-Documentation Update Rule (Non-Negotiable)

After every implementation, update the affected doc **in the same run** before presenting results.

| What Changed | Update Target |
|---|---|
| New Firestore collection or field | `mobile-database-schema.md` — add the type + description |
| New screen added | `mobile-agent.md` Section 4 (routes table) + Section 3 (directory tree) |
| New feature folder created | `mobile-agent.md` Section 3 (directory tree) |
| New Riverpod provider added | `shared/providers/providers.dart` |
| New route added | `mobile-agent.md` Section 4 + `app_router.dart` |

Append this marker to the updated section:
```
// AGENT-UPDATED: YYYY-MM-DD — <what changed>
```

---

## 9. Execution Checklist

Run this before writing any code:

- [ ] Entity identified — which Firestore collection?
- [ ] All fields verified in `mobile-database-schema.md`
- [ ] Working directory confirmed: `lib/features/<entity>/`
- [ ] MVVM layers planned: Model → Repository → ViewModel → View
- [ ] Live data uses `.snapshots()`, not `.get()`
- [ ] No Firestore imports in View or ViewModel files
- [ ] GoRouter named route used for navigation
- [ ] QR gate access check included (if attendance feature)
- [ ] Error handling uses typed `AppException`
- [ ] Docs updated if schema or routes changed

---

## 10. Anti-Patterns — Hard Stops

| Anti-Pattern | Correct Approach |
|---|---|
| `FirebaseFirestore.instance` inside a widget or ViewModel | Move to Repository layer |
| `.get()` for data that changes while app is open | Use `.snapshots()` stream |
| `setState` inside a screen widget | Use Riverpod `StateNotifier` |
| Hardcoding `'events'` string in a query | Use `FirestorePaths.events` constant |
| `Navigator.push(context, MaterialPageRoute(...))` | Use `context.goNamed(...)` |
| Skipping `fromFirestore` / `toMap` on a model | Always implement both |
| Writing attendance without checking `qrTicketUnlocked` | Check payable record first |
| `dynamic` type cast from Firestore data | Explicit cast: `data['field'] as String` |
| Skipping doc update after schema/route change | Update docs before finishing |
| Business logic in a widget build method | Move to ViewModel |
