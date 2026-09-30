import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../claims/domain/entities/expense_claim.dart';
import '../../../claims/domain/repositories/claim_repository.dart';
import '../../../employees/domain/entities/employee.dart';
import '../../../employees/domain/repositories/employee_repository.dart';

part 'dashboard_state.dart';

/// Derives the quick stats from both repositories. Because it listens to the
/// repository streams, approving a claim anywhere in the app updates the
/// dashboard without any explicit refresh call.
class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit(
    this._employees,
    this._claims, {
    required this.employeeId,
    DateTime Function()? clock,
  })  : _clock = clock ?? DateTime.now,
        super(const DashboardState());

  final EmployeeRepository _employees;
  final ClaimRepository _claims;
  final String employeeId;
  final DateTime Function() _clock;

  StreamSubscription<List<Employee>>? _employeeSub;
  StreamSubscription<List<ExpenseClaim>>? _claimSub;

  void load() {
    emit(state.copyWith(status: DashboardStatus.loading));
    _employeeSub?.cancel();
    _claimSub?.cancel();
    _employeeSub = _employees.watchAll().listen(
      (list) => emit(state.copyWith(status: DashboardStatus.ready, totalEmployees: list.length)),
      onError: _fail,
    );
    _claimSub = _claims.watchAll().listen(
      (all) => emit(_withClaims(all)),
      onError: _fail,
    );
  }

  DashboardState _withClaims(List<ExpenseClaim> all) {
    final mine = all.where((c) => c.employeeId == employeeId).toList();
    final now = _clock();
    final approvedThisMonth = mine
        .where((c) =>
            c.status == ClaimStatus.approved &&
            c.reviewedAt != null &&
            c.reviewedAt!.year == now.year &&
            c.reviewedAt!.month == now.month)
        .fold<double>(0, (sum, c) => sum + c.amount);
    final recent = [...mine]..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
    return state.copyWith(
      status: DashboardStatus.ready,
      pendingClaims: mine.where((c) => c.status == ClaimStatus.pending).length,
      approvedThisMonth: approvedThisMonth,
      recentClaims: recent.take(3).toList(),
    );
  }

  void _fail(Object error) => emit(state.copyWith(
        status: DashboardStatus.failure,
        errorMessage: 'Could not load dashboard: $error',
      ));

  @override
  Future<void> close() {
    _employeeSub?.cancel();
    _claimSub?.cancel();
    return super.close();
  }
}