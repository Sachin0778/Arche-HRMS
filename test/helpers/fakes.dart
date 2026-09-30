import 'dart:async';
import 'dart:io';

import 'package:hrms/features/claims/data/datasources/receipt_file_store.dart';
import 'package:hrms/features/claims/domain/entities/expense_claim.dart';
import 'package:hrms/features/claims/domain/repositories/claim_repository.dart';
import 'package:hrms/features/employees/domain/entities/employee.dart';
import 'package:hrms/features/employees/domain/repositories/employee_repository.dart';

/// In-memory repository doubles that mimic the "emit now, then on change"
/// contract of the Hive-backed implementations.
class FakeEmployeeRepository implements EmployeeRepository {
  FakeEmployeeRepository(this._employees);

  List<Employee> _employees;
  final _controller = StreamController<List<Employee>>.broadcast();

  void replace(List<Employee> employees) {
    _employees = employees;
    _controller.add(_employees);
  }

  @override
  Stream<List<Employee>> watchAll() async* {
    yield _employees;
    yield* _controller.stream;
  }

  @override
  Future<List<Employee>> getAll() async => _employees;

  @override
  Future<Employee?> getById(String id) async => _employees.where((e) => e.id == id).firstOrNull;

  @override
  Future<List<String>> getDepartments() async => _employees.map((e) => e.department).toSet().toList()..sort();
}

class FakeClaimRepository implements ClaimRepository {
  FakeClaimRepository([List<ExpenseClaim> seed = const []]) : _claims = {for (final c in seed) c.id: c};

  final Map<String, ExpenseClaim> _claims;
  final _controller = StreamController<List<ExpenseClaim>>.broadcast();
  final DateTime reviewClock = DateTime(2026, 9, 15, 10);

  List<ExpenseClaim> get current => _claims.values.toList();

  void _notify() => _controller.add(current);

  @override
  Stream<List<ExpenseClaim>> watchAll() async* {
    yield current;
    yield* _controller.stream;
  }

  @override
  Future<List<ExpenseClaim>> getAll() async => current;

  @override
  Future<ExpenseClaim?> getById(String id) async => _claims[id];

  @override
  Future<void> submit(ExpenseClaim claim) async {
    _claims[claim.id] = claim;
    _notify();
  }

  @override
  Future<void> updateStatus(String id, ClaimStatus status) async {
    final existing = _claims[id];
    if (existing == null) throw StateError('missing');
    _claims[id] = status == ClaimStatus.pending
        ? existing.copyWith(status: status, clearReviewedAt: true)
        : existing.copyWith(status: status, reviewedAt: reviewClock);
    _notify();
  }

  @override
  Future<void> delete(String id) async {
    _claims.remove(id);
    _notify();
  }
}

/// Persists receipts into a temp directory that the test owns.
ReceiptFileStore tempReceiptStore(Directory dir) => ReceiptFileStore(baseDirectory: () async => dir);

Employee employee(String id, {String name = 'Test User', String department = 'Engineering', String? managerId}) =>
    Employee(
      id: id,
      name: name,
      designation: 'Engineer',
      department: department,
      email: '$id@example.com',
      phone: '000',
      dateOfJoining: DateTime(2020, 1, 1),
      managerId: managerId,
    );

ExpenseClaim claim(
  String id, {
  String employeeId = 'emp001',
  ClaimStatus status = ClaimStatus.pending,
  double amount = 100,
  DateTime? expenseDate,
  DateTime? reviewedAt,
  String description = 'Test expense',
  ClaimCategory category = ClaimCategory.travel,
}) =>
    ExpenseClaim(
      id: id,
      employeeId: employeeId,
      category: category,
      amount: amount,
      expenseDate: expenseDate ?? DateTime(2026, 9, 1),
      description: description,
      receiptPath: '',
      status: status,
      submittedAt: expenseDate ?? DateTime(2026, 9, 1),
      reviewedAt: reviewedAt,
    );