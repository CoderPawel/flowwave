import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../app/failure_messages.dart';
import '../../../app/providers.dart';
import '../../../app/routes.dart';
import '../../../core/errors/error_mapper.dart';

/// Marks onboarding complete. The router then leaves the welcome flow.
Future<void> completeOnboarding(WidgetRef ref) => ref
    .read(settingsRepositoryProvider)
    .completeOnboarding(ref.read(zonedClockProvider).nowUtc());

/// Welcome flow step: what FlowWave does, then the optional account.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pages = PageController();
  int _page = 0;
  bool _finishing = false;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _finishWithoutAccount() async {
    setState(() => _finishing = true);
    try {
      await completeOnboarding(ref);
    } catch (error) {
      if (!mounted) return;
      setState(() => _finishing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            failureMessage(AppLocalizations.of(context), mapError(error)),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final accountsAvailable = ref.watch(apiBaseUrlProvider) != null;
    final pages = [
      (
        Icons.edit_note,
        l10n.onboardingCheckInTitle,
        l10n.onboardingCheckInBody,
      ),
      (Icons.insights, l10n.onboardingRhythmTitle, l10n.onboardingRhythmBody),
      (
        Icons.cloud_off,
        l10n.onboardingOfflineTitle,
        l10n.onboardingOfflineBody,
      ),
    ];
    final last = _page == pages.length - 1;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go(Routes.consents)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pages,
                onPageChanged: (page) => setState(() => _page = page),
                children: [
                  for (final (icon, title, body) in pages)
                    ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        Icon(icon, size: 64, color: theme.colorScheme.primary),
                        const SizedBox(height: 24),
                        Semantics(
                          header: true,
                          child: Text(
                            title,
                            style: theme.textTheme.headlineMedium,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          body,
                          style: theme.textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                ],
              ),
            ),
            Semantics(
              label: l10n.onboardingPageLabel(_page + 1, pages.length),
              excludeSemantics: true,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < pages.length; i++)
                    Container(
                      margin: const EdgeInsets.all(4),
                      width: i == _page ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _page
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: last
                    ? [
                        if (accountsAvailable) ...[
                          FilledButton(
                            onPressed: _finishing
                                ? null
                                : () => context.push(Routes.welcomeRegister),
                            child: Text(l10n.onboardingCreateAccount),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton(
                            onPressed: _finishing
                                ? null
                                : () => context.push(Routes.welcomeLogin),
                            child: Text(l10n.onboardingSignIn),
                          ),
                        ] else
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              l10n.accountsUnavailable,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _finishing ? null : _finishWithoutAccount,
                          child: Text(l10n.onboardingWithoutAccount),
                        ),
                      ]
                    : [
                        FilledButton(
                          onPressed: () => _pages.nextPage(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOut,
                          ),
                          child: Text(l10n.actionNext),
                        ),
                      ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
