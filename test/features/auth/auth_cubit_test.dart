import 'package:flutter_test/flutter_test.dart';
import 'package:hrms/features/auth/domain/repositories/auth_repository.dart';
import 'package:hrms/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:hrms/features/employees/domain/entities/employee.dart';

import '../../helpers/fakes.dart';

class _FakeAuthRepository implements AuthRepository {
  Employee? session;

  @override
  Future<Employee?> currentUser() async => session;

  @override
  Future<Employee> login({required String employeeId, required String password}) async {
    if (employeeId == 'emp001' && password == 'password123') {
      return session = employee('emp001');
    }
    throw const InvalidCredentialsException();
  }

  @override
  Future<void> logout() async => session = null;
}

void main() {
  test('restoreSession lands on unauthenticated when nothing is stored', () async {
    final cubit = AuthCubit(_FakeAuthRepository());
    await cubit.restoreSession();
    expect(cubit.state.status, AuthStatus.unauthenticated);
  });

  test('restoreSession restores a persisted user', () async {
    final repo = _FakeAuthRepository()..session = employee('emp001');
    final cubit = AuthCubit(repo);
    await cubit.restoreSession();
    expect(cubit.state.status, AuthStatus.authenticated);
    expect(cubit.state.user?.id, 'emp001');
  });

  test('login failure surfaces an error and stays unauthenticated', () async {
    final cubit = AuthCubit(_FakeAuthRepository());
    await cubit.restoreSession();
    await cubit.login(employeeId: 'emp001', password: 'wrong');
    expect(cubit.state.status, AuthStatus.unauthenticated);
    expect(cubit.state.errorMessage, isNotNull);
    expect(cubit.state.isSubmitting, isFalse);
  });

  test('login success then logout', () async {
    final cubit = AuthCubit(_FakeAuthRepository());
    await cubit.login(employeeId: 'emp001', password: 'password123');
    expect(cubit.state.status, AuthStatus.authenticated);
    await cubit.logout();
    expect(cubit.state.status, AuthStatus.unauthenticated);
    expect(cubit.state.user, isNull);
  });
}