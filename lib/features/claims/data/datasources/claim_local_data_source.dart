import 'package:hive/hive.dart';

import '../../domain/entities/expense_claim.dart';
import '../models/claim_model.dart';
import 'claim_seed.dart';

class ClaimLocalDataSource {
  ClaimLocalDataSource(this._box);

  static const String boxName = 'claims';

  final Box<Map> _box;

  Future<void> seedIfEmpty() async {
    if (_box.isNotEmpty) return;
    await _box.putAll({for (final c in ClaimSeed.build()) c.id: ClaimModel.toMap(c)});
  }

  List<ExpenseClaim> readAll() => _box.values.map(ClaimModel.fromMap).toList();

  ExpenseClaim? readById(String id) {
    final raw = _box.get(id);
    return raw == null ? null : ClaimModel.fromMap(raw);
  }

  Future<void> upsert(ExpenseClaim claim) => _box.put(claim.id, ClaimModel.toMap(claim));

  Future<void> delete(String id) => _box.delete(id);

  Stream<List<ExpenseClaim>> watchAll() async* {
    yield readAll();
    yield* _box.watch().map((_) => readAll());
  }
}