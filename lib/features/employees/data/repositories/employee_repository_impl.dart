import '../../domain/entities/employee.dart';
import '../../domain/repositories/employee_repository.dart';
import '../datasources/employee_local_data_source.dart';

class EmployeeRepositoryImpl implements EmployeeRepository {
  EmployeeRepositoryImpl(this._local);

  final EmployeeLocalDataSource _local;

  @override
  Stream<List<Employee>> watchAll() => _local.watchAll().map(_sorted);

  @override
  Future<List<Employee>> getAll() async => _sorted(_local.readAll());

  @override
  Future<Employee?> getById(String id) async => _local.readById(id);

  @override
  Future<List<String>> getDepartments() async {
    final departments = _local.readAll().map((e) => e.department).toSet().toList()..sort();
    return departments;
  }

  List<Employee> _sorted(List<Employee> list) =>
      [...list]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
}