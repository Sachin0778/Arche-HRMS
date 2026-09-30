import 'package:flutter_test/flutter_test.dart';
import 'package:hrms/features/claims/domain/entities/expense_claim.dart';
import 'package:hrms/features/dashboard/presentation/cubit/dashboard_cubit.dart';

import '../../helpers/fakes.dart';

void main() {
  final now = DateTime(2026, 9, 29);

  test('computes stats for the signed-in employee and reacts to approvals', () async {
    final employees = FakeEmployeeRepository([employee('emp001'), employee('emp002'), employee('emp003')]);
    final claims = FakeClaimRepository([
      claim('p1', status: ClaimStatus.pending, amount: 100),
      claim('p2', status: ClaimStatus.pending, amount: 200),
      claim('a1', status: ClaimStatus.approved, amount: 1000, reviewedAt: DateTime(2026, 9, 3)),
      claim('a-old', status: ClaimStatus.approved, amount: 5000, reviewedAt: DateTime(2026, 8, 30)),
      claim('r1', status: ClaimStatus.rejected, amount: 50, reviewedAt: DateTime(2026, 9, 5)),
      claim('theirs', employeeId: 'emp002', status: ClaimStatus.pending),
    ]);
    final cubit = DashboardCubit(employees, claims, employeeId: 'emp001', clock: () => now)..load();
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.status, DashboardStatus.ready);
    expect(cubit.state.totalEmployees, 3);
    expect(cubit.state.pendingClaims, 2);
    expect(cubit.state.approvedThisMonth, 1000);
    expect(cubit.state.recentClaims.length, 3);

    // Approving a pending claim should move it into this month's total.
    await claims.updateStatus('p1', ClaimStatus.approved);
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.pendingClaims, 1);
    expect(cubit.state.approvedThisMonth, 1100);

    await cubit.close();
  });
}