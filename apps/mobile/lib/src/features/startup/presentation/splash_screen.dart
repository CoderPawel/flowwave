import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../app/providers.dart';
import '../../../core/database/encrypted_database.dart';

/// Shown while local storage opens and the session is restored, and when
/// that fails. The router leaves this screen once startup succeeds.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final startup = ref.watch(startupProvider);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: switch (startup) {
              AsyncError(:final error) => _StartupProblem(error: error),
              _ => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.waves,
                    size: 72,
                    color: Theme.of(context).colorScheme.primary,
                    semanticLabel: l10n.appTitle,
                  ),
                  const SizedBox(height: 24),
                  CircularProgressIndicator(semanticsLabel: l10n.splashLoading),
                  const SizedBox(height: 16),
                  Text(l10n.splashLoading),
                ],
              ),
            },
          ),
        ),
      ),
    );
  }
}

class _StartupProblem extends ConsumerWidget {
  const _StartupProblem({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final keyLost = error is DatabaseKeyMismatchException;
    final noEncryption = error is EncryptionUnavailableException;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.error_outline, size: 56, color: theme.colorScheme.error),
        const SizedBox(height: 16),
        Semantics(
          header: true,
          child: Text(
            keyLost ? l10n.startupKeyLostTitle : l10n.startupFailedTitle,
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          keyLost
              ? l10n.startupKeyLostBody
              : noEncryption
              ? l10n.startupEncryptionUnavailableBody
              : l10n.startupFailedBody,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        if (keyLost)
          FilledButton(
            onPressed: () => _confirmReset(context, ref),
            child: Text(l10n.startupResetAction),
          )
        else
          FilledButton(
            onPressed: () => _retry(ref),
            child: Text(l10n.actionRetry),
          ),
      ],
    );
  }

  void _retry(WidgetRef ref) {
    ref.invalidate(appDatabaseProvider);
    ref.invalidate(startupProvider);
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.startupResetAction),
        content: Text(l10n.startupResetConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.actionDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(databaseResetterProvider)();
    _retry(ref);
  }
}
