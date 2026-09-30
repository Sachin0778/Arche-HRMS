import '../entities/expense_claim.dart';

abstract class ClaimRepository {
  /// Emits every stored claim now and after each mutation.
  Stream<List<ExpenseClaim>> watchAll();

  Future<List<ExpenseClaim>> getAll();

  Future<ExpenseClaim?> getById(String id);

  Future<void> submit(ExpenseClaim claim);

  /// Demo hook: approve, reject or reset a claim. Persists and notifies
  /// [watchAll] listeners so the dashboard refreshes automatically.
  Future<void> updateStatus(String id, ClaimStatus status);

  Future<void> delete(String id);
}