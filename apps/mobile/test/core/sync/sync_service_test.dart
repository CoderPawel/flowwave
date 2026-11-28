import 'dart:async';
import 'dart:io';

import 'package:flowwave_mobile/src/core/database/app_database.dart';
import 'package:flowwave_mobile/src/core/errors/app_failure.dart';
import 'package:flowwave_mobile/src/core/sync/drift_outbox_repository.dart';
import 'package:flowwave_mobile/src/core/sync/outbox_operation.dart';
import 'package:flowwave_mobile/src/core/sync/sync_scheduler.dart';
import 'package:flowwave_mobile/src/core/sync/sync_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import '../../support/test_database.dart';

/// Sends by calling [respond]; records what was sent and marked.
class RecordingHandler implements SyncHandler {
  RecordingHandler(this.respond);

  FutureOr<void> Function(OutboxOperation operation) respond;
  final List<String> sent = [];
  final List<String> marked = [];

  @override
  String get kind => 'test';

  @override
  Future<void> send(OutboxOperation operation) async {
    sent.add(operation.id);
    await respond(operation);
  }

  @override
  Future<void> markSent(OutboxOperation operation) async =>
      marked.add(operation.id);
}

class BrokenOutbox extends DriftOutboxRepository {
  BrokenOutbox(super.db);

  @override
  Future<List<OutboxOperation>> due(DateTime now, {int limit = 50}) =>
      throw SqliteException(extendedResultCode: 10, message: 'disk I/O error');
}

class RecordingParticipant implements SyncParticipant {
  int prepared = 0;

  @override
  Future<void> prepareForSync() async => prepared += 1;
}

void main() {
  late AppDatabase db;
  late DriftOutboxRepository outbox;
  late RecordingHandler handler;
  late DateTime now;
  late bool enabled;

  SyncService service() => SyncService(
    outbox: outbox,
    handlers: [handler],
    isEnabled: () => enabled,
    now: () => now,
  );

  Future<void> enqueue(String id, {int minute = 0}) => outbox.enqueue(
    OutboxOperation(
      id: id,
      kind: 'test',
      payload: '{}',
      createdAt: DateTime.utc(2026, 11, 28, 9, minute),
      nextAttemptAt: DateTime.utc(2026, 11, 28, 9, minute),
    ),
  );

  Future<DateTime> retryOf(String id) async => (await (db.select(
    db.outboxOperations,
  )..where((t) => t.id.equals(id))).getSingle()).nextAttemptAtUtc.toUtc();

  setUp(() {
    db = inMemoryDatabase();
    outbox = DriftOutboxRepository(db);
    handler = RecordingHandler((_) {});
    now = DateTime.utc(2026, 11, 28, 10);
    enabled = true;
  });

  tearDown(() => db.close());

  test('sends every due operation in order and removes it', () async {
    await enqueue('b', minute: 2);
    await enqueue('a', minute: 1);

    final report = await service().syncNow();

    expect(report.stop, SyncStop.completed);
    expect(report.sent, 2);
    expect(handler.sent, ['a', 'b']);
    expect(handler.marked, ['a', 'b']);
    expect(await outbox.summary(), const OutboxSummary());
  });

  test('does nothing while sync is off (signed out)', () async {
    enabled = false;
    await enqueue('a');
    final report = await service().syncNow();
    expect(report.stop, SyncStop.disabled);
    expect(handler.sent, isEmpty);
  });

  test('offline: keeps the order and retries with growing backoff', () async {
    await enqueue('a', minute: 1);
    await enqueue('b', minute: 2);
    handler.respond = (_) => throw const SocketException('offline');
    final sync = service();

    final first = await sync.syncNow();
    expect(first.stop, SyncStop.willRetry);
    expect(first.failure, const AppFailure.network());
    expect(handler.sent, ['a'], reason: 'b waits behind a');
    expect(await retryOf('a'), now.add(const Duration(seconds: 30)));

    now = now.add(const Duration(seconds: 30));
    await sync.syncNow();
    expect(await retryOf('a'), now.add(const Duration(minutes: 1)));

    expect(sync.backoffAfter(1), const Duration(seconds: 30));
    expect(sync.backoffAfter(3), const Duration(minutes: 2));
    expect(sync.backoffAfter(30), const Duration(hours: 1));
  });

  test('rate limited: waits as long as the server asks', () async {
    await enqueue('a');
    handler.respond = (_) =>
        throw const AppFailure.rateLimited(retryAfter: Duration(minutes: 5));
    await service().syncNow();
    expect(await outbox.nextDueAt(), now.add(const Duration(minutes: 5)));
  });

  test('session ended: pauses without touching the queue', () async {
    await enqueue('a');
    handler.respond = (_) => throw const AppFailure.notSignedIn();
    final report = await service().syncNow();
    expect(report.stop, SyncStop.needsSignIn);
    final pending = await outbox.due(now);
    expect(pending.single.attempts, 0);
  });

  test(
    'refused operations are kept as rejected and the rest continue',
    () async {
      await enqueue('invalid', minute: 1);
      await enqueue('conflict', minute: 2);
      await enqueue('fine', minute: 3);
      handler.respond = (operation) => switch (operation.id) {
        'invalid' => throw const AppFailure.validation(field: 'decidedAt'),
        'conflict' => throw const AppFailure.conflict(field: 'id'),
        _ => null,
      };

      final report = await service().syncNow();

      expect(report.stop, SyncStop.completed);
      expect(report.sent, 1);
      expect(report.rejected, 2);
      expect(handler.marked, ['fine']);
      expect(await outbox.summary(), const OutboxSummary(rejected: 2));
    },
  );

  test('operations of an unknown kind are rejected', () async {
    await outbox.enqueue(
      OutboxOperation(
        id: 'x',
        kind: 'from_a_newer_version',
        payload: '{}',
        createdAt: now,
        nextAttemptAt: now,
      ),
    );
    final report = await service().syncNow();
    expect(report.rejected, 1);
  });

  test('concurrent calls share one pass, so nothing is sent twice', () async {
    await enqueue('a');
    final release = Completer<void>();
    handler.respond = (_) => release.future;
    final sync = service();

    final both = Future.wait([sync.syncNow(), sync.syncNow()]);
    await Future<void>.delayed(Duration.zero);
    release.complete();
    await both;

    expect(handler.sent, ['a']);
  });

  group('scheduler', () {
    test('runs when something is enqueued', () async {
      final scheduler = SyncScheduler(
        service: service(),
        outbox: outbox,
        participants: const [],
        now: () => now,
      )..start();
      addTearDown(scheduler.dispose);

      await enqueue('a');
      await pumpEventQueue();

      expect(handler.sent, ['a']);
    });

    test(
      'prepares participants and skips backoff when sync turns on',
      () async {
        await enqueue('a');
        await outbox.scheduleRetry(
          'a',
          attempts: 3,
          nextAttemptAt: now.add(const Duration(hours: 1)),
          error: 'network',
        );
        final participant = RecordingParticipant();
        final scheduler = SyncScheduler(
          service: service(),
          outbox: outbox,
          participants: [participant],
          now: () => now,
        );
        addTearDown(scheduler.dispose);

        final report = await scheduler.onSyncEnabled();

        expect(participant.prepared, 1);
        expect(report.sent, 1);
      },
    );

    test('never throws, even when storage fails', () async {
      final broken = BrokenOutbox(db);
      final scheduler = SyncScheduler(
        service: SyncService(
          outbox: broken,
          handlers: [handler],
          isEnabled: () => true,
        ),
        outbox: broken,
        participants: const [],
        now: () => now,
      );
      addTearDown(scheduler.dispose);
      final report = await scheduler.syncNow();
      expect(report.stop, SyncStop.willRetry);
      expect(report.failure, const AppFailure.storage());
    });
  });
}
