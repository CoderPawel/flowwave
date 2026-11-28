import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../app/failure_messages.dart';
import '../../../app/providers.dart';
import '../../../core/errors/error_mapper.dart';
import '../domain/consent_catalog.dart';
import '../domain/consent_decision.dart';
import '../domain/consent_status.dart';
import 'consent_controller.dart';

/// The consent switches, used in the welcome flow and on the data and
/// privacy screen. Everything is off until the user switches it on.
class ConsentPanel extends ConsumerWidget {
  const ConsentPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final log = ref.watch(consentLogProvider);
    return switch (log) {
      AsyncData(:final value) => _ConsentSwitches(log: value),
      AsyncError(:final error) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          failureMessage(AppLocalizations.of(context), mapError(error)),
        ),
      ),
      _ => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
    };
  }
}

class _ConsentSwitches extends ConsumerWidget {
  const _ConsentSwitches({required this.log});

  final List<ConsentDecision> log;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(consentControllerProvider);

    Future<void> apply(Future<void> Function() change) async {
      try {
        await change();
      } catch (error) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failureMessage(l10n, mapError(error)))),
        );
      }
    }

    final health = consentState(
      log,
      ConsentType.healthData,
      sourceId: healthConnectSourceId,
    );
    final allScopes = healthDataSourceScopes[healthConnectSourceId]!;

    Widget simple(ConsentType type, String title, String body, IconData icon) {
      final state = consentState(log, type);
      return _ConsentSwitch(
        key: ValueKey('consent-${type.wireName}'),
        icon: icon,
        title: title,
        body: body,
        state: state,
        onChanged: (on) =>
            apply(() => controller.setGranted(type, granted: on)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ConsentSwitch(
          key: const ValueKey('consent-health_data'),
          icon: Icons.favorite_outline,
          title: l10n.consentHealthTitle,
          body: l10n.consentHealthBody,
          state: health,
          onChanged: (on) => apply(
            () => controller.setHealthScopes(
              healthConnectSourceId,
              on ? allScopes.toSet() : const {},
            ),
          ),
        ),
        if (health.isGranted)
          Padding(
            padding: const EdgeInsets.fromLTRB(72, 0, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.consentScopesLabel,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final scope in allScopes)
                      FilterChip(
                        key: ValueKey('scope-$scope'),
                        label: Text(_scopeLabel(l10n, scope)),
                        selected: health.scopes.contains(scope),
                        onSelected: (selected) {
                          final next = {...health.scopes};
                          selected ? next.add(scope) : next.remove(scope);
                          apply(
                            () => controller.setHealthScopes(
                              healthConnectSourceId,
                              next,
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
        simple(
          ConsentType.deviceUsage,
          l10n.consentDeviceUsageTitle,
          l10n.consentDeviceUsageBody,
          Icons.phone_android,
        ),
        simple(
          ConsentType.notifications,
          l10n.consentNotificationsTitle,
          l10n.consentNotificationsBody,
          Icons.notifications_none,
        ),
        simple(
          ConsentType.analytics,
          l10n.consentAnalyticsTitle,
          l10n.consentAnalyticsBody,
          Icons.bar_chart,
        ),
      ],
    );
  }

  static String _scopeLabel(AppLocalizations l10n, String scope) =>
      switch (scope) {
        'sleep_duration' => l10n.consentScopeSleepDuration,
        'steps' => l10n.consentScopeSteps,
        'heart_rate' => l10n.consentScopeHeartRate,
        'resting_heart_rate' => l10n.consentScopeRestingHeartRate,
        _ => scope,
      };
}

class _ConsentSwitch extends StatelessWidget {
  const _ConsentSwitch({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.state,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String body;
  final ConsentSubjectState state;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final outdated = state.status == ConsentStatus.outdated;
    return SwitchListTile(
      secondary: Icon(icon),
      title: Text(title),
      subtitle: Text(outdated ? '$body\n${l10n.consentOutdated}' : body),
      isThreeLine: true,
      value: state.isGranted,
      onChanged: onChanged,
    );
  }
}
