import '../../domain/entities/expense_claim.dart';

class ClaimModel {
  ClaimModel._();

  static Map<String, dynamic> toMap(ExpenseClaim c) => {
        'id': c.id,
        'employeeId': c.employeeId,
        'category': c.category.name,
        'amount': c.amount,
        'expenseDate': c.expenseDate.toIso8601String(),
        'description': c.description,
        'receiptPath': c.receiptPath,
        'status': c.status.name,
        'submittedAt': c.submittedAt.toIso8601String(),
        'reviewedAt': c.reviewedAt?.toIso8601String(),
      };

  static ExpenseClaim fromMap(Map<dynamic, dynamic> map) => ExpenseClaim(
        id: map['id'] as String,
        employeeId: map['employeeId'] as String,
        category: ClaimCategory.fromName(map['category'] as String),
        amount: (map['amount'] as num).toDouble(),
        expenseDate: DateTime.parse(map['expenseDate'] as String),
        description: map['description'] as String,
        receiptPath: map['receiptPath'] as String,
        status: ClaimStatus.fromName(map['status'] as String),
        submittedAt: DateTime.parse(map['submittedAt'] as String),
        reviewedAt: map['reviewedAt'] == null ? null : DateTime.parse(map['reviewedAt'] as String),
      );
}