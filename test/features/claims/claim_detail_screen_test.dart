import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrms/features/claims/domain/entities/expense_claim.dart';
import 'package:hrms/features/claims/presentation/cubit/claims_cubit.dart';
import 'package:hrms/features/claims/presentation/screens/claim_detail_screen.dart';

import '../../helpers/fakes.dart';

void main() {
  testWidgets('claim detail can be pushed on the root navigator and reflects status changes', (tester) async {
    final repo = FakeClaimRepository([
      claim('c1', description: 'Cab fare to the airport', amount: 1200),
    ]);
    final cubit = ClaimsCubit(repo, employeeId: 'emp001')..load();
    addTearDown(cubit.close);

    // Mirrors the real widget tree: the cubit lives *below* MaterialApp, so a
    // pushed route must carry it explicitly.
    await tester.pumpWidget(MaterialApp(
      home: BlocProvider.value(
        value: cubit,
        child: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(ClaimDetailScreen.route(context, 'c1')),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));
    await tester.pump();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Cab fare to the airport'), findsOneWidget);
    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('No receipt attached (seeded demo claim)'), findsOneWidget);

    await repo.updateStatus('c1', ClaimStatus.approved);
    await tester.pumpAndSettle();
    expect(find.text('Approved'), findsWidgets);
  });
}