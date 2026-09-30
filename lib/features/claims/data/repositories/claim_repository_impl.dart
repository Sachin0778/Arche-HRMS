import '../../domain/entities/expense_claim.dart';
import '../../domain/repositories/claim_repository.dart';
import '../datasources/claim_local_data_source.dart';

class ClaimRepositoryImpl implements ClaimRepository {
  ClaimRepositoryImpl(this._local, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final ClaimLocalDataSource _local;
  final DateTime Function() _clock;

  @override
  Stream<List<ExpenseClaim>> watchAll() => _local.watchAll();

  @override
  Future<List<ExpenseClaim>> getAll() async => _local.readAll();

  @override
  Future<ExpenseClaim?> getById(String id) async => _local.readById(id);

  @override
  Future<void> submit(ExpenseClaim claim) => _local.upsert(claim);

  @override
  Future<void> updateStatus(String id, ClaimStatus status) async {
    final existing = _local.readById(id);
    if (existing == null) {
      throw StateError('Claim $id no longer exists');
    }
    final updated = status == ClaimStatus.pending
        ? existing.copyWith(status: status, clearReviewedAt: true)
        : existing.copyWith(status: status, reviewedAt: _clock());
    await _local.upsert(updated);
  }

  @override
  Future<void> delete(String id) => _local.delete(id);
}