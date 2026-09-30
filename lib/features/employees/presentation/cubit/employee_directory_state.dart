part of 'employee_directory_cubit.dart';

enum DirectoryStatus { initial, loading, ready, failure }

class EmployeeDirectoryState extends Equatable {
  const EmployeeDirectoryState({
    this.status = DirectoryStatus.initial,
    this.employees = const [],
    this.departments = const [],
    this.query = '',
    this.department,
    this.errorMessage,
  });

  final DirectoryStatus status;
  final List<Employee> employees;
  final List<String> departments;
  final String query;

  /// `null` means "All departments".
  final String? department;
  final String? errorMessage;

  /// Search + filter applied. Kept here (not in the widget) so the UI stays
  /// declarative and the logic is unit-testable.
  List<Employee> get filtered {
    final q = query.trim().toLowerCase();
    return employees.where((e) {
      final matchesDept = department == null || e.department == department;
      final matchesQuery = q.isEmpty || e.name.toLowerCase().contains(q);
      return matchesDept && matchesQuery;
    }).toList();
  }

  bool get hasActiveFilter => query.trim().isNotEmpty || department != null;

  EmployeeDirectoryState copyWith({
    DirectoryStatus? status,
    List<Employee>? employees,
    List<String>? departments,
    String? query,
    String? department,
    bool clearDepartment = false,
    String? errorMessage,
  }) {
    return EmployeeDirectoryState(
      status: status ?? this.status,
      employees: employees ?? this.employees,
      departments: departments ?? this.departments,
      query: query ?? this.query,
      department: clearDepartment ? null : (department ?? this.department),
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, employees, departments, query, department, errorMessage];
}