import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/student_model.dart';
import '../repositories/auth_repository.dart';
import '../../../core/exceptions/app_exception.dart';
import '../../../core/local/app_database.dart';

class AuthState {
  final bool isLoading;
  final String? errorMessage;
  final StudentModel? student;
  final StudentModel? pendingStudent; // Added for PENDING/RETURNED accounts
  final bool isAuthenticated;

  const AuthState({
    this.isLoading = false,
    this.errorMessage,
    this.student,
    this.pendingStudent,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    bool? isLoading,
    String? errorMessage,
    StudentModel? student,
    StudentModel? pendingStudent,
    bool? isAuthenticated,
    bool clearError = false,
    bool clearStudent = false,
    bool clearPendingStudent = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage,
      student: clearStudent ? null : (student ?? this.student),
      pendingStudent: clearPendingStudent ? null : (pendingStudent ?? this.pendingStudent),
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

class AuthViewModel extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final AppDatabase _appDatabase;

  AuthViewModel(this._repository, this._appDatabase) : super(const AuthState()) {
    _init();
  }

  // Set to true while registration is in progress so the auth listener
  // does not sign the user out before the Firestore document is written.
  bool _registrationInProgress = false;

  void setRegistrationInProgress(bool value) {
    _registrationInProgress = value;
    if (!value) {
      // Registration just finished. If we have a user, trigger a manual fetch
      // to update the state since we ignored the stream events during registration.
      final user = _repository.auth.currentUser;
      if (user != null) {
        _repository.getStudentProfile(user.uid).then((student) {
          if (student != null) {
            if (student.status == 'ACTIVE') {
              state = state.copyWith(
                isAuthenticated: true,
                student: student,
                clearPendingStudent: true,
                isLoading: false,
              );
            } else if (student.status == 'PENDING' || student.status == 'RETURNED') {
              state = state.copyWith(
                isAuthenticated: true,
                pendingStudent: student,
                clearStudent: true,
                isLoading: false,
              );
            }
          }
        });
      }
    }
  }

  void _init() {
    _repository.authStateChanges.listen((user) async {
      if (user != null) {
        try {
          // Listen to the stream instead of a one-time get so that status changes
          // reflect immediately in the AuthState.
          _repository.watchStudentProfile(user.uid).listen((student) {
            // Ignore updates if registration is still writing the document
            if (_registrationInProgress) return;
            if (student != null) {
              if (student.status == 'ACTIVE') {
                state = state.copyWith(
                  isAuthenticated: true,
                  student: student,
                  clearPendingStudent: true,
                  isLoading: false,
                );
              } else if (student.status == 'PENDING' || student.status == 'RETURNED') {
                // Account exists but status is PENDING or RETURNED.
                // We keep them "authenticated" internally but track them via pendingStudent
                // so the router can send them to the pending screen.
                state = state.copyWith(
                  isAuthenticated: true,
                  pendingStudent: student,
                  clearStudent: true,
                  isLoading: false,
                );
              } else {
                 // Other states like SUSPENDED, INACTIVE
                 state = state.copyWith(
                  isAuthenticated: false,
                  clearStudent: true,
                  clearPendingStudent: true,
                  isLoading: false,
                );
              }
            } else {
               // Null doc edge cases
               state = state.copyWith(
                 isAuthenticated: false,
                 clearStudent: true,
                 clearPendingStudent: true,
                 isLoading: false,
               );
            }
          }, onError: (e) {
            state = state.copyWith(
              isAuthenticated: false,
              errorMessage: 'Failed to load profile: $e',
              clearStudent: true,
              clearPendingStudent: true,
              isLoading: false,
            );
          });

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
          clearStudent: true,
          clearPendingStudent: true,
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

  Future<void> logout() async {
    await _repository.logout();
    await _appDatabase.clearAllData();
  }


}
