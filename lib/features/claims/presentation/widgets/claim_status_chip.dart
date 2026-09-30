import 'package:flutter/material.dart';

import '../../domain/entities/expense_claim.dart';

class ClaimStatusChip extends StatelessWidget {
  const ClaimStatusChip({super.key, required this.status, this.large = false});

  final ClaimStatus status;
  final bool large;

  static Color colorFor(ClaimStatus status, ColorScheme scheme) => switch (status) {
        ClaimStatus.pending => const Color(0xFFE59A00),
        ClaimStatus.approved => const Color(0xFF1B9E5A),
        ClaimStatus.rejected => scheme.error,
      };

  static IconData iconFor(ClaimStatus status) => switch (status) {
        ClaimStatus.pending => Icons.hourglass_top_rounded,
        ClaimStatus.approved => Icons.check_circle_rounded,
        ClaimStatus.rejected => Icons.cancel_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final color = colorFor(status, Theme.of(context).colorScheme);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: large ? 12 : 8, vertical: large ? 6 : 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconFor(status), size: large ? 18 : 14, color: color),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: large ? 14 : 12),
          ),
        ],
      ),
    );
  }
}