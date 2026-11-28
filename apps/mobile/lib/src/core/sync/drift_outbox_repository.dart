import 'package:drift/drift.dart';

import '../database/app_database.dart';
import 'outbox_operation.dart';
import 'outbox_repository.dart';

class DriftOutboxRepository implements OutboxRepository {
  DriftOutboxRepository(this._db);

  final AppDatabase _db;

  $OutboxOperationsTable get _table => _db.outboxOperations;

  @override
  Future<bool> enqueue(OutboxOperation operation) => _db.transaction(() async {
    if (await _exists(operation.id)) return false;
    await _db
        .into(_table)
        .insert(
          OutboxOperationsCompanion.insert(
            id: operation.id,
            kind: operation.kind,
            payload: operation.payload,
            createdAtUtc: operation.createdAt.toUtc(),
            attempts: Value(operation.attempts),
            nextAttemptAtUtc: operation.nextAttemptAt.toUtc(),
            status: Value(operation.status.name),
            lastError: Value(operation.lastError),
          ),
        );
    return true;
  });

  Future<bool> _exists(String id) async =>
      await (_db.select(
        _table,
      )..where((t) => t.id.equals(id))).getSingleOrNull() !=
      null;

  @override
  Future<List<OutboxOperation>> due(DateTime now, {int limit = 50}) async {
    final rows =
        await (_db.select(_table)
              ..where(
                (t) =>
                    t.status.equals(OutboxStatus.pending.name) &
                    t.nextAttemptAtUtc.isSmallerOrEqualValue(now.toUtc()),
              )
              ..orderBy([
                (t) => OrderingTerm.asc(t.createdAtUtc),
                (t) => OrderingTerm.asc(t.id),
              ])
              ..limit(limit))
            .get();
    return rows.map(_toDomain).toList();
  }

  @override
  Future<DateTime?> nextDueAt() async {
    final earliest = _table.nextAttemptAtUtc.min();
    final row =
        await (_db.selectOnly(_table)
              ..addColumns([earliest])
              ..where(_table.status.equals(OutboxStatus.pending.name)))
            .getSingle();
    return row.read(earliest)?.toUtc();
  }

  @override
  Future<void> complete(String id, {Future<void> Function()? onSent}) =>
      _db.transaction(() async {
        await (_db.delete(_table)..where((t) => t.id.equals(id))).go();
        if (onSent != null) await onSent();
      });

  @override
  Future<void> scheduleRetry(
    String id, {
    required int attempts,
    required DateTime nextAttemptAt,
    required String error,
  }) => (_db.update(_table)..where((t) => t.id.equals(id))).write(
    OutboxOperationsCompanion(
      attempts: Value(attempts),
      nextAttemptAtUtc: Value(nextAttemptAt.toUtc()),
      lastError: Value(error),
    ),
  );

  @override
  Future<void> markRejected(String id, {required String error}) =>
      (_db.update(_table)..where((t) => t.id.equals(id))).write(
        OutboxOperationsCompanion(
          status: Value(OutboxStatus.rejected.name),
          lastError: Value(error),
        ),
      );

  @override
  Future<void> resetBackoff(DateTime now) =>
      (_db.update(
        _table,
      )..where((t) => t.status.equals(OutboxStatus.pending.name))).write(
        OutboxOperationsCompanion(nextAttemptAtUtc: Value(now.toUtc())),
      );

  @override
  Stream<OutboxSummary> watchSummary() =>
      _summaryQuery().watchSingle().map(_readSummary);

  @override
  Future<OutboxSummary> summary() async =>
      _readSummary(await _summaryQuery().getSingle());

  Selectable<QueryRow> _summaryQuery() => _db.customSelect(
    'SELECT '
    "COALESCE(SUM(status = 'pending'), 0) AS pending, "
    "COALESCE(SUM(status = 'rejected'), 0) AS rejected "
    'FROM outbox_operations',
    readsFrom: {_table},
  );

  OutboxSummary _readSummary(QueryRow row) => OutboxSummary(
    pending: row.read<int>('pending'),
    rejected: row.read<int>('rejected'),
  );

  @override
  Future<void> deleteAll() => _db.delete(_table).go();

  OutboxOperation _toDomain(OutboxOperationRow row) => OutboxOperation(
    id: row.id,
    kind: row.kind,
    payload: row.payload,
    createdAt: row.createdAtUtc.toUtc(),
    attempts: row.attempts,
    nextAttemptAt: row.nextAttemptAtUtc.toUtc(),
    status: OutboxStatus.values.byName(row.status),
    lastError: row.lastError,
  );
}
