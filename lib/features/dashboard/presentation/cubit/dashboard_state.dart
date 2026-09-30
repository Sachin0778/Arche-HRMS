part of 'dashboard_cubit.dart';

enum DashboardStatus { initial, loading, ready, failure }

class DashboardState extends Equatable {
  const DashboardState({
    this.status = DashboardStatus.initial,
    this.totalEmployees = 0,
    this.pendingClaims = 0,
    this.approvedThisMonth = 0,
    this.recentClaims = const [],
    this.errorMessage,
  });

  final DashboardStatus status;
  final int totalEmployees;

  /// Pending claims for the signed-in employee.
  final int pendingClaims;

  /// Sum of the signed-in employee's claims approved in the current month.
  final double approvedThisMonth;
  final List<ExpenseClaim> recentClaims;
  final String? errorMessage;

  DashboardState copyWith({
    DashboardStatus? status,
    int? totalEmployees,
    int? pendingClaims,
    double? approvedThisMonth,
    List<ExpenseClaim>? recentClaims,
    String? errorMessage,
  }) {
    return DashboardState(
      status: status ?? this.status,
      totalEmployees: totalEmployees ?? this.totalEmployees,
      pendingClaims: pendingClaims ?? this.pendingClaims,
      approvedThisMonth: approvedThisMonth ?? this.approvedThisMonth,
      recentClaims: recentClaims ?? this.recentClaims,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [status, totalEmployees, pendingClaims, approvedThisMonth, recentClaims, errorMessage];
}