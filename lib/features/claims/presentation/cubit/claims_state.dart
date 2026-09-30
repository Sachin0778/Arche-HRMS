part of 'claims_cubit.dart';

enum ClaimsStatus { initial, loading, ready, failure }

enum ClaimSortOrder { newestFirst, oldestFirst }

class ClaimsState extends Equatable {
  const ClaimsState({
    this.status = ClaimsStatus.initial,
    this.claims = const [],
    this.statusFilter,
    this.sortOrder = ClaimSortOrder.newestFirst,
    this.query = '',
    this.errorMessage,
  });

  final ClaimsStatus status;

  /// Claims belonging to the signed-in employee, unsorted.
  final List<ExpenseClaim> claims;

  /// `null` means every status.
  final ClaimStatus? statusFilter;
  final ClaimSortOrder sortOrder;
  final String query;
  final String? errorMessage;

  List<ExpenseClaim> get visible {
    final q = query.trim().toLowerCase();
    final list = claims.where((c) {
      final matchesStatus = statusFilter == null || c.status == statusFilter;
      final matchesQuery = q.isEmpty ||
          c.description.toLowerCase().contains(q) ||
          c.category.label.toLowerCase().contains(q);
      return matchesStatus && matchesQuery;
    }).toList();
    list.sort((a, b) => sortOrder == ClaimSortOrder.newestFirst
        ? b.expenseDate.compareTo(a.expenseDate)
        : a.expenseDate.compareTo(b.expenseDate));
    return list;
  }

  bool get hasActiveFilter => statusFilter != null || query.trim().isNotEmpty;

  ClaimsState copyWith({
    ClaimsStatus? status,
    List<ExpenseClaim>? claims,
    ClaimStatus? statusFilter,
    bool clearStatusFilter = false,
    ClaimSortOrder? sortOrder,
    String? query,
    String? errorMessage,
  }) {
    return ClaimsState(
      status: status ?? this.status,
      claims: claims ?? this.claims,
      statusFilter: clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
      sortOrder: sortOrder ?? this.sortOrder,
      query: query ?? this.query,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, claims, statusFilter, sortOrder, query, errorMessage];
}