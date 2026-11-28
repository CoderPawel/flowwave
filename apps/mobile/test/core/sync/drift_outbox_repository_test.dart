import 'package:flowwave_mobile/src/core/database/app_database.dart';
import 'package:flowwave_mobile/src/core/sync/drift_outbox_repository.dart';
import 'package:flowwave_mobile/src/core/sync/outbox_operation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_database.dart';

void main() {
  late AppDatabase db;
  late DriftOutboxRepository outbox;
  final t0 = DateTime.utc(2026, 11, 28, 9);

  OutboxOperation op(String id, {DateTime? createdAt, DateTime? due}) =>
      OutboxOperation(
        id: id,
        kind: 'consent_decision',
        payload: '{"id":"$id"}',
        createdAt: createdAt ?? t0,
        nextAttemptAt: due ?? createdAt ?? t0,
      );

  setUp(() {
    db = inMemoryDatabase();
    outbox = DriftOutboxRepository(db);
  });

  tearDown(() => db.close());

  test('enqueuing the same operation ID twice keeps one operation', () async {
    expect(await outbox.enqueue(op('a')), isTrue);
    expect(await outbox.enqueue(op('a')), isFalse);
    expect((await outbox.due(t0)).map((o) => o.id), ['a']);
  });

  test('returns due operations oldest first', () async {
    await outbox.enqueue(
      op('late', createdAt: t0.add(const Duration(minutes: 2))),
    );
    await outbox.enqueue(op('early', createdAt: t0));
    await outbox.enqueue(
      op('future', createdAt: t0, due: t0.add(const Duration(hours: 1))),
    );

    final due = await outbox.due(t0.add(const Duration(minutes: 5)));
    expect(due.map((o) => o.id), ['early', 'late']);
    expect(await outbox.nextDueAt(), t0);
  });

  test('completing removes the operation and runs the callback in the same '
      'transaction', () async {
    await outbox.enqueue(op('a'));
    await expectLater(
      outbox.complete('a', onSent: () async => throw StateError('boom')),
      throwsStateError,
    );
    expect(
      await outbox.due(t0),
      hasLength(1),
      reason: 'the failed callback rolled the removal back',
    );

    var marked = false;
    await outbox.complete('a', onSent: () async => marked = true);
    expect(marked, isTrue);
    expect(await outbox.due(t0), isEmpty);
  });

  test('a scheduled retry waits until it is due', () async {
    await outbox.enqueue(op('a'));
    final retryAt = t0.add(const Duration(seconds: 30));
    await outbox.scheduleRetry(
      'a',
      attempts: 1,
      nextAttemptAt: retryAt,
      error: 'network',
    );

    expect(await outbox.due(t0), isEmpty);
    final due = await outbox.due(retryAt);
    expect(due.single.attempts, 1);
    expect(due.single.lastError, 'network');
    expect(await outbox.nextDueAt(), retryAt);

    await outbox.resetBackoff(t0);
    expect(await outbox.due(t0), hasLength(1));
  });

  test('rejected operations are kept, counted, and never due', () async {
    await outbox.enqueue(op('a'));
    await outbox.enqueue(op('b'));
    await outbox.markRejected('a', error: 'validation_failed:decidedAt');

    expect((await outbox.due(t0)).map((o) => o.id), ['b']);
    expect(
      await outbox.summary(),
      const OutboxSummary(pending: 1, rejected: 1),
    );
    expect(
      await outbox.enqueue(op('a')),
      isFalse,
      reason: 'a rejected operation is not queued again',
    );
  });

  test('the summary stream follows changes', () async {
    final summaries = outbox.watchSummary();
    expect(await summaries.first, const OutboxSummary());
    await outbox.enqueue(op('a'));
    expect(await summaries.first, const OutboxSummary(pending: 1));
    await outbox.deleteAll();
    expect(await summaries.first, const OutboxSummary());
  });
}
