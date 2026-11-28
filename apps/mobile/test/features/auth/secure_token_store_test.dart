import 'package:flowwave_mobile/src/core/config/api_config.dart';
import 'package:flowwave_mobile/src/features/auth/data/secure_token_store.dart';
import 'package:flowwave_mobile/src/features/auth/domain/auth_tokens.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/auth_fakes.dart';

void main() {
  late Map<String, String> platformData;

  setUp(() {
    platformData = {};
    // The in-memory platform keeps this map, so the test sees what was stored.
    FlutterSecureStorage.setMockInitialValues(platformData);
  });

  test('round-trips tokens through secure storage under one key', () async {
    final store = SecureTokenStore();
    final tokens = tokensFor(1, DateTime.utc(2026, 11, 28, 9));

    await store.write(tokens);
    expect(platformData.keys, [SecureTokenStore.storageKey]);

    final read = await store.read();
    expect(read?.toJson(), tokens.toJson());

    await store.clear();
    expect(platformData, isEmpty);
    expect(await store.read(), isNull);
  });

  test('treats unreadable stored data as signed out and removes it', () async {
    platformData[SecureTokenStore.storageKey] = '{"accessToken":';
    final store = SecureTokenStore();
    expect(await store.read(), isNull);
    expect(platformData, isEmpty);
  });

  test('token responses must carry every field with UTC instants', () {
    final json = tokensFor(1, DateTime.utc(2026, 11, 28, 9)).toJson();
    expect(
      () => AuthTokens.fromJson({...json, 'refreshToken': null}),
      throwsFormatException,
    );
    expect(
      () => AuthTokens.fromJson({
        ...json,
        'accessTokenExpiresAt': '2026-11-28T09:15:00',
      }),
      throwsFormatException,
      reason: 'a local time without zone is ambiguous',
    );
  });

  test('never prints token values', () {
    final tokens = tokensFor(1, DateTime.utc(2026, 11, 28, 9));
    expect(tokens.toString(), isNot(contains('fwat_')));
    expect(tokens.toString(), isNot(contains('fwrt_')));
  });

  test('runs without an API when no base URL is configured', () {
    expect(apiBaseUrl(), isNull);
  });
}
