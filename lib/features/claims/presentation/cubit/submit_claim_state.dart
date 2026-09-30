part of 'submit_claim_cubit.dart';

enum SubmitStatus { editing, submitting, success, failure }

class SubmitClaimState extends Equatable {
  const SubmitClaimState({
    this.status = SubmitStatus.editing,
    this.category,
    this.expenseDate,
    this.receiptPath,
    this.errorMessage,
  });

  final SubmitStatus status;
  final ClaimCategory? category;
  final DateTime? expenseDate;

  /// Temporary path from the image picker until the claim is saved.
  final String? receiptPath;
  final String? errorMessage;

  bool get hasReceipt => receiptPath != null && receiptPath!.isNotEmpty;

  SubmitClaimState copyWith({
    SubmitStatus? status,
    ClaimCategory? category,
    DateTime? expenseDate,
    String? receiptPath,
    bool clearReceipt = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SubmitClaimState(
      status: status ?? this.status,
      category: category ?? this.category,
      expenseDate: expenseDate ?? this.expenseDate,
      receiptPath: clearReceipt ? null : (receiptPath ?? this.receiptPath),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, category, expenseDate, receiptPath, errorMessage];
}