import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/sync/outbox_operation.dart';
import '../../../core/sync/outbox_repository.dart';
import '../../../core/time/zoned_timestamp.dart';
import '../domain/consent_catalog.dart';
import '../domain/consent_decision.dart';
import '../domain/consent_repository.dart';

/// Outbox kind for consent decisions, sent to `POST /v1/consents`.
const String consentDecisionOperationKind = 'consent_decision';

class DriftConsentRepository implements ConsentRepository {
  DriftConsentRepository({
    required this._db,
    required this._outbox,
    required this._isSyncEnabled,
    DateTime Function()? now,
  }) : _now = now ?? (() => DateTime.now().toUtc());

  final AppDatabase _db;
  final OutboxRepository _outbox;
  final bool Function() _isSyncEnabled;
  final DateTime Function() _now;

  $ConsentDecisionsTable get _table => _db.consentDecisions;

  /// Recording order is insertion order.
  SimpleSelectStatement<$ConsentDecisionsTable, ConsentDecisionRow>
  get _ordered => _db.select(_table)
    ..orderBy([(_) => OrderingTerm.asc(const CustomExpression<int>('rowid'))]);

  @override
  Stream<List<ConsentDecision>> watchLog() =>
      _ordered.watch().map((rows) => rows.map(_toDomain).toList());

  @override
  Future<List<ConsentDecision>> log() async =>
      (await _ordered.get()).map(_toDomain).toList();

  @override
  Future<void> record(ConsentDecision decision) => _db.transaction(() async {
    final existing = await _find(decision.id);
    if (existing != null) {
      if (_toDomain(existing) != decision) {
        throw StateError('Consent decision ${decision.id} already exists.');
      }
      return;
    }
    await _db.into(_table).insert(_toRow(decision, syncedAt: null));
    if (_isSyncEnabled()) await _enqueue(decision);
  });

  @override
  Future<void> importConfirmed(List<ConsentDecision> decisions) =>
      _db.transaction(() async {
        final syncedAt = _now();
        for (final decision in decisions) {
          await _db
              .into(_table)
              .insert(
                _toRow(decision, syncedAt: syncedAt),
                mode: InsertMode.insertOrIgnore,
              );
        }
      });

  @override
  Future<int> enqueueUnsynced() => _db.transaction(() async {
    final unsynced = await (_ordered..where((t) => t.syncedAtUtc.isNull()))
        .get();
    var added = 0;
    for (final row in unsynced) {
      if (await _enqueue(_toDomain(row))) added += 1;
    }
    return added;
  });

  @override
  Future<void> markSynced(String id, DateTime at) =>
      (_db.update(_table)..where((t) => t.id.equals(id))).write(
        ConsentDecisionsCompanion(syncedAtUtc: Value(at.toUtc())),
      );

  @override
  Stream<int> watchUnsyncedCount() {
    final count = _table.id.count();
    return (_db.selectOnly(_table)
          ..addColumns([count])
          ..where(_table.syncedAtUtc.isNull()))
        .map((row) => row.read(count) ?? 0)
        .watchSingle();
  }

  @override
  Future<void> deleteAll() => _db.delete(_table).go();

  Future<ConsentDecisionRow?> _find(String id) =>
      (_db.select(_table)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<bool> _enqueue(ConsentDecision decision) {
    final now = _now();
    return _outbox.enqueue(
      OutboxOperation(
        id: decision.id,
        kind: consentDecisionOperationKind,
        payload: jsonEncode(decision.toJson()),
        createdAt: now,
        nextAttemptAt: now,
      ),
    );
  }

  static ConsentDecisionsCompanion _toRow(
    ConsentDecision decision, {
    required DateTime? syncedAt,
  }) => ConsentDecisionsCompanion.insert(
    id: decision.id,
    consentType: decision.type.wireName,
    sourceId: Value(decision.sourceId),
    state: decision.state.name,
    scopes: decision.scopes,
    policyVersion: decision.policyVersion,
    decidedAtUtc: decision.decidedAt.instant,
    decidedTimeZone: decision.decidedAt.timeZone,
    decidedUtcOffsetMinutes: decision.decidedAt.utcOffsetMinutes,
    syncedAtUtc: Value(syncedAt?.toUtc()),
  );

  static ConsentDecision _toDomain(ConsentDecisionRow row) {
    final type = ConsentType.fromWireName(row.consentType);
    if (type == null) {
      throw StateError('Unknown consent type "${row.consentType}".');
    }
    return ConsentDecision(
      id: row.id,
      type: type,
      sourceId: row.sourceId,
      state: ConsentState.values.byName(row.state),
      scopes: row.scopes,
      policyVersion: row.policyVersion,
      decidedAt: ZonedTimestamp.at(
        row.decidedAtUtc,
        timeZone: row.decidedTimeZone,
        utcOffsetMinutes: row.decidedUtcOffsetMinutes,
      ),
    );
  }
}
