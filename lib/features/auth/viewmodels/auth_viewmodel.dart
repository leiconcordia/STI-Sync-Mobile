import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/student_model.dart';
import '../repositories/auth_repository.dart';
import '../../../core/exceptions/app_exception.dart';

class AuthState {
  final bool isLoading;
  final String? errorMessage;
  final StudentModel? student;
  final bool isAuthenticated;

  const AuthState({
    this.isLoading = false,
    this.errorMessage,
    this.student,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    bool? isLoading,
    String? errorMessage,
    StudentModel? student,
    bool? isAuthenticated,
    bool clearError = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage,
      student: student ?? this.student,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

class AuthViewModel extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthViewModel(this._repository) : super(const AuthState()) {
    _init();
  }

  // Set to true while registration is in progress so the auth listener
  // does not sign the user out before the Firestore document is written.
  bool _registrationInProgress = false;

  void setRegistrationInProgress(bool value) {
    _registrationInProgress = value;
  }

  void _init() {
    _repository.authStateChanges.listen((user) async {
      if (user != null) {
        // If registration is still running, the Firestore doc doesn't exist
        // yet — do nothing and wait for registration to complete.
        if (_registrationInProgress) return;

        try {
          final student = await _repository.getStudentProfile(user.uid);
          if (student != null && student.status == 'ACTIVE') {
            state = state.copyWith(
              isAuthenticated: true,
              student: student,
              isLoading: false,
            );
          } else if (student != null) {
            // Account exists but status is PENDING / RETURNED / etc.
            // Don't sign out automatically here — only sign out on explicit login.
            state = state.copyWith(
              isAuthenticated: false,
              student: null,
              isLoading: false,
            );
          }
          // If student == null: doc not yet written (edge case during
          // registration or account just created) — stay silent.
        } catch (e) {
          state = state.copyWith(
            isAuthenticated: false,
            errorMessage: e.toString(),
            isLoading: false,
          );
        }
      } else {
        state = state.copyWith(
          isAuthenticated: false,
          student: null,
          isLoading: false,
        );
      }
    });
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repository.login(email, password);
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(
          isLoading: false, errorMessage: 'An unexpected error occurred.');
    }
  }

  Future<void> logout() async => _repository.logout();

  String _pendingMessage(String status) {
    switch (status) {
      case 'PENDING':
        return 'Your account is pending SAO review. You will be notified once approved.';
      case 'RETURNED':
        return 'Your registration was returned for corrections. Please contact the SAO office.';
      case 'INACTIVE':
      case 'SUSPENDED':
        return 'Your account has been deactivated. Contact the SAO office for assistance.';
      default:
        return 'Your account is not active. Contact the SAO office.';
    }
  }
}
