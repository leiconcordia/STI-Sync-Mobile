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
import '../../features/events/repositories/event_repository.dart';
import '../../features/events/viewmodels/event_viewmodel.dart';
import '../../core/local/app_database.dart';

/// Events feature
final eventRepositoryProvider = Provider<EventRepository>((ref) {
  return EventRepository(
    ref.watch(firestoreProvider),
    ref.watch(appDatabaseProvider),
  );
});

final eventViewModelProvider = StateNotifierProvider<EventViewModel, EventState>(
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
  (ref) => AuthViewModel(ref.watch(authRepositoryProvider)),
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
final orgNameProvider = FutureProvider.family<String, String>((ref, orgId) async {
  if (orgId.isEmpty) return 'Unknown Org';
  try {
    final doc = await ref.read(firestoreProvider).collection(FirestorePaths.organizations).doc(orgId).get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>?;
      return data?['name'] as String? ?? data?['acronym'] as String? ?? 'Unknown Org';
    }
  } catch (_) {}
  return 'Unknown Org';
});

final venueNameProvider = FutureProvider.family<String, String>((ref, venueId) async {
  if (venueId.isEmpty) return 'TBA';
  try {
    final doc = await ref.read(firestoreProvider).collection(FirestorePaths.venues).doc(venueId).get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>?;
      return data?['name'] as String? ?? 'TBA';
    }
  } catch (_) {}
  return 'TBA';
});

final categoryNameProvider = FutureProvider.family<String, String>((ref, categoryId) async {
  if (categoryId.isEmpty) return 'Event';
  try {
    final doc = await ref.read(firestoreProvider).collection(FirestorePaths.eventCategories).doc(categoryId).get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>?;
      return data?['name'] as String? ?? 'Event';
    }
  } catch (_) {}
  return 'Event';
});

final orgProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, orgId) async {
  if (orgId.isEmpty) return null;
  try {
    final doc = await ref.read(firestoreProvider).collection(FirestorePaths.organizations).doc(orgId).get();
    if (doc.exists) {
      return doc.data() as Map<String, dynamic>?;
    }
  } catch (_) {}
  return null;
});

final eventDetailProvider = StreamProvider.family<EventModel?, String>((ref, eventId) {
  return ref.read(firestoreProvider).collection(FirestorePaths.events).doc(eventId).snapshots().map((doc) {
    if (doc.exists) {
      return EventModel.fromFirestore(doc);
    }
    return null;
  });
});

final actualParticipantCountProvider = FutureProvider.family<int, EventModel>((ref, event) async {
  final firestore = ref.read(firestoreProvider);
  
  if (event.targetDepartmentIds.isEmpty && event.targetYearLevels.isEmpty) {
    final countSnap = await firestore.collection(FirestorePaths.students).count().get();
    return countSnap.count ?? 0;
  }

  if (event.targetDepartmentIds.isNotEmpty) {
    // Firestore whereIn supports up to 10 items. We assume targetDepartmentIds has <= 10 items.
    final snap = await firestore
        .collection(FirestorePaths.students)
        .where('departmentId', whereIn: event.targetDepartmentIds.take(10).toList())
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
