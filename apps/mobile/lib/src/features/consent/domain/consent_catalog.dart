import 'package:json_annotation/json_annotation.dart';

/// What a consent decision is about (decision 0014). The wire names match
/// `CONSENT_TYPES` in `@flowwave/core`.
@JsonEnum(fieldRename: FieldRename.snake)
enum ConsentType {
  healthData,
  deviceUsage,
  notifications,
  analytics;

  String get wireName => switch (this) {
    healthData => 'health_data',
    deviceUsage => 'device_usage',
    notifications => 'notifications',
    analytics => 'analytics',
  };

  static ConsentType? fromWireName(String name) {
    for (final type in values) {
      if (type.wireName == name) return type;
    }
    return null;
  }
}

enum ConsentState { granted, revoked }

/// `outdated`: granted under an older consent text, so the user must be
/// asked again before the feature may run.
enum ConsentStatus { granted, revoked, notAsked, outdated }

/// The consent text version the app shows for each type. Must equal
/// `CURRENT_CONSENT_POLICY_VERSIONS` in `@flowwave/core`; a test compares both
/// with `packages/core/test-vectors/consent-status.json`.
const Map<ConsentType, String> currentConsentPolicyVersions = {
  ConsentType.healthData: '2026-11-26',
  ConsentType.deviceUsage: '2026-11-28',
  ConsentType.notifications: '2026-11-28',
  ConsentType.analytics: '2026-11-28',
};

const String healthConnectSourceId = 'health_connect';

/// External health data sources and the only scopes FlowWave may read from
/// them, as in `EXTERNAL_DATA_SOURCES` in `@flowwave/core`. Declaring a
/// source collects nothing; Health Connect itself arrives in roadmap step 8.
const Map<String, List<String>> healthDataSourceScopes = {
  'apple_health': [
    'sleep_duration',
    'steps',
    'heart_rate',
    'resting_heart_rate',
  ],
  healthConnectSourceId: [
    'sleep_duration',
    'steps',
    'heart_rate',
    'resting_heart_rate',
  ],
};
