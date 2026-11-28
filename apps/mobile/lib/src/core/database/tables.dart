import 'dart:convert';

import 'package:drift/drift.dart';

/// App preferences and first-start progress. Exactly one row (`id = 1`).
/// Not account data: kept at sign-out, removed by "delete data on this
/// device".
@DataClassName('LocalSettingsRow')
class LocalSettings extends Table {
  IntColumn get id => integer()();

  /// `system`, `light` or `dark`.
  TextColumn get themePreference =>
      text().withDefault(const Constant('system'))();

  /// `system`, `en` or `pl`.
  TextColumn get languagePreference =>
      text().withDefault(const Constant('system'))();

  /// When the user finished onboarding; `null` until then.
  DateTimeColumn get onboardingCompletedAtUtc => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => ['CHECK (id = 1)'];
}

/// The user's consent decisions on this phone, an append-only log like the
/// server's `consent_decisions` (decision 0014). Account data: removed at
/// sign-out.
@DataClassName('ConsentDecisionRow')
class ConsentDecisions extends Table {
  /// UUID generated on the phone; also the idempotency key of the upload.
  TextColumn get id => text()();

  /// `health_data`, `device_usage`, `notifications` or `analytics`.
  TextColumn get consentType => text()();

  /// The external source for `health_data`, otherwise `null`.
  TextColumn get sourceId => text().nullable()();

  /// `granted` or `revoked`.
  TextColumn get state => text()();

  /// Granted scopes as a JSON array; empty for revocations and other types.
  TextColumn get scopes => text().map(const StringListConverter())();

  TextColumn get policyVersion => text()();

  DateTimeColumn get decidedAtUtc => dateTime()();
  TextColumn get decidedTimeZone => text()();
  IntColumn get decidedUtcOffsetMinutes => integer()();

  /// When the server confirmed the decision; `null` while only on the phone.
  DateTimeColumn get syncedAtUtc => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// The offline write queue (decision 0007). Filled only while sync is on.
/// Account data: removed at sign-out.
@DataClassName('OutboxOperationRow')
class OutboxOperations extends Table {
  /// Operation ID, equal to the ID of the entity it uploads (rule 7).
  TextColumn get id => text()();

  /// Which transport sends it, for example `consent_decision`.
  TextColumn get kind => text()();

  /// The request body as JSON.
  TextColumn get payload => text()();

  DateTimeColumn get createdAtUtc => dateTime()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextAttemptAtUtc => dateTime()();

  /// `pending`, or `rejected` when the API refused it for good.
  TextColumn get status => text().withDefault(const Constant('pending'))();

  /// Stable failure code of the last attempt, never a server message.
  TextColumn get lastError => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class StringListConverter extends TypeConverter<List<String>, String> {
  const StringListConverter();

  @override
  List<String> fromSql(String fromDb) =>
      (jsonDecode(fromDb) as List<Object?>).cast<String>();

  @override
  String toSql(List<String> value) => jsonEncode(value);
}
