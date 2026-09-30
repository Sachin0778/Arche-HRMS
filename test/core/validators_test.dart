import 'package:flutter_test/flutter_test.dart';
import 'package:hrms/core/utils/validators.dart';

void main() {
  group('Validators.amount', () {
    test('rejects empty, non-numeric, zero and negative', () {
      expect(Validators.amount(''), isNotNull);
      expect(Validators.amount('abc'), isNotNull);
      expect(Validators.amount('0'), isNotNull);
      expect(Validators.amount('-5'), isNotNull);
    });

    test('accepts positive decimals and thousands separators', () {
      expect(Validators.amount('1250.50'), isNull);
      expect(Validators.amount('1,250'), isNull);
    });
  });

  group('Validators.claimDate', () {
    final now = DateTime(2026, 9, 29, 12);

    test('rejects future dates and dates older than a year', () {
      expect(Validators.claimDate(DateTime(2026, 9, 30), now: now), isNotNull);
      expect(Validators.claimDate(DateTime(2025, 1, 1), now: now), isNotNull);
      expect(Validators.claimDate(null, now: now), isNotNull);
    });

    test('accepts today and recent dates', () {
      expect(Validators.claimDate(DateTime(2026, 9, 29), now: now), isNull);
      expect(Validators.claimDate(DateTime(2026, 8, 1), now: now), isNull);
    });
  });

  test('description enforces length bounds', () {
    expect(Validators.description('short'), isNotNull);
    expect(Validators.description('A reasonably long description'), isNull);
    expect(Validators.description('x' * 301), isNotNull);
  });

  test('employeeId accepts emp001 style ids only', () {
    expect(Validators.employeeId('emp001'), isNull);
    expect(Validators.employeeId('EMP12345'), isNull);
    expect(Validators.employeeId('001'), isNotNull);
    expect(Validators.employeeId(''), isNotNull);
  });
}