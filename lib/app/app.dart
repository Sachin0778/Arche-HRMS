import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/theme/app_theme.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/presentation/cubit/auth_cubit.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/claims/data/datasources/receipt_file_store.dart';
import '../features/claims/domain/repositories/claim_repository.dart';
import '../features/employees/domain/repositories/employee_repository.dart';
import '../features/home/presentation/screens/home_shell.dart';
import 'app_dependencies.dart';

class HrmsApp extends StatelessWidget {
  const HrmsApp({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>.value(value: dependencies.authRepository),
        RepositoryProvider<EmployeeRepository>.value(value: dependencies.employeeRepository),
        RepositoryProvider<ClaimRepository>.value(value: dependencies.claimRepository),
        RepositoryProvider<ReceiptFileStore>.value(value: dependencies.receiptFileStore),
      ],
      child: BlocProvider(
        create: (context) => AuthCubit(context.read<AuthRepository>())..restoreSession(),
        child: MaterialApp(
          title: 'Arche HRMS',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.system,
          home: const _AuthGate(),
        ),
      ),
    );
  }
}

/// Swaps between login and the signed-in shell based on [AuthCubit].
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final status = context.select((AuthCubit c) => c.state.status);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: switch (status) {
        AuthStatus.unknown => const Scaffold(body: Center(child: CircularProgressIndicator())),
        AuthStatus.unauthenticated => const LoginScreen(),
        AuthStatus.authenticated => const HomeShell(),
      },
    );
  }
}