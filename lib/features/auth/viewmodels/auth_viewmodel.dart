import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/student_model.dart';
import '../repositories/auth_repository.dart';
import '../../../core/exceptions/app_exception.dart';

/// State for Authentication
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
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
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

  void _init() {
    _repository.authStateChanges.listen((user) async {
      if (user != null) {
        // Fetch student profile when user is logged in
        try {
          final student = await _repository.getStudentProfile(user.uid);
          state = state.copyWith(
            isAuthenticated: true,
            student: student,
            isLoading: false,
          );
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
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.login(email, password);
      // Auth state listener will handle the rest
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'An unexpected error occurred');
    }
  }

  Future<void> logout() async {
    await _repository.logout();
  }
}
