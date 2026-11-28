import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flowwave_mobile/src/auth/auth_api.dart';
import 'package:flowwave_mobile/src/auth/auth_session.dart';
import 'package:flowwave_mobile/src/auth/authenticated_client.dart';
import 'package:flowwave_mobile/src/auth/logout_cleanup.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'fakes.dart';

void main() {
  late TestClock clock;
  late InMemoryTokenStore store;
  late List<http.Request> requests;
  late FutureOr<http.Response> Function(http.Request request) server;

  AuthSession session({LogoutCleanup? cleanup}) => AuthSession(
    api: AuthApi(
      baseUrl: testBaseUrl,
      client: MockClient((request) async {
        requests.add(request);
        return server(request);
      }),
    ),
    store: store,
    cleanup: cleanup,
    now: clock.now,
  );

  setUp(() {
    clock = TestClock();
    store = InMemoryTokenStore();
    requests = [];
    server = (request) => http.Response('', 500);
  });

  group('sign-in', () {
    test('stores the tokens in the token store and reports the user', () async {
      final issued = tokensFor(1, clock.now());
      server = (request) {
        expect(request.url.path, '/v1/auth/login');
        final body = jsonDecode(request.body) as Map<String, Object?>;
        expect(body['email'], 'tester@example.org');
        expect(body['device'], {'platform': 'android'});
        return tokenResponse(issued);
      };
      final auth = session();

      await auth.signIn(
        email: 'tester@example.org',
        password: 'long password 1',
      );

      expect(auth.isSignedIn, isTrue);
      expect(auth.userId, issued.userId);
      expect(store.tokens?.refreshToken, issued.refreshToken);
    });

    test(
      'restores a saved session and drops one whose refresh token expired',
      () async {
        store.tokens = tokensFor(1, clock.now());
        final auth = session();
        await auth.restore();
        expect(auth.isSignedIn, isTrue);

        clock.advance(const Duration(days: 31));
        final later = session();
        await later.restore();
        expect(later.isSignedIn, isFalse);
        expect(store.tokens, isNull);
      },
    );

    test('a wrong password leaves the user signed out', () async {
      server = (request) => unauthorized('invalid_credentials');
      final auth = session();
      await expectLater(
        auth.signIn(email: 'tester@example.org', password: 'wrong password'),
        throwsA(
          isA<AuthApiException>().having(
            (e) => e.reason,
            'reason',
            'invalid_credentials',
          ),
        ),
      );
      expect(auth.isSignedIn, isFalse);
      expect(store.tokens, isNull);
    });
  });

  group('automatic refresh', () {
    test('uses the access token until shortly before it expires', () async {
      store.tokens = tokensFor(1, clock.now());
      server = (request) => tokenResponse(tokensFor(2, clock.now()));
      final auth = session();
      await auth.restore();

      expect(await auth.accessToken(), 'fwat_access1');
      expect(requests, isEmpty);

      clock.advance(const Duration(minutes: 14, seconds: 1));
      expect(await auth.accessToken(), 'fwat_access2');
      expect(requests.single.url.path, '/v1/auth/refresh');
      expect(jsonDecode(requests.single.body), {
        'refreshToken': 'fwrt_refresh1',
      });
      expect(
        store.tokens?.refreshToken,
        'fwrt_refresh2',
        reason: 'the rotated pair replaces the old one',
      );
    });

    test('concurrent callers share one refresh request', () async {
      store.tokens = tokensFor(1, clock.now());
      final release = Completer<void>();
      server = (request) async {
        await release.future;
        return tokenResponse(tokensFor(2, clock.now()));
      };
      final auth = session();
      await auth.restore();
      clock.advance(const Duration(minutes: 15));

      final tokens = Future.wait([
        auth.accessToken(),
        auth.accessToken(),
        auth.refresh().then((t) => t.accessToken),
      ]);
      release.complete();

      expect(await tokens, ['fwat_access2', 'fwat_access2', 'fwat_access2']);
      expect(
        requests,
        hasLength(1),
        reason: 'a second use of a refresh token would end the session',
      );
    });

    test('signs out locally when the server ends the session', () async {
      store.tokens = tokensFor(1, clock.now());
      server = (request) => unauthorized('refresh_token_reused');
      var cleaned = false;
      final cleanup = LogoutCleanup()
        ..register('local-data', () async => cleaned = true);
      final auth = session(cleanup: cleanup);
      await auth.restore();
      clock.advance(const Duration(minutes: 15));

      await expectLater(
        auth.accessToken(),
        throwsA(
          isA<NotSignedInException>().having(
            (e) => e.reason,
            'reason',
            'refresh_token_reused',
          ),
        ),
      );
      expect(auth.isSignedIn, isFalse);
      expect(store.tokens, isNull);
      expect(cleaned, isTrue);
    });

    test('keeps the session when offline, so it can refresh later', () async {
      store.tokens = tokensFor(1, clock.now());
      server = (request) => throw http.ClientException('offline');
      final auth = session();
      await auth.restore();
      clock.advance(const Duration(minutes: 15));

      await expectLater(
        auth.accessToken(),
        throwsA(isA<AuthNetworkException>()),
      );
      expect(auth.isSignedIn, isTrue);
      expect(store.tokens?.refreshToken, 'fwrt_refresh1');
    });
  });

  group('authenticated client', () {
    test(
      'adds the token and retries once with a refreshed token after a 401',
      () async {
        store.tokens = tokensFor(1, clock.now());
        final seen = <String?>[];
        server = (request) {
          if (request.url.path == '/v1/auth/refresh') {
            return tokenResponse(tokensFor(2, clock.now()));
          }
          seen.add(request.headers['authorization']);
          if (request.headers['authorization'] == 'Bearer fwat_access1') {
            return unauthorized('session_revoked');
          }
          expect(
            request.body,
            '{"value":1}',
            reason: 'the retry repeats the body',
          );
          return http.Response('{}', 200);
        };
        final auth = session();
        await auth.restore();
        final api = AuthenticatedClient(
          auth,
          inner: MockClient((request) async {
            requests.add(request);
            return server(request);
          }),
        );

        final response = await api.post(
          testBaseUrl.resolve('v1/sync'),
          body: '{"value":1}',
        );

        expect(response.statusCode, 200);
        expect(seen, ['Bearer fwat_access1', 'Bearer fwat_access2']);
      },
    );

    test('does not call the API without a session', () async {
      final api = AuthenticatedClient(
        session(),
        inner: MockClient((request) async => http.Response('', 200)),
      );
      await expectLater(
        api.get(testBaseUrl.resolve('v1/account')),
        throwsA(isA<NotSignedInException>()),
      );
    });
  });

  group('sign-out', () {
    test('ends the server session, deletes the tokens, and runs every cleanup task', () async {
      store.tokens = tokensFor(1, clock.now());
      server = (request) {
        expect(request.url.path, '/v1/auth/logout');
        expect(request.headers['authorization'], 'Bearer fwat_access1');
        return http.Response('', 204);
      };
      final ran = <String>[];
      final cleanup = LogoutCleanup()
        ..register('check-ins', () async => ran.add('check-ins'))
        ..register(
          'broken',
          () async => throw const FileSystemException('locked'),
        )
        ..register('caches', () async => ran.add('caches'));
      final auth = session(cleanup: cleanup);
      await auth.restore();

      final failed = await auth.signOut();

      expect(auth.isSignedIn, isFalse);
      expect(store.tokens, isNull);
      expect(ran, [
        'check-ins',
        'caches',
      ], reason: 'a failing task does not stop the others');
      expect(failed, ['broken']);
    });

    test('completes locally when offline', () async {
      store.tokens = tokensFor(1, clock.now());
      server = (request) => throw http.ClientException('offline');
      final auth = session();
      await auth.restore();

      await auth.signOut();

      expect(auth.isSignedIn, isFalse);
      expect(store.tokens, isNull);
    });

    test('can sign out every device', () async {
      store.tokens = tokensFor(1, clock.now());
      server = (request) => http.Response('{"sessionsRevoked":2}', 200);
      final auth = session();
      await auth.restore();

      await auth.signOut(allDevices: true);

      expect(requests.single.url.path, '/v1/auth/logout-all');
      expect(store.tokens, isNull);
    });
  });
}
