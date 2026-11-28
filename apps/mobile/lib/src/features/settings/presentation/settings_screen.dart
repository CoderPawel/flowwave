import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../app/failure_messages.dart';
import '../../../app/providers.dart';
import '../../../app/routes.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/errors/error_mapper.dart';
import '../domain/app_settings.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider).value ?? const AppSettings();
    final repository = ref.read(settingsRepositoryProvider);

    Future<void> save(Future<void> Function() change) async {
      try {
        await change();
      } catch (error) {
        if (!context.mounted) return;
        _showFailure(context, mapError(error));
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            _SectionHeader(l10n.settingsAppearance),
            _ChoiceTile<ThemePreference>(
              key: const ValueKey('theme-choice'),
              label: l10n.settingsTheme,
              selected: settings.theme,
              options: [
                (
                  ThemePreference.system,
                  l10n.themeSystem,
                  Icons.brightness_auto,
                ),
                (ThemePreference.light, l10n.themeLight, Icons.light_mode),
                (ThemePreference.dark, l10n.themeDark, Icons.dark_mode),
              ],
              onChanged: (theme) => save(() => repository.setTheme(theme)),
            ),
            _ChoiceTile<LanguagePreference>(
              key: const ValueKey('language-choice'),
              label: l10n.settingsLanguage,
              selected: settings.language,
              options: [
                (LanguagePreference.system, l10n.languageSystem, null),
                (LanguagePreference.en, l10n.languageEnglish, null),
                (LanguagePreference.pl, l10n.languagePolish, null),
              ],
              onChanged: (language) =>
                  save(() => repository.setLanguage(language)),
            ),
            const Divider(),
            _SectionHeader(l10n.settingsAccount),
            const _AccountSection(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.shield_outlined),
              title: Text(l10n.settingsDataPrivacy),
              subtitle: Text(l10n.settingsDataPrivacySubtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(Routes.dataPrivacy),
            ),
            const Divider(),
            _SectionHeader(l10n.settingsAbout),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(l10n.appTitle),
              subtitle: Text(l10n.disclaimer),
              isThreeLine: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountSection extends ConsumerWidget {
  const _AccountSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final configured = ref.watch(apiBaseUrlProvider) != null;
    final signedIn = ref.watch(isSignedInProvider);
    if (!configured) {
      return ListTile(
        leading: const Icon(Icons.cloud_off),
        title: Text(l10n.accountsUnavailable),
      );
    }
    if (!signedIn) {
      return Column(
        children: [
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(l10n.accountSignedOut),
          ),
          ListTile(
            leading: const Icon(Icons.login),
            title: Text(l10n.accountSignIn),
            onTap: () => context.push(Routes.settingsLogin),
          ),
          ListTile(
            leading: const Icon(Icons.person_add_alt),
            title: Text(l10n.accountCreate),
            onTap: () => context.push(Routes.settingsRegister),
          ),
        ],
      );
    }
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.cloud_done_outlined),
          title: Text(l10n.accountSignedIn),
        ),
        ListTile(
          leading: const Icon(Icons.logout),
          title: Text(l10n.accountSignOut),
          onTap: () => _signOut(context, ref, allDevices: false),
        ),
        ListTile(
          leading: const Icon(Icons.devices),
          title: Text(l10n.accountSignOutAll),
          onTap: () => _signOut(context, ref, allDevices: true),
        ),
      ],
    );
  }

  Future<void> _signOut(
    BuildContext context,
    WidgetRef ref, {
    required bool allDevices,
  }) async {
    final l10n = AppLocalizations.of(context);
    final pending =
        (await ref.read(outboxRepositoryProvider).summary()).pending;
    if (!context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.signOutDialogTitle),
        content: Text(
          [
            l10n.signOutDialogBody,
            if (pending > 0) l10n.signOutPendingWarning(pending),
          ].join('\n\n'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              allDevices ? l10n.accountSignOutAll : l10n.accountSignOut,
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final failed = await ref
        .read(authSessionProvider)
        .signOut(allDevices: allDevices);
    if (failed.isNotEmpty && context.mounted) {
      _showFailure(context, const AppFailure.storage());
    }
  }
}

void _showFailure(BuildContext context, AppFailure failure) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(failureMessage(AppLocalizations.of(context), failure)),
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Semantics(
        header: true,
        child: Text(
          text,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

/// A labeled single choice with segments that stay readable when the text
/// is enlarged.
class _ChoiceTile<T> extends StatelessWidget {
  const _ChoiceTile({
    super.key,
    required this.label,
    required this.selected,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final T selected;
  final List<(T, String, IconData?)> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<T>(
              showSelectedIcon: false,
              segments: [
                for (final (value, text, icon) in options)
                  ButtonSegment<T>(
                    value: value,
                    label: Text(text),
                    icon: icon == null ? null : Icon(icon),
                  ),
              ],
              selected: {selected},
              onSelectionChanged: (values) => onChanged(values.single),
            ),
          ),
        ],
      ),
    );
  }
}
