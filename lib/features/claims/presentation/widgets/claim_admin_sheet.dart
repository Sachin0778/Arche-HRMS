import 'package:flutter/material.dart';

import '../../domain/entities/expense_claim.dart';
import 'claim_status_chip.dart';

/// Demo-only "admin" actions. Long-press a claim (or use the menu on the
/// detail screen) to simulate a manager approving or rejecting it.
class ClaimAdminSheet extends StatelessWidget {
  const ClaimAdminSheet({super.key, required this.claim});

  final ExpenseClaim claim;

  /// Returns the chosen status, or `null` when dismissed.
  static Future<ClaimStatus?> show(BuildContext context, ExpenseClaim claim) =>
      showModalBottomSheet<ClaimStatus>(
        context: context,
        showDragHandle: true,
        builder: (_) => ClaimAdminSheet(claim: claim),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget option(ClaimStatus status, String label) {
      final selected = claim.status == status;
      return ListTile(
        leading: Icon(ClaimStatusChip.iconFor(status), color: ClaimStatusChip.colorFor(status, theme.colorScheme)),
        title: Text(label),
        trailing: selected ? const Icon(Icons.check) : null,
        enabled: !selected,
        onTap: () => Navigator.of(context).pop(status),
      );
    }

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text('Simulate manager review', style: theme.textTheme.titleMedium),
            subtitle: const Text('Demo action. Dashboard stats update immediately.'),
          ),
          const Divider(height: 1),
          option(ClaimStatus.approved, 'Approve claim'),
          option(ClaimStatus.rejected, 'Reject claim'),
          option(ClaimStatus.pending, 'Reset to pending'),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}