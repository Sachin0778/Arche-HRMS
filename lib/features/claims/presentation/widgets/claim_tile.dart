import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../domain/entities/expense_claim.dart';
import 'claim_status_chip.dart';

IconData categoryIcon(ClaimCategory category) => switch (category) {
      ClaimCategory.travel => Icons.directions_car_outlined,
      ClaimCategory.food => Icons.restaurant_outlined,
      ClaimCategory.accommodation => Icons.hotel_outlined,
      ClaimCategory.other => Icons.receipt_long_outlined,
    };

class ClaimTile extends StatelessWidget {
  const ClaimTile({super.key, required this.claim, this.onTap, this.onLongPress});

  final ExpenseClaim claim;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      onLongPress: onLongPress,
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primaryContainer,
        foregroundColor: theme.colorScheme.onPrimaryContainer,
        child: Icon(categoryIcon(claim.category)),
      ),
      title: Text(claim.description, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text('${claim.category.label} · ${Formatters.date(claim.expenseDate)}'),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(Formatters.currency(claim.amount),
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          ClaimStatusChip(status: claim.status),
        ],
      ),
    );
  }
}