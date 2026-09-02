import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sti_sync/features/events/models/event_model.dart';
import 'package:sti_sync/core/constants/firestore_paths.dart';
import '../../core/firebase/firebase_service.dart';
import '../../features/auth/models/student_model.dart';
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
import '../../features/payables/models/payable_model.dart';
import '../../features/payables/repositories/payables_repository.dart';
import '../../features/announcements/models/announcement_model.dart';
import '../../features/announcements/repositories/announcements_repository.dart';
import '../../features/semester/models/semester_model.dart';
import '../../features/semester/repositories/semester_repository.dart';
import '../../core/local/app_database.dart';

/// Semester feature
final semesterRepositoryProvider = Provider<SemesterRepository>((ref) {
  return SemesterRepository(ref.watch(firestoreProvider));
});

/// Announcements feature
final announcementsRepositoryProvider = Provider<AnnouncementsRepository>((ref) {
  return AnnouncementsRepository(ref.watch(firestoreProvider));
});


final announcementsStreamProvider = StreamProvider<List<AnnouncementModel>>((ref) {
  final student = ref.watch(authViewModelProvider).student;
  final myOrgsAsync = ref.watch(myOrganizationsProvider);
  final studentOrgIds = myOrgsAsync.maybeWhen(
    data: (memberships) => memberships.map((m) => m.organizationId).toList(),
    orElse: () => <String>[],
  );

  return ref.watch(announcementsRepositoryProvider).watchTargetedAnnouncements(
        student: student,
        studentOrgIds: studentOrgIds,
      );
});


/// Payables feature
final payablesRepositoryProvider = Provider<PayablesRepository>((ref) {
  return PayablesRepository(
    ref.watch(firestoreProvider),
    ref.watch(appDatabaseProvider),
  );
});

final studentPayablesStreamProvider = StreamProvider<List<PayableModel>>((ref) {
  final authState = ref.watch(authViewModelProvider);
  final uid = authState.student?.id ?? '';
  if (uid.isEmpty) return Stream.value([]);
  return ref.watch(payablesRepositoryProvider).watchStudentPayables(uid);
});

// Alias for backward compatibility across existing views
final payablesStreamProvider = studentPayablesStreamProvider;

final eventPayableFamilyProvider = StreamProvider.family<PayableModel?, String>((ref, eventId) {
  final authState = ref.watch(authViewModelProvider);
  final uid = authState.student?.id ?? '';
  if (uid.isEmpty || eventId.isEmpty) return Stream.value(null);
  return ref.watch(payablesRepositoryProvider).watchEventPayable(uid, eventId);
});

/// Filter selection state: 'all' | 'event_fee' | 'membership_due' | 'fine'
final payablesFilterProvider = StateProvider<String>((ref) => 'all');

/// Filtered payables list
final filteredPayablesProvider = Provider<List<PayableModel>>((ref) {
  final payablesAsync = ref.watch(studentPayablesStreamProvider);
  final filter = ref.watch(payablesFilterProvider);

  return payablesAsync.maybeWhen(
    data: (payables) {
      if (filter == 'all') return payables;
      if (filter == 'event_fee') {
        return payables.where((p) => p.type == 'event_fee' || p.payableType == PayableType.eventFee).toList();
      }
      if (filter == 'membership_due') {
        return payables.where((p) => p.type == 'membership_due' || p.payableType == PayableType.membershipDue).toList();
      }
      if (filter == 'fine') {
        return payables.where((p) => p.type == 'org_fine' || p.type == 'admin_fine' || p.payableType == PayableType.orgFine || p.payableType == PayableType.adminFine).toList();
      }
      return payables;
    },
    orElse: () => [],
  );
});

final payablesSummaryProvider = Provider<PayablesSummary>((ref) {
  final payablesAsync = ref.watch(studentPayablesStreamProvider);
  return payablesAsync.maybeWhen(
    data: (payables) => PayablesSummary.fromPayables(payables),
    orElse: () => const PayablesSummary(
      totalAssigned: 0,
      totalPaid: 0,
      totalOutstanding: 0,
      paidPercentage: 1.0,
      pendingCount: 0,
      overdueCount: 0,
      nextDue: null,
    ),
  );
});

/// Unsettled payables count for Navigation Bar Badge
final unreadPayablesBadgeProvider = Provider<int>((ref) {
  final summary = ref.watch(payablesSummaryProvider);
  return summary.pendingCount;
});



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

final eventsStreamProvider = StreamProvider<List<EventModel>>((ref) {
  final student = ref.watch(authViewModelProvider).student;
  if (student == null || student.id.isEmpty) return Stream.value([]);
  final myOrgsAsync = ref.watch(myOrganizationsProvider);
  final studentOrgIds = myOrgsAsync.maybeWhen(
    data: (memberships) => memberships.map((m) => m.organizationId).toList(),
    orElse: () => <String>[],
  );

  return ref.watch(eventRepositoryProvider).watchEligibleEvents(
        student: student,
        studentOrgIds: studentOrgIds,
      );
});

final activeSemesterModelProvider = StreamProvider<SemesterModel?>((ref) {
  return ref.watch(semesterRepositoryProvider).watchActiveSemester();
});

final activeSemesterProvider = StreamProvider<String>((ref) {
  final semAsync = ref.watch(activeSemesterModelProvider);
  return semAsync.when(
    data: (sem) => Stream.value(sem?.displayName ?? ''),
    loading: () => Stream.value(''),
    error: (_, __) => Stream.value(''),
  );
});

final isPendingReEnrollmentProvider = Provider<bool>((ref) {
  final student = ref.watch(authViewModelProvider).student;
  if (student == null) return false;
  final activeSemester = ref.watch(activeSemesterModelProvider).valueOrNull;
  return student.isPendingReEnrollment(activeSemester);
});



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

enum EventFilterCategory { all, schoolSao, myOrgs, completed }

final eventFilterCategoryProvider =
    StateProvider<EventFilterCategory>((ref) => EventFilterCategory.all);

final eventSearchQueryProvider =
    StateProvider<String>((ref) => '');

/// Name Resolvers
final orgNameProvider =
    FutureProvider.family<String, String>((ref, orgId) async {
  final trimmed = orgId.trim();
  final lower = trimmed.toLowerCase();
  if (trimmed.isEmpty ||
      lower == 'sas' ||
      lower == 'sao' ||
      lower == 'sas_admin' ||
      lower == 'sao_admin' ||
      lower == 'admin' ||
      lower == 'sti' ||
      lower == 'sti_college') {
    return 'STI College / SAO';
  }
  try {
    final doc = await ref
        .read(firestoreProvider)
        .collection(FirestorePaths.organizations)
        .doc(trimmed)
        .get();
    if (doc.exists) {
      final data = doc.data();
      return data?['name'] as String? ??
          data?['acronym'] as String? ??
          'STI College / SAO';
    }
  } catch (_) {}
  return 'STI College / SAO';
});

final venueNameProvider =
    FutureProvider.family<String, String>((ref, venueId) async {
  final trimmed = venueId.trim();
  if (trimmed.isEmpty) return 'Campus Venue';
  try {
    final doc = await ref
        .read(firestoreProvider)
        .collection(FirestorePaths.venues)
        .doc(trimmed)
        .get();
    if (doc.exists && doc.data() != null) {
      final data = doc.data()!;
      final name = data['name'] as String? ??
          data['venueName'] as String? ??
          data['venue_name'] as String? ??
          data['title'] as String? ??
          data['venue'] as String? ??
          data['location'] as String? ??
          data['label'] as String?;
      if (name != null && name.trim().isNotEmpty) {
        return name.trim();
      }
    }
  } catch (e) {
    debugPrint('venueNameProvider: Failed to load venue for $trimmed: $e');
  }
  return 'Campus Venue';
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
    FutureProvider.family<int, String>((ref, eventId) async {
  if (eventId.isEmpty) return 0;
  final isOnline = ref.read(connectivityServiceProvider).isOnline;
  if (!isOnline) {
    try {
      final db = ref.read(appDatabaseProvider);
      final count = await db.participantsDao.getParticipantCount(eventId);
      return count > 0 ? count : 0;
    } catch (_) {
      return 0;
    }
  }

  try {
    final firestore = ref.read(firestoreProvider);
    final eventDoc =
        await firestore.collection(FirestorePaths.events).doc(eventId).get();
    if (!eventDoc.exists) return 0;
    final event = EventModel.fromFirestore(eventDoc);

    if (event.targetAudienceScope != 'members' &&
        event.targetDepartmentIds.isEmpty &&
        event.targetYearLevels.isEmpty &&
        event.targetCourses.isEmpty &&
        event.targetSections.isEmpty &&
        (event.targetAcademicLevel == null || event.targetAcademicLevel == 'BOTH')) {
      final countSnap =
          await firestore.collection(FirestorePaths.students).count().get();
      return countSnap.count ?? 0;
    }

    final snap = await firestore.collection(FirestorePaths.students).get();
    final eligibleCount = snap.docs.where((doc) {
      final student = StudentModel.fromFirestore(doc);
      return event.isStudentEligible(student);
    }).length;

    return eligibleCount;
  } catch (_) {
    return 0;
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
    return ref.watch(scannerRepositoryProvider).watchScannerAssignments(uid).map(
      (assignments) {
        final active = assignments.where((a) => a.canScan).toList();
        active.sort((a, b) => b.eventEndTime.compareTo(a.eventEndTime));
        return active;
      },
    );
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
