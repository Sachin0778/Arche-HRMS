import 'package:flutter_test/flutter_test.dart';
import 'package:hrms/features/employees/presentation/cubit/employee_directory_cubit.dart';

import '../../helpers/fakes.dart';

void main() {
  late FakeEmployeeRepository repo;
  late EmployeeDirectoryCubit cubit;

  setUp(() {
    repo = FakeEmployeeRepository([
      employee('emp001', name: 'Sachin Shirake', department: 'Engineering'),
      employee('emp002', name: 'Sneha Pillai', department: 'Engineering'),
      employee('emp008', name: 'Neha Kapoor', department: 'Human Resources'),
    ]);
    cubit = EmployeeDirectoryCubit(repo);
  });

  tearDown(() => cubit.close());

  test('load emits ready with employees and sorted departments', () async {
    cubit.load();
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.status, DirectoryStatus.ready);
    expect(cubit.state.employees.length, 3);
    expect(cubit.state.departments, ['Engineering', 'Human Resources']);
  });

  test('search is case-insensitive and matches partial names', () async {
    cubit.load();
    await Future<void>.delayed(Duration.zero);
    cubit.search('neh');
    expect(cubit.state.filtered.map((e) => e.name), ['Neha Kapoor']);
  });

  test('department filter combines with search', () async {
    cubit.load();
    await Future<void>.delayed(Duration.zero);
    cubit.selectDepartment('Engineering');
    expect(cubit.state.filtered.length, 2);
    cubit.search('sneha');
    expect(cubit.state.filtered.map((e) => e.id), ['emp002']);
    cubit.clearFilters();
    expect(cubit.state.filtered.length, 3);
    expect(cubit.state.hasActiveFilter, isFalse);
  });

  test('reacts to repository changes', () async {
    cubit.load();
    await Future<void>.delayed(Duration.zero);
    repo.replace([employee('emp001', name: 'Only One')]);
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.employees.length, 1);
  });
}
