import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrms/features/auth/domain/repositories/auth_repository.dart';
import 'package:hrms/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:hrms/features/auth/presentation/screens/login_screen.dart';
import 'package:hrms/features/employees/domain/entities/employee.dart';

import '../../helpers/fakes.dart';

class _StubAuthRepository implements AuthRepository {
  int loginCalls = 0;

  @override
  Future<Employee?> currentUser() async => null;

  @override
  Future<Employee> login({required String employeeId, required String password}) async {
    loginCalls++;
    if (password == 'password123') return employee(employeeId);
    throw const InvalidCredentialsException();
  }

  @override
  Future<void> logout() async {}
}

Widget _harness(AuthCubit cubit) => MaterialApp(
      home: BlocProvider.value(value: cubit, child: const LoginScreen()),
    );

void main() {
  testWidgets('blocks submission with inline errors when fields are invalid', (tester) async {
    final repo = _StubAuthRepository();
    final cubit = AuthCubit(repo);
    addTearDown(cubit.close);
    await tester.pumpWidget(_harness(cubit));

    await tester.enterText(find.byType(TextFormField).first, '');
    await tester.tap(find.text('Sign in'));
    await tester.pump();

    expect(find.text('Employee ID is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
    expect(repo.loginCalls, 0);
  });

  testWidgets('shows a snackbar on wrong credentials and authenticates on correct ones', (tester) async {
    final repo = _StubAuthRepository();
    final cubit = AuthCubit(repo);
    addTearDown(cubit.close);
    await tester.pumpWidget(_harness(cubit));

    await tester.enterText(find.byType(TextFormField).last, 'wrongpass');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Invalid employee ID or password'), findsOneWidget);
    expect(cubit.state.status, isNot(AuthStatus.authenticated));

    await tester.enterText(find.byType(TextFormField).last, 'password123');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(cubit.state.status, AuthStatus.authenticated);
    expect(cubit.state.user?.id, 'emp001');
  });
}