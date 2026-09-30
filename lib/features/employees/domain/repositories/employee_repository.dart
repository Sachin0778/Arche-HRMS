import '../entities/employee.dart';

/// Contract the presentation layer depends on. The data layer provides a
/// Hive-backed implementation; tests can provide an in-memory fake.
abstract class EmployeeRepository {
  /// Emits the full employee list now and whenever it changes.
  Stream<List<Employee>> watchAll();

  Future<List<Employee>> getAll();

  Future<Employee?> getById(String id);

  /// Distinct department names, sorted alphabetically.
  Future<List<String>> getDepartments();
}