import 'package:equatable/equatable.dart';

enum ClaimCategory {
  travel('Travel'),
  food('Food'),
  accommodation('Accommodation'),
  other('Other');

  const ClaimCategory(this.label);
  final String label;

  static ClaimCategory fromName(String name) =>
      ClaimCategory.values.firstWhere((c) => c.name == name, orElse: () => ClaimCategory.other);
}

enum ClaimStatus {
  pending('Pending'),
  approved('Approved'),
  rejected('Rejected');

  const ClaimStatus(this.label);
  final String label;

  static ClaimStatus fromName(String name) =>
      ClaimStatus.values.firstWhere((s) => s.name == name, orElse: () => ClaimStatus.pending);
}

/// An expense claim raised by an employee.
class ExpenseClaim extends Equatable {
  const ExpenseClaim({
    required this.id,
    required this.employeeId,
    required this.category,
    required this.amount,
    required this.expenseDate,
    required this.description,
    required this.receiptPath,
    required this.status,
    required this.submittedAt,
    this.reviewedAt,
  });

  final String id;
  final String employeeId;
  final ClaimCategory category;
  final double amount;

  /// Date the expense was incurred (what the user picks in the form).
  final DateTime expenseDate;
  final String description;

  /// Absolute path of the receipt image copied into app storage.
  final String receiptPath;
  final ClaimStatus status;
  final DateTime submittedAt;

  /// When an admin approved/rejected it; `null` while pending.
  final DateTime? reviewedAt;

  ExpenseClaim copyWith({ClaimStatus? status, DateTime? reviewedAt, bool clearReviewedAt = false}) {
    return ExpenseClaim(
      id: id,
      employeeId: employeeId,
      category: category,
      amount: amount,
      expenseDate: expenseDate,
      description: description,
      receiptPath: receiptPath,
      status: status ?? this.status,
      submittedAt: submittedAt,
      reviewedAt: clearReviewedAt ? null : (reviewedAt ?? this.reviewedAt),
    );
  }

  @override
  List<Object?> get props => [
        id, employeeId, category, amount, expenseDate, description,
        receiptPath, status, submittedAt, reviewedAt,
      ];
}