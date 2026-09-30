import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../employees/domain/entities/employee.dart';
import '../../domain/repositories/auth_repository.dart';

part 'auth_state.dart';

/// App-wide session state. Restores a persisted login on start so the user
/// lands on the dashboard after an app restart.
class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._repository) : super(const AuthState());

  final AuthRepository _repository;

  Future<void> restoreSession() async {
    final user = await _repository.currentUser();
    emit(user == null
        ? const AuthState(status: AuthStatus.unauthenticated)
        : AuthState(status: AuthStatus.authenticated, user: user));
  }

  Future<void> login({required String employeeId, required String password}) async {
    emit(state.copyWith(isSubmitting: true, clearError: true));
    try {
      final user = await _repository.login(employeeId: employeeId, password: password);
      emit(AuthState(status: AuthStatus.authenticated, user: user));
    } on InvalidCredentialsException catch (e) {
      emit(state.copyWith(isSubmitting: false, errorMessage: e.toString()));
    } catch (_) {
      emit(state.copyWith(isSubmitting: false, errorMessage: 'Could not sign in. Please try again.'));
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }
}