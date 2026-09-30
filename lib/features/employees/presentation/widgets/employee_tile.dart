import 'package:flutter/material.dart';

import '../../../../core/widgets/initials_avatar.dart';
import '../../domain/entities/employee.dart';

class EmployeeTile extends StatelessWidget {
  const EmployeeTile({super.key, required this.employee, this.onTap});

  final Employee employee;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      leading: Hero(
        tag: 'avatar-${employee.id}',
        child: InitialsAvatar(name: employee.name),
      ),
      title: Text(employee.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(employee.designation, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Chip(
        label: Text(employee.department, style: theme.textTheme.labelSmall),
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        side: BorderSide.none,
        backgroundColor: theme.colorScheme.secondaryContainer,
      ),
    );
  }
}