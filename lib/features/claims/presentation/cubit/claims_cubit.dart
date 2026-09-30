import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/expense_claim.dart';
import '../../domain/repositories/claim_repository.dart';

part 'claims_state.dart';

/// Drives the "My Claims" list and the demo approve/reject action.
class ClaimsCubit extends Cubit<ClaimsState> {
  ClaimsCubit(this._repository, {required this.employeeId}) : super(const ClaimsState());

  final ClaimRepository _repository;
  final String employeeId;
  StreamSubscription<List<ExpenseClaim>>? _subscription;

  void load() {
    emit(state.copyWith(status: ClaimsStatus.loading));
    _subscription?.cancel();
    _subscription = _repository.watchAll().listen(
      (all) => emit(state.copyWith(
        status: ClaimsStatus.ready,
        claims: all.where((c) => c.employeeId == employeeId).toList(),
      )),
      onError: (Object e) => emit(state.copyWith(
        status: ClaimsStatus.failure,
        errorMessage: 'Could not load claims: $e',
      )),
    );
  }

  void filterByStatus(ClaimStatus? status) => emit(
        status == null ? state.copyWith(clearStatusFilter: true) : state.copyWith(statusFilter: status),
      );

  void toggleSortOrder() => emit(state.copyWith(
        sortOrder: state.sortOrder == ClaimSortOrder.newestFirst
            ? ClaimSortOrder.oldestFirst
            : ClaimSortOrder.newestFirst,
      ));

  void search(String query) => emit(state.copyWith(query: query));

  void clearFilters() => emit(state.copyWith(query: '', clearStatusFilter: true));

  /// Demo-only admin action. Returns an error message on failure so the UI
  /// can show a snackbar without holding transient state in the cubit.
  Future<String?> setStatus(String claimId, ClaimStatus status) async {
    try {
      await _repository.updateStatus(claimId, status);
      return null;
    } catch (e) {
      return 'Could not update claim: $e';
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}