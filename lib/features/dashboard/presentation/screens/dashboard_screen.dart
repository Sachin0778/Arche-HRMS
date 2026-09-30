import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/initials_avatar.dart';
import '../../../../core/widgets/stat_card.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../claims/presentation/screens/claim_detail_screen.dart';
import '../../../claims/presentation/screens/submit_claim_screen.dart';
import '../../../claims/presentation/widgets/claim_tile.dart';
import '../cubit/dashboard_cubit.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.onOpenDirectory, required this.onOpenClaims});

  final VoidCallback onOpenDirectory;
  final VoidCallback onOpenClaims;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.select((AuthCubit c) => c.state.user);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
      body: BlocBuilder<DashboardCubit, DashboardState>(
        builder: (context, state) {
          if (state.status == DashboardStatus.failure) {
            return ErrorState(
              message: state.errorMessage ?? 'Unknown error',
              onRetry: () => context.read<DashboardCubit>().load(),
            );
          }
          if (state.status == DashboardStatus.initial || state.status == DashboardStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  InitialsAvatar(name: user?.name ?? '?', radius: 26),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${Formatters.greeting(DateTime.now())},',
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                        Text(user?.name ?? 'there',
                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                        if (user != null)
                          Text('${user.designation} · ${user.department}', style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      label: 'Employees',
                      value: '${state.totalEmployees}',
                      icon: Icons.groups_outlined,
                      onTap: onOpenDirectory,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      label: 'Pending claims',
                      value: '${state.pendingClaims}',
                      icon: Icons.hourglass_top_rounded,
                      color: const Color(0xFFE59A00),
                      onTap: onOpenClaims,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              StatCard(
                label: 'Approved in ${Formatters.monthYear(DateTime.now())}',
                value: Formatters.currency(state.approvedThisMonth),
                icon: Icons.verified_outlined,
                color: const Color(0xFF1B9E5A),
                onTap: onOpenClaims,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).push(SubmitClaimScreen.route()),
                icon: const Icon(Icons.add),
                label: const Text('Submit an expense claim'),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Recent claims', style: theme.textTheme.titleMedium),
                  TextButton(onPressed: onOpenClaims, child: const Text('See all')),
                ],
              ),
              if (state.recentClaims.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text('You have not submitted any claims yet.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                )
              else
                Card(
                  child: Column(
                    children: [
                      for (var i = 0; i < state.recentClaims.length; i++) ...[
                        if (i > 0) const Divider(height: 1, indent: 72),
                        ClaimTile(
                          claim: state.recentClaims[i],
                          onTap: () => Navigator.of(context)
                              .push(ClaimDetailScreen.route(context, state.recentClaims[i].id)),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final cubit = context.read<AuthCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('Your claims and directory data stay saved on this device.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Sign out')),
        ],
      ),
    );
    if (confirmed == true) await cubit.logout();
  }
}