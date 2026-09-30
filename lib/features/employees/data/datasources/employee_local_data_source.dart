import 'package:hive/hive.dart';

import '../../domain/entities/employee.dart';
import '../models/employee_model.dart';
import 'employee_seed.dart';

/// Thin wrapper around the Hive box that stores employees. Only this class
/// knows the box layout; everything above works with [Employee] entities.
class EmployeeLocalDataSource {
  EmployeeLocalDataSource(this._box);

  static const String boxName = 'employees';

  final Box<Map> _box;

  /// Populates the box on first launch so the directory is never empty.
  Future<void> seedIfEmpty() async {
    if (_box.isNotEmpty) return;
    final entries = {for (final e in EmployeeSeed.build()) e.id: EmployeeModel.toMap(e)};
    await _box.putAll(entries);
  }

  List<Employee> readAll() => _box.values.map(EmployeeModel.fromMap).toList();

  Employee? readById(String id) {
    final raw = _box.get(id);
    return raw == null ? null : EmployeeModel.fromMap(raw);
  }

  /// Emits the current list immediately, then again on every box change.
  Stream<List<Employee>> watchAll() async* {
    yield readAll();
    yield* _box.watch().map((_) => readAll());
  }
}