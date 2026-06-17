import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/firebase/firebase_service.dart';
import '../../features/auth/repositories/auth_repository.dart';
import '../../features/auth/repositories/registration_repository.dart';
import '../../features/auth/viewmodels/auth_viewmodel.dart';
import '../../features/auth/viewmodels/registration_viewmodel.dart';
import '../../services/cloudinary_service.dart';

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
    StateNotifierProvider.autoDispose<RegistrationViewModel, RegistrationState>(
  (ref) => RegistrationViewModel(ref.watch(registrationRepositoryProvider)),
);
