import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/error_state.dart';
import '../../domain/entities/expense_claim.dart';
import '../cubit/claims_cubit.dart';
import '../widgets/claim_admin_sheet.dart';
import '../widgets/claim_status_chip.dart';
import '../widgets/claim_tile.dart';

/// Reads the claim from [ClaimsCubit] so status changes made here (or from
/// the list) are reflected immediately without a manual refresh.
class ClaimDetailScreen extends StatelessWidget {
  const ClaimDetailScreen({super.key, required this.claimId});

  final String claimId;

  /// [ClaimsCubit] is created in the home shell, *below* the root navigator,
  /// so a pushed route cannot look it up. Capture it from the caller's
  /// [context] and re-provide it to the new page.
  static Route<void> route(BuildContext context, String claimId) {
    final cubit = context.read<ClaimsCubit>();
    return MaterialPageRoute(
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: ClaimDetailScreen(claimId: claimId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ClaimsCubit, ClaimsState, ExpenseClaim?>(
      selector: (state) => state.claims.where((c) => c.id == claimId).firstOrNull,
      builder: (context, claim) {
        if (claim == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Claim')),
            body: const ErrorState(message: 'This claim no longer exists.'),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: const Text('Claim Detail'),
            actions: [
              IconButton(
                tooltip: 'Simulate review',
                icon: const Icon(Icons.admin_panel_settings_outlined),
                onPressed: () => _simulateReview(context, claim),
              ),
            ],
          ),
          body: _ClaimDetailBody(claim: claim),
        );
      },
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

class _ClaimDetailBody extends StatelessWidget {
  const _ClaimDetailBody({required this.claim});

  final ExpenseClaim claim;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(Formatters.currency(claim.amount),
                  style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
            ),
            ClaimStatusChip(status: claim.status, large: true),
          ],
        ),
        const SizedBox(height: 4),
        Text(claim.description, style: theme.textTheme.bodyLarge),
        const SizedBox(height: 20),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: Icon(categoryIcon(claim.category)),
                title: const Text('Category'),
                subtitle: Text(claim.category.label),
              ),
              ListTile(
                leading: const Icon(Icons.event_outlined),
                title: const Text('Expense date'),
                subtitle: Text(Formatters.date(claim.expenseDate)),
              ),
              ListTile(
                leading: const Icon(Icons.schedule_outlined),
                title: const Text('Submitted'),
                subtitle: Text(Formatters.dateTime(claim.submittedAt)),
              ),
              if (claim.reviewedAt != null)
                ListTile(
                  leading: const Icon(Icons.fact_check_outlined),
                  title: Text(claim.status == ClaimStatus.approved ? 'Approved' : 'Rejected'),
                  subtitle: Text(Formatters.dateTime(claim.reviewedAt!)),
                ),
              ListTile(
                leading: const Icon(Icons.tag),
                title: const Text('Reference'),
                subtitle: Text(claim.id),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text('Receipt', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        _ReceiptPreview(path: claim.receiptPath),
      ],
    );
  }
}

class _ReceiptPreview extends StatelessWidget {
  const _ReceiptPreview({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final file = File(path);
    if (path.isEmpty || !file.existsSync()) {
      return Container(
        height: 140,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported_outlined, color: theme.colorScheme.outline),
            const SizedBox(height: 8),
            Text(path.isEmpty ? 'No receipt attached (seeded demo claim)' : 'Receipt file is missing',
                style: theme.textTheme.bodySmall),
          ],
        ),
      );
    }
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Receipt')),
          body: Center(child: InteractiveViewer(child: Image.file(file))),
        ),
      )),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(file, width: double.infinity, height: 260, fit: BoxFit.cover),
      ),
    );
  }
}