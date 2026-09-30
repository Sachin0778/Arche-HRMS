import '../../../employees/domain/entities/employee.dart';
import '../../../employees/domain/repositories/employee_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._local, this._employees);

  final AuthLocalDataSource _local;
  final EmployeeRepository _employees;

  @override
  Future<Employee?> currentUser() async {
    final id = _local.currentUserId;
    if (id == null) return null;
    final employee = await _employees.getById(id);
    if (employee == null) {
      // Session points at an employee that no longer exists; drop it.
      await _local.clearSession();
    }
    return employee;
  }

  @override
  Future<Employee> login({required String employeeId, required String password}) async {
    final id = employeeId.trim().toLowerCase();
    if (!_local.verify(id, password)) {
      throw const InvalidCredentialsException();
    }
    final employee = await _employees.getById(id);
    if (employee == null) {
      throw const InvalidCredentialsException();
    }
    await _local.saveSession(id);
    return employee;
  }

  @override
  Future<void> logout() => _local.clearSession();
}