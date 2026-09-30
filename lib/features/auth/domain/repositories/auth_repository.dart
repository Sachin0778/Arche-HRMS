import '../../../employees/domain/entities/employee.dart';

class InvalidCredentialsException implements Exception {
  const InvalidCredentialsException();

  @override
  String toString() => 'Invalid employee ID or password';
}

abstract class AuthRepository {
  /// Returns the logged-in employee, or `null` when no session is stored.
  Future<Employee?> currentUser();

  /// Validates against the local credential list and persists the session.
  /// Throws [InvalidCredentialsException] on failure.
  Future<Employee> login({required String employeeId, required String password});

  Future<void> logout();
}