import 'package:flutter_test/flutter_test.dart';
import 'package:hrms/features/claims/domain/entities/expense_claim.dart';
import 'package:hrms/features/claims/presentation/cubit/claims_cubit.dart';

import '../../helpers/fakes.dart';

void main() {
  late FakeClaimRepository repo;
  late ClaimsCubit cubit;

  setUp(() {
    repo = FakeClaimRepository([
      claim('a', expenseDate: DateTime(2026, 9, 1), status: ClaimStatus.pending, description: 'Cab to airport'),
      claim('b', expenseDate: DateTime(2026, 9, 10), status: ClaimStatus.approved, description: 'Team lunch', category: ClaimCategory.food),
      claim('c', expenseDate: DateTime(2026, 8, 20), status: ClaimStatus.rejected, description: 'Hotel'),
      claim('other', employeeId: 'emp002', status: ClaimStatus.pending),
    ]);
    cubit = ClaimsCubit(repo, employeeId: 'emp001');
  });

  tearDown(() => cubit.close());

  Future<void> pump() => Future<void>.delayed(Duration.zero);

  test('only shows the signed-in employee\'s claims, newest first by default', () async {
    cubit.load();
    await pump();
    expect(cubit.state.status, ClaimsStatus.ready);
    expect(cubit.state.visible.map((c) => c.id), ['b', 'a', 'c']);
  });

  test('toggleSortOrder flips to oldest first', () async {
    cubit.load();
    await pump();
    cubit.toggleSortOrder();
    expect(cubit.state.visible.map((c) => c.id), ['c', 'a', 'b']);
  });

  test('status filter and search narrow the list', () async {
    cubit.load();
    await pump();
    cubit.filterByStatus(ClaimStatus.pending);
    expect(cubit.state.visible.map((c) => c.id), ['a']);
    cubit.filterByStatus(null);
    cubit.search('food');
    expect(cubit.state.visible.map((c) => c.id), ['b']);
    cubit.clearFilters();
    expect(cubit.state.visible.length, 3);
  });

  test('setStatus persists and the list updates from the stream', () async {
    cubit.load();
    await pump();
    final error = await cubit.setStatus('a', ClaimStatus.approved);
    await pump();
    expect(error, isNull);
    final updated = cubit.state.claims.firstWhere((c) => c.id == 'a');
    expect(updated.status, ClaimStatus.approved);
    expect(updated.reviewedAt, repo.reviewClock);
  });

  test('setStatus reports an error for an unknown claim', () async {
    cubit.load();
    await pump();
    expect(await cubit.setStatus('missing', ClaimStatus.approved), isNotNull);
  });
}