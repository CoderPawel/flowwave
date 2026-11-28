import 'dart:io';

import 'package:flowwave_mobile/src/core/database/app_database.dart';
import 'package:flowwave_mobile/src/core/errors/app_failure.dart';
import 'package:flowwave_mobile/src/core/sync/drift_outbox_repository.dart';
import 'package:flowwave_mobile/src/core/sync/outbox_operation.dart';
import 'package:flowwave_mobile/src/core/time/zoned_timestamp.dart';
import 'package:flowwave_mobile/src/features/consent/data/consent_sync_handler.dart';
import 'package:flowwave_mobile/src/features/consent/data/dio_consent_remote_data_source.dart';
import 'package:flowwave_mobile/src/features/consent/data/drift_consent_repository.dart';
import 'package:flowwave_mobile/src/features/consent/domain/consent_catalog.dart';
import 'package:flowwave_mobile/src/features/consent/domain/consent_decision.dart';
import 'package:flowwave_mobile/src/features/consent/domain/consent_repository.dart';
import 'package:flowwave_mobile/src/core/network/api_dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/auth_fakes.dart';
import '../../support/fake_http_adapter.dart';
import '../../support/test_database.dart';

ConsentDecision decision(
  String id, {
  ConsentType type = ConsentType.notifications,
  ConsentState state = ConsentState.granted,
  int minute = 0,
}) => ConsentDecision.create(
  id: id,
  type: type,
  state: state,
  decidedAt: ZonedTimestamp.at(
    DateTime.utc(2026, 11, 28, 9, minute),
    timeZone: 'Europe/Warsaw',
    utcOffsetMinutes: 60,
  ),
);

/// Fails every enqueue, to prove the entity write rolls back with it.
class FailingOutbox extends DriftOutboxRepository {
  FailingOutbox(super.db);

  @override
  Future<bool> enqueue(OutboxOperation operation) =>
      throw StateError('disk full');
}

void main() {
  late AppDatabase db;
  late DriftOutboxRepository outbox;
  late bool syncOn;
  final now = DateTime.utc(2026, 11, 28, 10);

  DriftConsentRepository repository({DriftOutboxRepository? queue}) =>
      DriftConsentRepository(
        db: db,
        outbox: queue ?? outbox,
        isSyncEnabled: () => syncOn,
        now: () => now,
      );

  setUp(() {
    db = inMemoryDatabase();
    outbox = DriftOutboxRepository(db);
    syncOn = false;
  });

  tearDown(() => db.close());

  group('recording', () {
    test('while signed out stores the decision without queuing it', () async {
      final repo = repository();
      await repo.record(decision('a'));

      expect(await repo.log(), [decision('a')]);
      expect(await outbox.summary(), const OutboxSummary());
    });

    test('while signed in stores and queues it in one transaction', () async {
      syncOn = true;
      final repo = repository();
      await repo.record(decision('a'));

      final queued = await outbox.due(now);
      expect(queued.single.id, 'a');
      expect(queued.single.kind, consentDecisionOperationKind);
      expect(queued.single.payload, contains('"type":"notifications"'));
    });

    test('rolls the decision back when queuing fails', () async {
      syncOn = true;
      final repo = repository(queue: FailingOutbox(db));
      await expectLater(repo.record(decision('a')), throwsStateError);
      expect(await repo.log(), isEmpty);
    });

    test('recording the same decision again changes nothing', () async {
      syncOn = true;
      final repo = repository();
      await repo.record(decision('a'));
      await repo.record(decision('a'));
      expect(await repo.log(), hasLength(1));
      expect(await outbox.summary(), const OutboxSummary(pending: 1));
    });

    test('refuses a different decision with a used ID', () async {
      final repo = repository();
      await repo.record(decision('a'));
      await expectLater(
        repo.record(decision('a', state: ConsentState.revoked)),
        throwsStateError,
      );
    });

    test('keeps recording order', () async {
      final repo = repository();
      await repo.record(decision('later', minute: 5));
      await repo.record(decision('earlier', minute: 1));
      expect((await repo.log()).map((d) => d.id), ['later', 'earlier']);
    });
  });

  group('sync', () {
    test('queues only decisions the server does not have, once', () async {
      final repo = repository();
      await repo.record(decision('local'));
      await repo.importConfirmed([decision('remote', minute: 1)]);

      syncOn = true;
      expect(await repo.enqueueUnsynced(), 1);
      expect(await repo.enqueueUnsynced(), 0);
      expect((await outbox.due(now)).map((o) => o.id), ['local']);
    });

    test('importing keeps local decisions with the same ID', () async {
      final repo = repository();
      await repo.record(decision('a'));
      await repo.importConfirmed([decision('a'), decision('b', minute: 1)]);
      expect((await repo.log()).map((d) => d.id), ['a', 'b']);
    });

    test('marking synced updates the unsynced count', () async {
      final repo = repository();
      await repo.record(decision('a'));
      expect(await repo.watchUnsyncedCount().first, 1);
      await repo.markSynced('a', now);
      expect(await repo.watchUnsyncedCount().first, 0);
    });

    test('deleteAll removes every decision', () async {
      final repo = repository();
      await repo.record(decision('a'));
      await repo.deleteAll();
      expect(await repo.log(), isEmpty);
    });
  });

  group('sync handler', () {
    late FakeHttpAdapter server;
    late ConsentRepository repo;
    late ConsentSyncHandler handler;

    setUp(() {
      server = FakeHttpAdapter();
      repo = repository();
      handler = ConsentSyncHandler(
        repository: repo,
        remote: DioConsentRemoteDataSource(
          createApiDio(testBaseUrl, adapter: server),
        ),
        now: () => now,
      );
    });

    test('sends the stored body and marks the decision synced', () async {
      syncOn = true;
      await repo.record(decision('6d9c0a3e-0c1f-4b8e-9a51-2a6f0f8d1001'));
      server.handler = (request) {
        expect(request.method, 'POST');
        expect(request.path, '/v1/consents');
        expect(
          (request.body! as Map<String, Object?>)['id'],
          '6d9c0a3e-0c1f-4b8e-9a51-2a6f0f8d1001',
        );
        return FakeResponse.json({'replayed': false}, status: 201);
      };
      final operation = (await outbox.due(now)).single;

      await handler.send(operation);
      await outbox.complete(
        operation.id,
        onSent: () => handler.markSent(operation),
      );

      expect(await repo.watchUnsyncedCount().first, 0);
    });

    test('merges server history before queuing local decisions', () async {
      await repo.record(decision('local'));
      server.handler = (request) {
        expect(request.path, '/v1/consents/history');
        return FakeResponse.json([decision('remote', minute: 1).toJson()]);
      };
      syncOn = true;

      await handler.prepareForSync();

      expect((await repo.log()).map((d) => d.id), ['local', 'remote']);
      expect((await outbox.due(now)).map((o) => o.id), ['local']);
    });

    test(
      'still queues local decisions when the history is unreachable',
      () async {
        await repo.record(decision('local'));
        server.handler = (request) => throw const SocketException('offline');
        syncOn = true;

        await handler.prepareForSync();

        expect((await outbox.due(now)).map((o) => o.id), ['local']);
      },
    );

    test('an unreadable history is a server failure', () async {
      server.handler = (request) => FakeResponse.json({'not': 'a list'});
      await expectLater(
        DioConsentRemoteDataSource(createApiDio(testBaseUrl, adapter: server))
            .history(),
        throwsA(isA<ServerFailure>()),
      );
    });
  });
}
