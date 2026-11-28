import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/check_in/presentation/check_in_screen.dart';
import '../features/consent/presentation/consent_selection_screen.dart';
import '../features/insights/presentation/insights_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/privacy/presentation/data_privacy_screen.dart';
import '../features/privacy/presentation/privacy_intro_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/startup/presentation/splash_screen.dart';
import '../features/timeline/presentation/timeline_screen.dart';
import '../features/today/presentation/today_screen.dart';
import 'home_shell.dart';
import 'providers.dart';
import 'routes.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<bool?>(null);
  ref.listen<bool?>(
    onboardingCompletedProvider,
    (_, next) => refresh.value = next,
    fireImmediately: true,
  );
  final router = GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    redirect: (context, state) => redirectFor(
      location: state.matchedLocation,
      onboardingCompleted: ref.read(onboardingCompletedProvider),
    ),
    routes: [
      GoRoute(
        path: Routes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: Routes.privacyIntro,
        builder: (context, state) => const PrivacyIntroScreen(),
      ),
      GoRoute(
        path: Routes.consents,
        builder: (context, state) => const ConsentSelectionScreen(),
      ),
      GoRoute(
        path: Routes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: Routes.welcomeLogin,
        builder: (context, state) => const LoginScreen(fromOnboarding: true),
      ),
      GoRoute(
        path: Routes.welcomeRegister,
        builder: (context, state) => const RegisterScreen(fromOnboarding: true),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => HomeShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.today,
                builder: (context, state) => const TodayScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.checkIn,
                builder: (context, state) => const CheckInScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.timeline,
                builder: (context, state) => const TimelineScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.insights,
                builder: (context, state) => const InsightsScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: Routes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: Routes.dataPrivacy,
        builder: (context, state) => const DataPrivacyScreen(),
      ),
      GoRoute(
        path: Routes.settingsLogin,
        builder: (context, state) => const LoginScreen(fromOnboarding: false),
      ),
      GoRoute(
        path: Routes.settingsRegister,
        builder: (context, state) =>
            const RegisterScreen(fromOnboarding: false),
      ),
    ],
  );
  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});

/// Where to go instead of [location], or `null` to stay. Until startup
/// finishes ([onboardingCompleted] is `null`) only the startup screen shows;
/// until onboarding is complete only the welcome flow does.
String? redirectFor({
  required String location,
  required bool? onboardingCompleted,
}) {
  if (onboardingCompleted == null) {
    return location == Routes.splash ? null : Routes.splash;
  }
  final inWelcome = location.startsWith('${Routes.welcome}/');
  if (!onboardingCompleted) return inWelcome ? null : Routes.privacyIntro;
  if (location == Routes.splash || inWelcome) return Routes.today;
  return null;
}
