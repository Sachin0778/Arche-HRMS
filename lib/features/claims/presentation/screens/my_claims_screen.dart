import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../domain/entities/expense_claim.dart';
import '../cubit/claims_cubit.dart';
import '../widgets/claim_admin_sheet.dart';
import '../widgets/claim_tile.dart';
import 'claim_detail_screen.dart';
import 'submit_claim_screen.dart';

class MyClaimsScreen extends StatelessWidget {
  const MyClaimsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Claims'),
        actions: [
          BlocBuilder<ClaimsCubit, ClaimsState>(
            buildWhen: (p, c) => p.sortOrder != c.sortOrder,
            builder: (context, state) {
              final newest = state.sortOrder == ClaimSortOrder.newestFirst;
              return IconButton(
                tooltip: newest ? 'Newest first' : 'Oldest first',
                icon: Icon(newest ? Icons.arrow_downward : Icons.arrow_upward),
                onPressed: () => context.read<ClaimsCubit>().toggleSortOrder(),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'submit-claim-fab',
        onPressed: () => Navigator.of(context).push(SubmitClaimScreen.route()),
        icon: const Icon(Icons.add),
        label: const Text('New claim'),
      ),
      body: Column(
        children: [
          const _ClaimFilters(),
          Expanded(
            child: BlocBuilder<ClaimsCubit, ClaimsState>(
              builder: (context, state) {
                switch (state.status) {
                  case ClaimsStatus.initial:
                  case ClaimsStatus.loading:
                    return const Center(child: CircularProgressIndicator());
                  case ClaimsStatus.failure:
                    return ErrorState(
                      message: state.errorMessage ?? 'Unknown error',
                      onRetry: () => context.read<ClaimsCubit>().load(),
                    );
                  case ClaimsStatus.ready:
                    final items = state.visible;
                    if (items.isEmpty) {
                      return EmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: state.hasActiveFilter ? 'No claims match' : 'No claims yet',
                        message: state.hasActiveFilter
                            ? 'Try another status or search term.'
                            : 'Submit your first expense claim using the button below.',
                        action: state.hasActiveFilter
                            ? TextButton(
                                onPressed: () => context.read<ClaimsCubit>().clearFilters(),
                                child: const Text('Clear filters'),
                              )
                            : null,
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.only(bottom: 88),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
                      itemBuilder: (context, index) {
                        final claim = items[index];
                        return ClaimTile(
                          claim: claim,
                          onTap: () => Navigator.of(context).push(ClaimDetailScreen.route(context, claim.id)),
                          onLongPress: () => _simulateReview(context, claim),
                        );
                      },
                    );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _simulateReview(BuildContext context, ExpenseClaim claim) async {
    final cubit = context.read<ClaimsCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final status = await ClaimAdminSheet.show(context, claim);
    if (status == null) return;
    final error = await cubit.setStatus(claim.id, status);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(error ?? 'Claim marked as ${status.label.toLowerCase()}')));
  }
}

class _ClaimFilters extends StatelessWidget {
  const _ClaimFilters();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ClaimsCubit>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        children: [
          TextField(
            onChanged: cubit.search,
            decoration: const InputDecoration(
              hintText: 'Search description or category',
              prefixIcon: Icon(Icons.search),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          BlocBuilder<ClaimsCubit, ClaimsState>(
            buildWhen: (p, c) => p.statusFilter != c.statusFilter,
            builder: (context, state) {
              return SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: const Text('All'),
                        selected: state.statusFilter == null,
                        onSelected: (_) => cubit.filterByStatus(null),
                      ),
                    ),
                    for (final status in ClaimStatus.values)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(status.label),
                          selected: state.statusFilter == status,
                          onSelected: (sel) => cubit.filterByStatus(sel ? status : null),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}