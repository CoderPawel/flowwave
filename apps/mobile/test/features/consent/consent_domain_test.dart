import 'dart:convert';
import 'dart:io';

import 'package:flowwave_mobile/src/core/time/zoned_timestamp.dart';
import 'package:flowwave_mobile/src/features/consent/domain/consent_catalog.dart';
import 'package:flowwave_mobile/src/features/consent/domain/consent_decision.dart';
import 'package:flowwave_mobile/src/features/consent/domain/consent_status.dart';
import 'package:flutter_test/flutter_test.dart';

final _at = ZonedTimestamp.at(
  DateTime.utc(2026, 11, 28, 9),
  timeZone: 'Europe/Warsaw',
  utcOffsetMinutes: 60,
);

void main() {
  group('shared consent vectors from packages/core', () {
    // `flutter test` runs in apps/mobile.
    final vectors = jsonDecode(
      File('../../packages/core/test-vectors/consent-status.json')
          .readAsStringSync(),
    ) as Map<String, Object?>;

    test('list the same consent text versions as the app', () {
      expect(vectors['currentPolicyVersions'], {
        for (final entry in currentConsentPolicyVersions.entries)
          entry.key.wireName: entry.value,
      });
    });

    test('list the same health data sources and scopes as the app', () {
      expect(vectors['healthDataSources'], healthDataSourceScopes);
    });

    for (final raw in vectors['cases']! as List<Object?>) {
      final vector = raw! as Map<String, Object?>;
      test(vector['name']! as String, () {
        final subject = vector['subject']! as Map<String, Object?>;
        final expected = vector['expected']! as Map<String, Object?>;
        final log = [
          for (final entry in vector['log']! as List<Object?>)
            ConsentDecision.fromJson(entry! as Map<String, Object?>),
        ];
        final state = consentState(
          log,
          ConsentType.fromWireName(subject['type']! as String)!,
          sourceId: subject['sourceId'] as String?,
        );
        expect(switch (state.status) {
          ConsentStatus.granted => 'granted',
          ConsentStatus.revoked => 'revoked',
          ConsentStatus.notAsked => 'not_asked',
          ConsentStatus.outdated => 'outdated',
        }, expected['status']);
        expect(state.scopes, expected['scopes']);
      });
    }
  });

  group('creating decisions', () {
    test('serializes to the body of POST /v1/consents', () {
      final decision = ConsentDecision.create(
        id: '6d9c0a3e-0c1f-4b8e-9a51-2a6f0f8d1001',
        type: ConsentType.healthData,
        sourceId: healthConnectSourceId,
        state: ConsentState.granted,
        scopes: const ['steps', 'heart_rate', 'steps'],
        decidedAt: _at,
      );
      expect(jsonDecode(jsonEncode(decision.toJson())), {
        'id': '6d9c0a3e-0c1f-4b8e-9a51-2a6f0f8d1001',
        'type': 'health_data',
        'sourceId': 'health_connect',
        'state': 'granted',
        'scopes': ['heart_rate', 'steps'],
        'policyVersion': '2026-11-26',
        'decidedAt': {
          'utc': '2026-11-28T09:00:00.000Z',
          'timeZone': 'Europe/Warsaw',
          'utcOffsetMinutes': 60,
        },
      });
    });

    test('uses the current text version for each type', () {
      final decision = ConsentDecision.create(
        id: 'id',
        type: ConsentType.analytics,
        state: ConsentState.granted,
        decidedAt: _at,
      );
      expect(decision.policyVersion, '2026-11-28');
      expect(decision.toJson()['type'], 'analytics');
    });

    test('rejects decisions the API would refuse', () {
      ConsentDecision create({
        ConsentType type = ConsentType.healthData,
        String? sourceId = healthConnectSourceId,
        ConsentState state = ConsentState.granted,
        List<String> scopes = const ['steps'],
      }) => ConsentDecision.create(
        id: 'id',
        type: type,
        sourceId: sourceId,
        state: state,
        scopes: scopes,
        decidedAt: _at,
      );

      expect(() => create(sourceId: null), throwsArgumentError);
      expect(() => create(sourceId: 'mi_fitness'), throwsArgumentError);
      expect(() => create(scopes: const []), throwsArgumentError);
      expect(() => create(scopes: const ['location']), throwsArgumentError);
      expect(
        () => create(state: ConsentState.revoked),
        throwsArgumentError,
        reason: 'a withdrawal lists no scopes',
      );
      expect(
        () => create(type: ConsentType.notifications, sourceId: null),
        throwsArgumentError,
        reason: 'only health data has scopes',
      );
      expect(
        () => create(type: ConsentType.analytics, scopes: const []),
        throwsArgumentError,
        reason: 'only health data has a source',
      );
    });
  });
}
