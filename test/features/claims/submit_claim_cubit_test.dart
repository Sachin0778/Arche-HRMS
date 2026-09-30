import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hrms/features/claims/domain/entities/expense_claim.dart';
import 'package:hrms/features/claims/presentation/cubit/submit_claim_cubit.dart';
import 'package:path/path.dart' as p;

import '../../helpers/fakes.dart';

void main() {
  late Directory tempDir;
  late FakeClaimRepository repo;
  late SubmitClaimCubit cubit;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('hrms_test');
    repo = FakeClaimRepository();
    cubit = SubmitClaimCubit(
      repo,
      tempReceiptStore(tempDir),
      employeeId: 'emp001',
      clock: () => DateTime(2026, 9, 29, 9),
    );
  });

  tearDown(() async {
    await cubit.close();
    tempDir.deleteSync(recursive: true);
  });

  test('refuses to submit without category, date and receipt', () async {
    await cubit.submit(amount: 100, description: 'Missing pieces');
    expect(cubit.state.status, SubmitStatus.failure);
    expect(repo.current, isEmpty);
  });

  test('copies the receipt into app storage and saves a pending claim', () async {
    final source = File(p.join(tempDir.path, 'picked.jpg'))..writeAsBytesSync([1, 2, 3]);
    cubit
      ..selectCategory(ClaimCategory.food)
      ..selectDate(DateTime(2026, 9, 20))
      ..attachReceipt(source.path);

    await cubit.submit(amount: 450.75, description: '  Lunch with client  ');

    expect(cubit.state.status, SubmitStatus.success);
    final saved = repo.current.single;
    expect(saved.status, ClaimStatus.pending);
    expect(saved.amount, 450.75);
    expect(saved.description, 'Lunch with client');
    expect(saved.submittedAt, DateTime(2026, 9, 29, 9));
    expect(saved.receiptPath, contains('receipts'));
    expect(File(saved.receiptPath).existsSync(), isTrue);
  });

  test('surfaces a failure when the receipt file cannot be copied', () async {
    cubit
      ..selectCategory(ClaimCategory.travel)
      ..selectDate(DateTime(2026, 9, 20))
      ..attachReceipt(p.join(tempDir.path, 'does-not-exist.jpg'));
    await cubit.submit(amount: 10, description: 'Broken receipt path');
    expect(cubit.state.status, SubmitStatus.failure);
    expect(cubit.state.errorMessage, contains('Could not save'));
    expect(repo.current, isEmpty);
  });
}