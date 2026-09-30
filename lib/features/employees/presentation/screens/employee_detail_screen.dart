import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/initials_avatar.dart';
import '../../domain/entities/employee.dart';
import '../../domain/repositories/employee_repository.dart';

class EmployeeDetailScreen extends StatelessWidget {
  const EmployeeDetailScreen({super.key, required this.employeeId});

  final String employeeId;

  static Route<void> route(String employeeId) =>
      MaterialPageRoute(builder: (_) => EmployeeDetailScreen(employeeId: employeeId));

  @override
  Widget build(BuildContext context) {
    final repository = context.read<EmployeeRepository>();
    return Scaffold(
      appBar: AppBar(title: const Text('Employee')),
      body: FutureBuilder<_EmployeeWithManager>(
        future: _EmployeeWithManager.load(repository, employeeId),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ErrorState(message: snapshot.error.toString());
          }
          final data = snapshot.data;
          if (data == null || data.employee == null) {
            return const ErrorState(message: 'This employee record could not be found.');
          }
          return _EmployeeDetailBody(employee: data.employee!, manager: data.manager);
        },
      ),
    );
  }
}

class _EmployeeWithManager {
  const _EmployeeWithManager(this.employee, this.manager);

  final Employee? employee;
  final Employee? manager;

  static Future<_EmployeeWithManager> load(EmployeeRepository repo, String id) async {
    final employee = await repo.getById(id);
    final managerId = employee?.managerId;
    final manager = managerId == null ? null : await repo.getById(managerId);
    return _EmployeeWithManager(employee, manager);
  }
}

class _EmployeeDetailBody extends StatelessWidget {
  const _EmployeeDetailBody({required this.employee, this.manager});

  final Employee employee;
  final Employee? manager;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: Hero(tag: 'avatar-${employee.id}', child: InitialsAvatar(name: employee.name, radius: 44)),
        ),
        const SizedBox(height: 16),
        Text(employee.name,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('${employee.designation} · ${employee.department}',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 24),
        _Section(
          title: 'Contact',
          children: [
            _InfoRow(icon: Icons.mail_outline, label: 'Email', value: employee.email, copyable: true),
            _InfoRow(icon: Icons.phone_outlined, label: 'Phone', value: employee.phone, copyable: true),
          ],
        ),
        const SizedBox(height: 16),
        _Section(
          title: 'Employment',
          children: [
            _InfoRow(icon: Icons.badge_outlined, label: 'Employee ID', value: employee.id.toUpperCase()),
            _InfoRow(
              icon: Icons.event_outlined,
              label: 'Date of joining',
              value: Formatters.date(employee.dateOfJoining),
            ),
            if (manager != null)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: InitialsAvatar(name: manager!.name, radius: 18),
                title: const Text('Reporting manager'),
                subtitle: Text('${manager!.name} · ${manager!.designation}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(EmployeeDetailScreen.route(manager!.id)),
              )
            else
              const _InfoRow(
                icon: Icons.account_tree_outlined,
                label: 'Reporting manager',
                value: 'None (top of org chart)',
              ),
          ],
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value, this.copyable = false});

  final IconData icon;
  final String label;
  final String value;
  final bool copyable;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(value),
      trailing: copyable ? const Icon(Icons.copy_outlined, size: 18) : null,
      onTap: copyable
          ? () async {
              await Clipboard.setData(ClipboardData(text: value));
              if (context.mounted) {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(content: Text('$label copied')));
              }
            }
          : null,
    );
  }
}