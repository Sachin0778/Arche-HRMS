import '../../domain/entities/expense_claim.dart';

/// A handful of historical claims so the dashboard and list have content on
/// first launch. Dates are relative to "now" so the "approved this month"
/// stat always has data. Seeded claims have no receipt file on disk, and the
/// detail screen handles that gracefully.
class ClaimSeed {
  ClaimSeed._();

  static List<ExpenseClaim> build({DateTime? now}) {
    final today = now ?? DateTime.now();
    DateTime ago(int days) => today.subtract(Duration(days: days));

    return [
      ExpenseClaim(
        id: 'clm-seed-001',
        employeeId: 'emp001',
        category: ClaimCategory.travel,
        amount: 2450,
        expenseDate: ago(4),
        description: 'Cab fare to client site in Whitefield and back',
        receiptPath: '',
        status: ClaimStatus.approved,
        submittedAt: ago(3),
        reviewedAt: ago(2),
      ),
      ExpenseClaim(
        id: 'clm-seed-002',
        employeeId: 'emp001',
        category: ClaimCategory.food,
        amount: 860.5,
        expenseDate: ago(2),
        description: 'Team lunch during sprint planning offsite',
        receiptPath: '',
        status: ClaimStatus.pending,
        submittedAt: ago(1),
      ),
      ExpenseClaim(
        id: 'clm-seed-003',
        employeeId: 'emp001',
        category: ClaimCategory.accommodation,
        amount: 7200,
        expenseDate: ago(40),
        description: 'Two nights hotel stay for Chennai onboarding trip',
        receiptPath: '',
        status: ClaimStatus.approved,
        submittedAt: ago(38),
        reviewedAt: ago(35),
      ),
      ExpenseClaim(
        id: 'clm-seed-004',
        employeeId: 'emp001',
        category: ClaimCategory.other,
        amount: 1299,
        expenseDate: ago(20),
        description: 'USB-C hub for the work laptop after the old one failed',
        receiptPath: '',
        status: ClaimStatus.rejected,
        submittedAt: ago(19),
        reviewedAt: ago(17),
      ),
      ExpenseClaim(
        id: 'clm-seed-005',
        employeeId: 'emp002',
        category: ClaimCategory.travel,
        amount: 5600,
        expenseDate: ago(6),
        description: 'Flight to Hyderabad for architecture review',
        receiptPath: '',
        status: ClaimStatus.pending,
        submittedAt: ago(5),
      ),
    ];
  }
}