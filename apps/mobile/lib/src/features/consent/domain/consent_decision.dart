import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/time/zoned_timestamp.dart';
import 'consent_catalog.dart';

part 'consent_decision.freezed.dart';
part 'consent_decision.g.dart';

/// One immutable entry in the append-only consent log. Serializes to the body
/// of `POST /v1/consents` and parses `GET /v1/consents/history` items.
@freezed
abstract class ConsentDecision with _$ConsentDecision {
  const ConsentDecision._();

  const factory ConsentDecision({
    required String id,
    required ConsentType type,

    /// The external source for health data, otherwise `null`.
    String? sourceId,
    required ConsentState state,

    /// Granted scopes, sorted. Empty for revocations and types without
    /// scopes.
    @Default(<String>[]) List<String> scopes,
    required String policyVersion,
    required ZonedTimestamp decidedAt,
  }) = _ConsentDecision;

  factory ConsentDecision.fromJson(Map<String, Object?> json) =>
      _$ConsentDecisionFromJson(json);

  /// A new decision under the current consent text. Scopes are sorted and
  /// de-duplicated like the server does, so a replay compares equal.
  factory ConsentDecision.create({
    required String id,
    required ConsentType type,
    String? sourceId,
    required ConsentState state,
    Iterable<String> scopes = const [],
    required ZonedTimestamp decidedAt,
  }) {
    if ((type == ConsentType.healthData) != (sourceId != null)) {
      throw ArgumentError.value(
        sourceId,
        'sourceId',
        'Required for health data and not allowed for other types',
      );
    }
    final sorted = {...scopes}.toList()..sort();
    if (state == ConsentState.revoked && sorted.isNotEmpty) {
      throw ArgumentError.value(sorted, 'scopes', 'A withdrawal lists none');
    }
    if (type == ConsentType.healthData) {
      final allowed = healthDataSourceScopes[sourceId];
      if (allowed == null) {
        throw ArgumentError.value(sourceId, 'sourceId', 'Unknown source');
      }
      if (state == ConsentState.granted && sorted.isEmpty) {
        throw ArgumentError.value(sorted, 'scopes', 'A grant needs a scope');
      }
      final unknown = sorted.where((scope) => !allowed.contains(scope));
      if (unknown.isNotEmpty) {
        throw ArgumentError.value(sorted, 'scopes', 'Not offered: $unknown');
      }
    } else if (sorted.isNotEmpty) {
      throw ArgumentError.value(sorted, 'scopes', '$type has no scopes');
    }
    return ConsentDecision(
      id: id,
      type: type,
      sourceId: sourceId,
      state: state,
      scopes: sorted,
      policyVersion: currentConsentPolicyVersions[type]!,
      decidedAt: decidedAt,
    );
  }
}
