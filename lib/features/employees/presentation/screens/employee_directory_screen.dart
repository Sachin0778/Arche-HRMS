import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../cubit/employee_directory_cubit.dart';
import '../widgets/employee_tile.dart';
import 'employee_detail_screen.dart';

class EmployeeDirectoryScreen extends StatelessWidget {
  const EmployeeDirectoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Employee Directory')),
      body: Column(
        children: [
          const _SearchAndFilterBar(),
          Expanded(
            child: BlocBuilder<EmployeeDirectoryCubit, EmployeeDirectoryState>(
              builder: (context, state) {
                switch (state.status) {
                  case DirectoryStatus.initial:
                  case DirectoryStatus.loading:
                    return const Center(child: CircularProgressIndicator());
                  case DirectoryStatus.failure:
                    return ErrorState(
                      message: state.errorMessage ?? 'Unknown error',
                      onRetry: () => context.read<EmployeeDirectoryCubit>().load(),
                    );
                  case DirectoryStatus.ready:
                    final items = state.filtered;
                    if (items.isEmpty) {
                      return EmptyState(
                        icon: Icons.person_search_outlined,
                        title: state.hasActiveFilter ? 'No matching colleagues' : 'No employees yet',
                        message: state.hasActiveFilter
                            ? 'Try a different name or clear the department filter.'
                            : 'The directory is empty.',
                        action: state.hasActiveFilter
                            ? TextButton(
                                onPressed: () => context.read<EmployeeDirectoryCubit>().clearFilters(),
                                child: const Text('Clear filters'),
                              )
                            : null,
                      );
                    }
                    return ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
                      itemBuilder: (context, index) {
                        final employee = items[index];
                        return EmployeeTile(
                          employee: employee,
                          onTap: () => Navigator.of(context).push(
                            EmployeeDetailScreen.route(employee.id),
                          ),
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
}

class _SearchAndFilterBar extends StatelessWidget {
  const _SearchAndFilterBar();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<EmployeeDirectoryCubit>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        children: [
          BlocBuilder<EmployeeDirectoryCubit, EmployeeDirectoryState>(
            buildWhen: (p, c) => p.query != c.query,
            builder: (context, state) {
              return TextField(
                onChanged: cubit.search,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search by name',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: state.query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            cubit.search('');
                            FocusScope.of(context).unfocus();
                          },
                        ),
                  isDense: true,
                ),
                controller: _SearchController.of(context, state.query),
              );
            },
          ),
          const SizedBox(height: 8),
          BlocBuilder<EmployeeDirectoryCubit, EmployeeDirectoryState>(
            buildWhen: (p, c) => p.departments != c.departments || p.department != c.department,
            builder: (context, state) {
              if (state.departments.isEmpty) return const SizedBox.shrink();
              return SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: const Text('All'),
                        selected: state.department == null,
                        onSelected: (_) => cubit.selectDepartment(null),
                      ),
                    ),
                    for (final dept in state.departments)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(dept),
                          selected: state.department == dept,
                          onSelected: (selected) => cubit.selectDepartment(selected ? dept : null),
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

/// Keeps a single TextEditingController in sync with cubit state so the
/// clear button can reset the field without the widget owning the text.
class _SearchController {
  static final _controllers = Expando<TextEditingController>();

  static TextEditingController of(BuildContext context, String query) {
    final cubit = context.read<EmployeeDirectoryCubit>();
    final controller = _controllers[cubit] ??= TextEditingController();
    if (controller.text != query) {
      controller.value = controller.value.copyWith(
        text: query,
        selection: TextSelection.collapsed(offset: query.length),
      );
    }
    return controller;
  }
}