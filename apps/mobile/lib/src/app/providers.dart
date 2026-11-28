import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/config/api_config.dart';
import '../core/database/app_database.dart';
import '../core/database/database_key_store.dart';
import '../core/database/encrypted_database.dart';
import '../core/network/api_dio.dart';
import '../core/network/auth_interceptor.dart';
import '../core/sync/drift_outbox_repository.dart';
import '../core/sync/outbox_operation.dart';
import '../core/sync/outbox_repository.dart';
import '../core/sync/sync_scheduler.dart';
import '../core/sync/sync_service.dart';
import '../core/time/zoned_clock.dart';
import '../features/auth/data/dio_auth_api.dart';
import '../features/auth/data/secure_token_store.dart';
import '../features/auth/domain/auth_api.dart';
import '../features/auth/domain/auth_session.dart';
import '../features/auth/domain/logout_cleanup.dart';
import '../features/auth/domain/token_store.dart';
import '../features/consent/data/consent_sync_handler.dart';
import '../features/consent/data/dio_consent_remote_data_source.dart';
import '../features/consent/data/drift_consent_repository.dart';
import '../features/consent/domain/consent_decision.dart';
import '../features/consent/domain/consent_repository.dart';
import '../features/privacy/data/dio_account_repository.dart';
import '../features/privacy/domain/account_repository.dart';
import '../features/settings/data/drift_settings_repository.dart';
import '../features/settings/domain/app_settings.dart';
import '../features/settings/domain/settings_repository.dart';

// The composition root: every dependency is created here and overridden in
// tests. Screens read repositories through these providers only.

/// `null` when the build has no API: the app runs fully offline.
final apiBaseUrlProvider = Provider<Uri?>((ref) => apiBaseUrl());

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(),
);

final databaseKeyStoreProvider = Provider<DatabaseKeyStore>(
  (ref) => SecureDatabaseKeyStore(storage: ref.watch(secureStorageProvider)),
);

/// Opens the database. Tests replace it with an in-memory database.
final databaseOpenerProvider = Provider<Future<AppDatabase> Function()>(
  (ref) =>
      () => openEncryptedDatabase(keys: ref.read(databaseKeyStoreProvider)),
);

/// Deletes the database file and its key. Tests replace it.
final databaseResetterProvider = Provider<Future<void> Function()>(
  (ref) =>
      () => deleteDatabaseFiles(keys: ref.read(databaseKeyStoreProvider)),
);

/// Startup failures are shown to the user instead of retried silently: a
/// wrong database key never fixes itself.
Duration? _noRetry(int retryCount, Object error) => null;

final appDatabaseProvider = FutureProvider<AppDatabase>((ref) async {
  final database = await ref.watch(databaseOpenerProvider)();
  ref.onDispose(database.close);
  return database;
}, retry: _noRetry);

/// The open database. Only read after startup finished.
final databaseProvider = Provider<AppDatabase>(
  (ref) => ref.watch(appDatabaseProvider).requireValue,
);

final zonedClockProvider = Provider<ZonedClock>((ref) => DeviceZonedClock());

/// Replaced in tests with a fake transport.
final httpClientAdapterProvider = Provider<HttpClientAdapter?>((ref) => null);

Dio? _createDio(Ref ref) {
  final baseUrl = ref.watch(apiBaseUrlProvider);
  if (baseUrl == null) return null;
  final dio = createApiDio(
    baseUrl,
    adapter: ref.watch(httpClientAdapterProvider),
  );
  ref.onDispose(dio.close);
  return dio;
}

/// For the authentication endpoints, which take no access token.
final publicDioProvider = Provider<Dio?>(_createDio);

/// For every other endpoint: adds and refreshes the access token.
final authenticatedDioProvider = Provider<Dio?>((ref) {
  final dio = _createDio(ref);
  if (dio == null) return null;
  final AccessTokenSource tokens = ref.watch(authSessionProvider);
  dio.interceptors.add(AuthInterceptor(tokens: tokens, dio: dio));
  return dio;
});

final tokenStoreProvider = Provider<TokenStore>(
  (ref) => SecureTokenStore(storage: ref.watch(secureStorageProvider)),
);

final authApiProvider = Provider<AuthApi>((ref) {
  final dio = ref.watch(publicDioProvider);
  return dio == null ? const UnconfiguredAuthApi() : DioAuthApi(dio: dio);
});

/// Account data removed from the phone at sign-out (decision 0013). Each
/// feature that stores account data adds its table here.
final Provider<LogoutCleanup> logoutCleanupProvider = Provider<LogoutCleanup>(
  (ref) => LogoutCleanup()
    ..register(
      'outbox_operations',
      () => ref.read(outboxRepositoryProvider).deleteAll(),
    )
    ..register(
      'consent_decisions',
      () => ref.read(consentRepositoryProvider).deleteAll(),
    ),
);

final Provider<AuthSession> authSessionProvider = Provider<AuthSession>((ref) {
  final session = AuthSession(
    api: ref.watch(authApiProvider),
    store: ref.watch(tokenStoreProvider),
    cleanup: ref.watch(logoutCleanupProvider),
    now: ref.watch(zonedClockProvider).nowUtc,
  );
  ref.onDispose(session.dispose);
  return session;
});

/// Rebuilds dependents when the user signs in or out.
final isSignedInProvider = Provider<bool>((ref) {
  final session = ref.watch(authSessionProvider);
  void changed() => ref.invalidateSelf();
  session.addListener(changed);
  ref.onDispose(() => session.removeListener(changed));
  return session.isSignedIn;
});

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => DriftSettingsRepository(ref.watch(databaseProvider)),
);

final settingsProvider = StreamProvider<AppSettings>(
  (ref) => ref.watch(settingsRepositoryProvider).watch(),
);

final outboxRepositoryProvider = Provider<OutboxRepository>(
  (ref) => DriftOutboxRepository(ref.watch(databaseProvider)),
);

final outboxSummaryProvider = StreamProvider<OutboxSummary>(
  (ref) => ref.watch(outboxRepositoryProvider).watchSummary(),
);

final Provider<ConsentRepository> consentRepositoryProvider =
    Provider<ConsentRepository>(
      (ref) => DriftConsentRepository(
        db: ref.watch(databaseProvider),
        outbox: ref.watch(outboxRepositoryProvider),
        // Read lazily: the session's sign-out cleanup uses this repository,
        // so watching the session here would be a dependency cycle.
        isSyncEnabled: () => ref.read(authSessionProvider).isSignedIn,
        now: ref.watch(zonedClockProvider).nowUtc,
      ),
    );

final consentLogProvider = StreamProvider<List<ConsentDecision>>(
  (ref) => ref.watch(consentRepositoryProvider).watchLog(),
);

final consentRemoteProvider = Provider<ConsentRemoteDataSource>((ref) {
  final dio = ref.watch(authenticatedDioProvider);
  return dio == null
      ? const UnconfiguredConsentRemoteDataSource()
      : DioConsentRemoteDataSource(dio);
});

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  final dio = ref.watch(authenticatedDioProvider);
  return dio == null
      ? const UnconfiguredAccountRepository()
      : DioAccountRepository(dio);
});

final consentSyncHandlerProvider = Provider<ConsentSyncHandler>(
  (ref) => ConsentSyncHandler(
    repository: ref.watch(consentRepositoryProvider),
    remote: ref.watch(consentRemoteProvider),
    now: ref.watch(zonedClockProvider).nowUtc,
  ),
);

final syncSchedulerProvider = Provider<SyncScheduler>((ref) {
  final session = ref.watch(authSessionProvider);
  final outbox = ref.watch(outboxRepositoryProvider);
  final consent = ref.watch(consentSyncHandlerProvider);
  final now = ref.watch(zonedClockProvider).nowUtc;
  final scheduler = SyncScheduler(
    service: SyncService(
      outbox: outbox,
      handlers: [consent],
      isEnabled: () => session.isSignedIn,
      now: now,
    ),
    outbox: outbox,
    participants: [consent],
    now: now,
  );
  var signedIn = session.isSignedIn;
  void authChanged() {
    if (session.isSignedIn && !signedIn) unawaited(scheduler.onSyncEnabled());
    signedIn = session.isSignedIn;
  }

  session.addListener(authChanged);
  ref.onDispose(() {
    session.removeListener(authChanged);
    unawaited(scheduler.dispose());
  });
  return scheduler;
});

/// Opens storage, restores the session and starts sync. The router shows
/// the startup screen until this completes.
final startupProvider = FutureProvider<AppSettings>((ref) async {
  await ref.watch(appDatabaseProvider.future);
  final session = ref.read(authSessionProvider);
  await session.restore();
  final settings = await ref.read(settingsRepositoryProvider).load();
  final scheduler = ref.read(syncSchedulerProvider)..start();
  if (session.isSignedIn) unawaited(scheduler.onSyncEnabled());
  return settings;
}, retry: _noRetry);

/// `null` while starting; then whether onboarding is complete.
final onboardingCompletedProvider = Provider<bool?>((ref) {
  final startup = ref.watch(startupProvider);
  if (!startup.hasValue || startup.hasError) return null;
  final settings = ref.watch(settingsProvider).value ?? startup.requireValue;
  return settings.onboardingCompleted;
});
