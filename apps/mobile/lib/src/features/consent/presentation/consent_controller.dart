import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/ids.dart';
import '../../../core/time/zoned_clock.dart';
import '../domain/consent_catalog.dart';
import '../domain/consent_decision.dart';
import '../domain/consent_repository.dart';

/// Turns switch changes into consent decisions. Each change is a new entry
/// in the append-only log, applied at once (decision 0015).
class ConsentController {
  ConsentController({required this._repository, required this._clock});

  final ConsentRepository _repository;
  final ZonedClock _clock;

  /// For types without a source: notifications, device usage, analytics.
  Future<void> setGranted(ConsentType type, {required bool granted}) async {
    await _repository.record(
      ConsentDecision.create(
        id: newUuid(),
        type: type,
        state: granted ? ConsentState.granted : ConsentState.revoked,
        decidedAt: await _clock.now(),
      ),
    );
  }

  /// Grants health data from [sourceId] for [scopes]; an empty set withdraws
  /// the consent.
  Future<void> setHealthScopes(String sourceId, Set<String> scopes) async {
    await _repository.record(
      ConsentDecision.create(
        id: newUuid(),
        type: ConsentType.healthData,
        sourceId: sourceId,
        state: scopes.isEmpty ? ConsentState.revoked : ConsentState.granted,
        scopes: scopes,
        decidedAt: await _clock.now(),
      ),
    );
  }
}

final consentControllerProvider = Provider<ConsentController>(
  (ref) => ConsentController(
    repository: ref.watch(consentRepositoryProvider),
    clock: ref.watch(zonedClockProvider),
  ),
);
