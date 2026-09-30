import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../data/datasources/receipt_file_store.dart';
import '../../domain/entities/expense_claim.dart';
import '../../domain/repositories/claim_repository.dart';

part 'submit_claim_state.dart';

/// Holds the non-text parts of the claim form (category, date, receipt) and
/// performs the save. Text fields stay in the Form so validation messages
/// render inline; the cubit receives their final values on submit.
class SubmitClaimCubit extends Cubit<SubmitClaimState> {
  SubmitClaimCubit(
    this._repository,
    this._receipts, {
    required this.employeeId,
    Uuid? uuid,
    DateTime Function()? clock,
  })  : _uuid = uuid ?? const Uuid(),
        _clock = clock ?? DateTime.now,
        super(const SubmitClaimState());

  final ClaimRepository _repository;
  final ReceiptFileStore _receipts;
  final String employeeId;
  final Uuid _uuid;
  final DateTime Function() _clock;

  void selectCategory(ClaimCategory category) => emit(state.copyWith(category: category));

  void selectDate(DateTime date) => emit(state.copyWith(expenseDate: date));

  void attachReceipt(String path) => emit(state.copyWith(receiptPath: path, clearError: true));

  void removeReceipt() => emit(state.copyWith(clearReceipt: true));

  Future<void> submit({required double amount, required String description}) async {
    final category = state.category;
    final date = state.expenseDate;
    final receipt = state.receiptPath;
    if (category == null || date == null || receipt == null || receipt.isEmpty) {
      emit(state.copyWith(
        status: SubmitStatus.failure,
        errorMessage: 'Please complete every field and attach a receipt.',
      ));
      return;
    }

    emit(state.copyWith(status: SubmitStatus.submitting, clearError: true));
    final id = 'clm-${_uuid.v4()}';
    try {
      final storedPath = await _receipts.persist(receipt, claimId: id);
      await _repository.submit(ExpenseClaim(
        id: id,
        employeeId: employeeId,
        category: category,
        amount: amount,
        expenseDate: date,
        description: description.trim(),
        receiptPath: storedPath,
        status: ClaimStatus.pending,
        submittedAt: _clock(),
      ));
      emit(state.copyWith(status: SubmitStatus.success));
    } catch (e) {
      emit(state.copyWith(status: SubmitStatus.failure, errorMessage: 'Could not save the claim: $e'));
    }
  }
}