import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/student_model.dart';
import '../repositories/auth_repository.dart';
import '../../../core/exceptions/app_exception.dart';
import '../../../core/local/app_database.dart';

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
    bool clearStudent = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage,
      student: clearStudent ? null : (student ?? this.student),
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

  void _init() {
    _repository.authStateChanges.listen((user) async {
      if (user != null) {
        try {
          _repository.watchStudentProfile(user.uid).listen((student) {
            debugPrint('=== AUTH PROFILE STREAM: uid=${user.uid}, email=${user.email}, student=${student?.firstName} ${student?.lastName}, status=${student?.status} ===');
            if (student != null) {
              final statusUpper = student.status.trim().toUpperCase();
              if (statusUpper == 'ACTIVE') {
                state = state.copyWith(
                  isAuthenticated: true,
                  student: student,
                  isLoading: false,
                );
              } else {
                state = state.copyWith(
                  isAuthenticated: false,
                  errorMessage: 'Account status is ${student.status}. Please visit the SAO office.',
                  clearStudent: true,
                  isLoading: false,
                );
              }
            } else if (!user.isAnonymous) {
              debugPrint('=== AUTH PROFILE STREAM: No student doc found for UID ${user.uid} ===');
              state = state.copyWith(
                isAuthenticated: false,
                errorMessage: 'No student record found for this account. Please visit the SAO or Registrar.',
                clearStudent: true,
                isLoading: false,
              );
            }
          }, onError: (e) {
            debugPrint('=== AUTH PROFILE STREAM ERROR: $e ===');
            state = state.copyWith(
              isAuthenticated: false,
              errorMessage: 'Failed to load profile: $e',
              clearStudent: true,
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
        try {
          await _appDatabase.clearAllData();
        } catch (e) {
          debugPrint('Error purging local database on auth state change (logged out): $e');
        }
        state = state.copyWith(
          isAuthenticated: false,
          clearStudent: true,
          isLoading: false,
        );
      }
    });
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repository.login(email, password);
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'An unexpected error occurred.',
      );
    }
  }

  Future<void> logout() async {
    try {
      await _appDatabase.clearAllData();
    } catch (e) {
      debugPrint('Error purging local database on logout: $e');
    }
    await _repository.logout();
  }

  Future<void> updateProfile({
    String? contactNumber,
    String? profilePhotoUrl,
  }) async {
    final currentStudent = state.student;
    if (currentStudent == null) return;

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final updates = <String, dynamic>{};
      if (contactNumber != null) updates['contactNumber'] = contactNumber;
      if (profilePhotoUrl != null) updates['profilePhotoUrl'] = profilePhotoUrl;

      if (updates.isNotEmpty) {
        await _repository.updateStudentProfile(currentStudent.id, updates);
      }
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }
}
