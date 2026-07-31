import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sti_sync/features/events/models/event_model.dart';
import 'package:sti_sync/core/constants/firestore_paths.dart';
import '../../core/firebase/firebase_service.dart';
import '../../features/auth/repositories/auth_repository.dart';
import '../../features/auth/repositories/registration_repository.dart';
import '../../features/auth/viewmodels/auth_viewmodel.dart';
import '../../features/auth/viewmodels/registration_viewmodel.dart';
import '../../services/cloudinary_service.dart';
import '../../features/sync/services/connectivity_service.dart';
import '../../features/sync/services/sync_service.dart';
import '../../features/sync/services/event_cleanup_service.dart';
import '../../features/events/repositories/event_repository.dart';
import '../../features/events/viewmodels/event_viewmodel.dart';
import '../../features/qr_ticket/repositories/qr_ticket_repository.dart';
import '../../features/qr_ticket/viewmodels/qr_ticket_viewmodel.dart';
import '../../features/scanner/repositories/scanner_repository.dart';
import '../../features/scanner/repositories/offline_attendance_repository.dart';
import '../../features/scanner/viewmodels/scanner_viewmodel.dart';
import '../../features/organizations/repositories/organization_repository.dart';
import '../../features/organizations/models/organization_member_model.dart';
import '../../core/local/app_database.dart';

/// Organization Repository & Memberships Provider
final organizationRepositoryProvider = Provider<OrganizationRepository>((ref) {
  return OrganizationRepository(firestore: ref.watch(firestoreProvider));
});

final myOrganizationsProvider = StreamProvider<List<OrganizationMemberModel>>((ref) {
  final authState = ref.watch(authViewModelProvider);
  final uid = authState.student?.id ?? '';
  if (uid.isEmpty) return Stream.value([]);
  return ref.watch(organizationRepositoryProvider).watchStudentOrganizations(uid);
});

/// Events feature
final eventRepositoryProvider = Provider<EventRepository>((ref) {
  return EventRepository(
    ref.watch(firestoreProvider),
    ref.watch(appDatabaseProvider),
    ref.watch(connectivityServiceProvider),
  );
});

final eventViewModelProvider =
    StateNotifierProvider<EventViewModel, EventState>(
  (ref) => EventViewModel(ref.watch(eventRepositoryProvider)),
);

/// Sync feature
// connectivityServiceProvider is exported from connectivity_service.dart

/// Firebase singletons (re-exported from firebase_service.dart for convenience)
// firestoreProvider, authProvider, storageProvider are defined in firebase_service.dart

/// Cloudinary upload service
final cloudinaryServiceProvider = Provider<CloudinaryService>(
  (_) => CloudinaryService(),
);

/// Auth feature
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(authProvider),
    ref.watch(firestoreProvider),
  );
});

final authViewModelProvider = StateNotifierProvider<AuthViewModel, AuthState>(
  (ref) => AuthViewModel(
    ref.watch(authRepositoryProvider),
    ref.watch(appDatabaseProvider),
  ),
);

/// Registration feature
final registrationRepositoryProvider = Provider<RegistrationRepository>((ref) {
  return RegistrationRepository(
    ref.watch(authProvider),
    ref.watch(firestoreProvider),
    ref.watch(cloudinaryServiceProvider),
  );
});

final registrationViewModelProvider =
    StateNotifierProvider<RegistrationViewModel, RegistrationState>(
  (ref) => RegistrationViewModel(ref.watch(registrationRepositoryProvider)),
);

/// Name Resolvers
final orgNameProvider =
    FutureProvider.family<String, String>((ref, orgId) async {
  if (orgId.isEmpty) return 'Unknown Org';
  try {
    final doc = await ref
        .read(firestoreProvider)
        .collection(FirestorePaths.organizations)
        .doc(orgId)
        .get();
    if (doc.exists) {
      final data = doc.data();
      return data?['name'] as String? ??
          data?['acronym'] as String? ??
          'Unknown Org';
    }
  } catch (_) {}
  return 'Unknown Org';
});

final venueNameProvider =
    FutureProvider.family<String, String>((ref, venueId) async {
  if (venueId.isEmpty) return 'TBA';
  try {
    final doc = await ref
        .read(firestoreProvider)
        .collection(FirestorePaths.venues)
        .doc(venueId)
        .get();
    if (doc.exists) {
      final data = doc.data();
      return data?['name'] as String? ?? 'TBA';
    }
  } catch (_) {}
  return 'TBA';
});

final categoryNameProvider =
    FutureProvider.family<String, String>((ref, categoryId) async {
  if (categoryId.isEmpty) return 'Event';
  try {
    final doc = await ref
        .read(firestoreProvider)
        .collection(FirestorePaths.eventCategories)
        .doc(categoryId)
        .get();
    if (doc.exists) {
      final data = doc.data();
      return data?['name'] as String? ?? 'Event';
    }
  } catch (_) {}
  return 'Event';
});

final orgProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, orgId) async {
  if (orgId.isEmpty) return null;
  try {
    final doc = await ref
        .read(firestoreProvider)
        .collection(FirestorePaths.organizations)
        .doc(orgId)
        .get();
    if (doc.exists) {
      return doc.data();
    }
  } catch (_) {}
  return null;
});

final eventDetailProvider =
    StreamProvider.family<EventModel?, String>((ref, eventId) {
  final studentId = ref.watch(authProvider).currentUser?.uid;
  return ref
      .watch(eventRepositoryProvider)
      .watchEventDetail(eventId, studentId: studentId);
});

final actualParticipantCountProvider =
    FutureProvider.family<int, EventModel>((ref, event) async {
  final firestore = ref.read(firestoreProvider);

  if (event.targetDepartmentIds.isEmpty && event.targetYearLevels.isEmpty) {
    final countSnap =
        await firestore.collection(FirestorePaths.students).count().get();
    return countSnap.count ?? 0;
  }

  if (event.targetDepartmentIds.isNotEmpty) {
    // Firestore whereIn supports up to 10 items. We assume targetDepartmentIds has <= 10 items.
    final snap = await firestore
        .collection(FirestorePaths.students)
        .where('departmentId',
            whereIn: event.targetDepartmentIds.take(10).toList())
        .get();

    var docs = snap.docs;
    if (event.targetYearLevels.isNotEmpty) {
      docs = docs.where((doc) {
        final data = doc.data();
        final yearLevel = data['yearLevel'] as String?;
        return event.targetYearLevels.contains(yearLevel);
      }).toList();
    }
    return docs.length;
  } else {
    // Only yearLevels is provided
    final snap = await firestore
        .collection(FirestorePaths.students)
        .where('yearLevel', whereIn: event.targetYearLevels.take(10).toList())
        .get();
    return snap.docs.length;
  }
});

final connectivityStatusProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.connectivityStream;
});

/// QR Ticket feature
final qrTicketRepositoryProvider = Provider<QrTicketRepository>((ref) {
  return QrTicketRepository(
    ref.watch(firestoreProvider),
    ref.watch(appDatabaseProvider).payablesDao,
    ref.watch(appDatabaseProvider).eventsDao,
    ref.watch(connectivityServiceProvider),
  );
});

final qrTicketViewModelProvider =
    StateNotifierProvider.family<QrTicketViewModel, QrTicketState, String>(
  (ref, eventId) => QrTicketViewModel(ref.watch(qrTicketRepositoryProvider)),
);

/// Scanner feature
final offlineAttendanceRepositoryProvider =
    Provider<OfflineAttendanceRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return OfflineAttendanceRepository(
    firestore: ref.watch(firestoreProvider),
    participantsDao: db.participantsDao,
    payablesDao: db.payablesDao,
    scannerDao: db.scannerDao,
  );
});
final scannerRepositoryProvider = Provider<ScannerRepository>((ref) {
  return ScannerRepository(
    firestore: ref.watch(firestoreProvider),
    scannerDao: ref.watch(appDatabaseProvider).scannerDao,
  );
});

final scannerViewModelProvider =
    StateNotifierProvider<ScannerViewModel, ScannerState>(
  (ref) {
    final viewModel = ScannerViewModel(
      ref.watch(scannerRepositoryProvider),
      ref.watch(offlineAttendanceRepositoryProvider),
    );

    // Automatically load assignments when the user logs in
    ref.listen<String?>(
      authViewModelProvider.select((state) => state.student?.id),
      (previous, next) {
        if (next != null && next.isNotEmpty && next != previous) {
          // Delay the state modification to avoid modifying the provider
          // while the widget tree is still building.
          Future.microtask(() => viewModel.loadAssignments(next));
        }
      },
      fireImmediately: true,
    );

    return viewModel;
  },
);

/// Convenience stream: resolves the current user UID and streams active
/// scanner assignments. Watches authViewModelProvider so it re-subscribes
/// if the user logs in/out.
final activeScannerAssignmentsProvider = StreamProvider(
  (ref) {
    final authState = ref.watch(authViewModelProvider);
    final uid = authState.student?.id ?? '';
    if (uid.isEmpty) {
      return const Stream.empty();
    }
    return ref.watch(scannerRepositoryProvider).watchScannerAssignments(uid);
  },
);

/// Sync service — handles uploading pending offline attendance to Firestore,
/// duplicate detection, and conflict resolution.
final syncServiceProvider = Provider<SyncService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final service = SyncService(
    firestore: ref.watch(firestoreProvider),
    attendanceDao: db.attendanceDao,
    participantsDao: db.participantsDao,
    connectivityService: ref.watch(connectivityServiceProvider),
    getCurrentStudent: () => ref.read(authViewModelProvider).student,
  );
  // Auto-sync disabled per user requirement — sync is strictly manual via Sync button
  ref.onDispose(() => service.dispose());
  return service;
});

/// Event cleanup service — purges locally cached data for expired events.
/// Runs a 30-minute periodic check while the app is open.
final eventCleanupServiceProvider = Provider<EventCleanupService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final service = EventCleanupService(
    attendanceDao: db.attendanceDao,
    participantsDao: db.participantsDao,
    payablesDao: db.payablesDao,
    scannerDao: db.scannerDao,
    syncService: ref.watch(syncServiceProvider),
  );
  service.startPeriodicCheck();
  ref.onDispose(() => service.dispose());
  return service;
});
