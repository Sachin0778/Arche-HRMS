import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../claims/domain/repositories/claim_repository.dart';
import '../../../claims/presentation/cubit/claims_cubit.dart';
import '../../../claims/presentation/screens/my_claims_screen.dart';
import '../../../dashboard/presentation/cubit/dashboard_cubit.dart';
import '../../../dashboard/presentation/screens/dashboard_screen.dart';
import '../../../employees/domain/repositories/employee_repository.dart';
import '../../../employees/presentation/cubit/employee_directory_cubit.dart';
import '../../../employees/presentation/screens/employee_directory_screen.dart';

/// Signed-in shell: owns the per-session cubits and the bottom navigation.
/// The cubits are created here (not in main) so they are scoped to the
/// logged-in user and disposed on sign-out.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthCubit>().state.user!;
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => DashboardCubit(
            context.read<EmployeeRepository>(),
            context.read<ClaimRepository>(),
            employeeId: user.id,
          )..load(),
        ),
        BlocProvider(
          create: (context) => EmployeeDirectoryCubit(context.read<EmployeeRepository>())..load(),
        ),
        BlocProvider(
          create: (context) => ClaimsCubit(context.read<ClaimRepository>(), employeeId: user.id)..load(),
        ),
      ],
      child: Scaffold(
        body: IndexedStack(
          index: _index,
          children: [
            DashboardScreen(
              onOpenDirectory: () => setState(() => _index = 1),
              onOpenClaims: () => setState(() => _index = 2),
            ),
            const EmployeeDirectoryScreen(),
            const MyClaimsScreen(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
            NavigationDestination(
                icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'Directory'),
            NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Claims'),
          ],
        ),
      ),
    );
  }
}