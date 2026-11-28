import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flowwave_mobile/src/core/errors/app_failure.dart';
import 'package:flowwave_mobile/src/core/errors/error_mapper.dart';
import 'package:flowwave_mobile/src/core/network/api_dio.dart';
import 'package:flowwave_mobile/src/core/network/auth_interceptor.dart';
import 'package:flowwave_mobile/src/features/auth/data/dio_auth_api.dart';
import 'package:flowwave_mobile/src/features/auth/domain/auth_session.dart';
import 'package:flowwave_mobile/src/features/auth/domain/logout_cleanup.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/auth_fakes.dart';
import '../../support/fake_http_adapter.dart';

void main() {
  late TestClock clock;
  late InMemoryTokenStore store;
  late FakeHttpAdapter server;

  AuthSession session({LogoutCleanup? cleanup}) => AuthSession(
    api: DioAuthApi(dio: createApiDio(testBaseUrl, adapter: server)),
    store: store,
    cleanup: cleanup,
    now: clock.now,
  );

  /// An authenticated client for other endpoints, like the app's.
  Dio apiFor(AuthSession auth) {
    final dio = createApiDio(testBaseUrl, adapter: server);
    dio.interceptors.add(AuthInterceptor(tokens: auth, dio: dio));
    return dio;
  }

  setUp(() {
    clock = TestClock();
    store = InMemoryTokenStore();
    server = FakeHttpAdapter();
  });

  group('sign-in', () {
    test('stores the tokens in the token store and reports the user', () async {
      final issued = tokensFor(1, clock.now());
      server.handler = (request) {
        expect(request.path, '/v1/auth/login');
        expect(request.body, {
          'email': 'tester@example.org',
          'password': 'long password 1',
          'device': {'platform': 'android'},
        });
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

    test('registers with the home time zone', () async {
      server.handler = (request) {
        expect(request.path, '/v1/auth/register');
        expect(
          (request.body! as Map<String, Object?>)['homeTimeZone'],
          'Europe/Warsaw',
        );
        return tokenResponse(tokensFor(1, clock.now()), status: 201);
      };
      final auth = session();
      await auth.register(
        email: 'tester@example.org',
        password: 'long password 1',
        homeTimeZone: 'Europe/Warsaw',
      );
      expect(auth.isSignedIn, isTrue);
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
      server.handler = (request) => unauthorized('invalid_credentials');
      final auth = session();
      await expectLater(
        auth.signIn(email: 'tester@example.org', password: 'wrong password'),
        throwsA(const AppFailure.unauthorized(reason: 'invalid_credentials')),
      );
      expect(auth.isSignedIn, isFalse);
      expect(store.tokens, isNull);
    });

    test('an email that is already registered is a conflict', () async {
      server.handler = (request) => FakeResponse.json({
        'statusCode': 409,
        'error': 'conflict',
        'message': 'An account with this email already exists.',
        'field': 'email',
      }, status: 409);
      await expectLater(
        session().register(
          email: 'tester@example.org',
          password: 'long password 1',
          homeTimeZone: 'Europe/Warsaw',
        ),
        throwsA(const AppFailure.conflict(field: 'email')),
      );
    });

    test('a malformed token response is a server failure', () async {
      server.handler = (request) => FakeResponse.json({'accessToken': 'x'});
      await expectLater(
        session().signIn(email: 'a@b.cd', password: 'long password 1'),
        throwsA(isA<ServerFailure>()),
      );
    });
  });

  group('automatic refresh', () {
    test('uses the access token until shortly before it expires', () async {
      store.tokens = tokensFor(1, clock.now());
      server.handler = (request) => tokenResponse(tokensFor(2, clock.now()));
      final auth = session();
      await auth.restore();

      expect(await auth.accessToken(), 'fwat_access1');
      expect(server.requests, isEmpty);

      clock.advance(const Duration(minutes: 14, seconds: 1));
      expect(await auth.accessToken(), 'fwat_access2');
      expect(server.paths, ['/v1/auth/refresh']);
      expect(server.requests.single.body, {'refreshToken': 'fwrt_refresh1'});
      expect(
        store.tokens?.refreshToken,
        'fwrt_refresh2',
        reason: 'the rotated pair replaces the old one',
      );
    });

    test('concurrent callers share one refresh request', () async {
      store.tokens = tokensFor(1, clock.now());
      final release = Completer<void>();
      server.handler = (request) async {
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
        server.requests,
        hasLength(1),
        reason: 'a second use of a refresh token would end the session',
      );
    });

    test('signs out locally when the server ends the session', () async {
      store.tokens = tokensFor(1, clock.now());
      server.handler = (request) => unauthorized('refresh_token_reused');
      var cleaned = false;
      final cleanup = LogoutCleanup()
        ..register('local-data', () async => cleaned = true);
      final auth = session(cleanup: cleanup);
      await auth.restore();
      clock.advance(const Duration(minutes: 15));

      await expectLater(
        auth.accessToken(),
        throwsA(const AppFailure.notSignedIn(reason: 'refresh_token_reused')),
      );
      expect(auth.isSignedIn, isFalse);
      expect(store.tokens, isNull);
      expect(cleaned, isTrue);
    });

    test('keeps the session when offline, so it can refresh later', () async {
      store.tokens = tokensFor(1, clock.now());
      server.handler = (request) => throw const SocketException('offline');
      final auth = session();
      await auth.restore();
      clock.advance(const Duration(minutes: 15));

      await expectLater(
        auth.accessToken(),
        throwsA(const AppFailure.network()),
      );
      expect(auth.isSignedIn, isTrue);
      expect(store.tokens?.refreshToken, 'fwrt_refresh1');
    });
  });

  group('authenticated requests', () {
    test(
      'add the token and retry once with a refreshed token after a 401',
      () async {
        store.tokens = tokensFor(1, clock.now());
        final seen = <String?>[];
        server.handler = (request) {
          if (request.path == '/v1/auth/refresh') {
            return tokenResponse(tokensFor(2, clock.now()));
          }
          seen.add(request.authorization);
          if (request.authorization == 'Bearer fwat_access1') {
            return unauthorized('session_revoked');
          }
          expect(request.body, {'value': 1}, reason: 'the retry repeats it');
          return FakeResponse.json({});
        };
        final auth = session();
        await auth.restore();

        final response = await apiFor(auth)
            .post<Object?>('v1/sync', data: {'value': 1});

        expect(response.statusCode, 200);
        expect(seen, ['Bearer fwat_access1', 'Bearer fwat_access2']);
      },
    );

    test('do not retry a second time', () async {
      store.tokens = tokensFor(1, clock.now());
      server.handler = (request) => request.path == '/v1/auth/refresh'
          ? tokenResponse(tokensFor(2, clock.now()))
          : unauthorized('session_revoked');
      final auth = session();
      await auth.restore();

      final error = await apiFor(auth)
          .get<Object?>('v1/account')
          .then<Object?>((_) => null, onError: (Object e) => e);

      expect(mapError(error!), isA<UnauthorizedFailure>());
      expect(server.paths, ['/v1/account', '/v1/auth/refresh', '/v1/account']);
    });

    test('never reach the network without a session', () async {
      final error = await apiFor(session())
          .get<Object?>('v1/account')
          .then<Object?>((_) => null, onError: (Object e) => e);
      expect(mapError(error!), const AppFailure.notSignedIn());
      expect(server.requests, isEmpty);
    });
  });

  group('sign-out', () {
    test('ends the server session, deletes the tokens, and runs every cleanup task', () async {
      store.tokens = tokensFor(1, clock.now());
      server.handler = (request) {
        expect(request.path, '/v1/auth/logout');
        expect(request.authorization, 'Bearer fwat_access1');
        return const FakeResponse.empty();
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
      server.handler = (request) => throw const SocketException('offline');
      final auth = session();
      await auth.restore();

      await auth.signOut();

      expect(auth.isSignedIn, isFalse);
      expect(store.tokens, isNull);
    });

    test('can sign out every device', () async {
      store.tokens = tokensFor(1, clock.now());
      server.handler = (request) => FakeResponse.json({'sessionsRevoked': 2});
      final auth = session();
      await auth.restore();

      await auth.signOut(allDevices: true);

      expect(server.paths, ['/v1/auth/logout-all']);
      expect(store.tokens, isNull);
    });

    test('signing out locally makes no request', () async {
      store.tokens = tokensFor(1, clock.now());
      final auth = session();
      await auth.restore();

      await auth.signOutLocally();

      expect(server.requests, isEmpty);
      expect(auth.isSignedIn, isFalse);
    });
  });

  test('without a configured API every call fails as not configured', () {
    expect(
      const UnconfiguredAuthApi().login(email: 'a@b.cd', password: 'x'),
      throwsA(const AppFailure.notConfigured()),
    );
  });
}
