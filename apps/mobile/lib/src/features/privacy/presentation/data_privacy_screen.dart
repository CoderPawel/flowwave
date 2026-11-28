import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../app/failure_messages.dart';
import '../../../app/providers.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/sync/outbox_operation.dart';
import '../../../core/sync/sync_service.dart';
import '../../auth/presentation/auth_form.dart';
import '../../consent/presentation/consent_panel.dart';

/// Consents, what is stored where, sync state, and deletion (decision 0015).
class DataPrivacyScreen extends ConsumerWidget {
  const DataPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final signedIn = ref.watch(isSignedInProvider);
    final decisions = ref.watch(consentLogProvider).value?.length ?? 0;
    final outbox =
        ref.watch(outboxSummaryProvider).value ?? const OutboxSummary();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.dataPrivacyTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            _Header(l10n.dataPrivacyConsents),
            const ConsentPanel(),
            const Divider(),
            _Header(l10n.dataPrivacyOnPhone),
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: Text(l10n.dataPrivacyOnPhoneBody),
              subtitle: Text(l10n.dataPrivacyConsentCount(decisions)),
            ),
            const Divider(),
            _Header(l10n.dataPrivacySync),
            if (!signedIn)
              ListTile(
                leading: const Icon(Icons.cloud_off),
                title: Text(l10n.syncOff),
              )
            else ...[
              ListTile(
                key: const ValueKey('sync-status'),
                leading: Icon(
                  outbox.pending == 0
                      ? Icons.cloud_done_outlined
                      : Icons.cloud_upload_outlined,
                ),
                title: Text(l10n.syncPending(outbox.pending)),
                subtitle: outbox.rejected == 0
                    ? null
                    : Text(
                        l10n.syncRejected(outbox.rejected),
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.sync),
                    label: Text(l10n.syncNow),
                    onPressed: () => _syncNow(context, ref),
                  ),
                ),
              ),
            ],
            const Divider(),
            ListTile(
              leading: Icon(
                Icons.phonelink_erase,
                color: theme.colorScheme.error,
              ),
              title: Text(l10n.deleteLocalTitle),
              subtitle: Text(
                signedIn
                    ? l10n.deleteLocalBodySignedIn
                    : l10n.deleteLocalBodySignedOut,
              ),
              onTap: () => _deleteLocalData(context, ref, signedIn: signedIn),
            ),
            if (signedIn)
              ListTile(
                leading: Icon(
                  Icons.delete_forever_outlined,
                  color: theme.colorScheme.error,
                ),
                title: Text(l10n.deleteAccountTitle),
                subtitle: Text(l10n.deleteAccountBody),
                onTap: () => _deleteAccount(context, ref),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _syncNow(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final report = await ref.read(syncSchedulerProvider).syncNow();
    if (!context.mounted) return;
    final failure = report.failure;
    final message = switch (report.stop) {
      SyncStop.completed => l10n.syncDone,
      SyncStop.willRetry => l10n.syncWillRetry,
      SyncStop.needsSignIn || SyncStop.disabled => failureMessage(
        l10n,
        failure ?? const AppFailure.notSignedIn(),
      ),
    };
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _deleteLocalData(
    BuildContext context,
    WidgetRef ref, {
    required bool signedIn,
  }) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteLocalTitle),
        content: Text(
          signedIn
              ? l10n.deleteLocalBodySignedIn
              : l10n.deleteLocalBodySignedOut,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.actionDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(authSessionProvider).signOut();
      // Resets onboarding too, so the router returns to the welcome flow.
      await ref.read(databaseProvider).deleteEverything();
    } catch (error) {
      if (context.mounted) _showFailure(context, mapError(error));
    }
  }

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final deleted = await showDialog<bool>(
      context: context,
      builder: (context) => const _DeleteAccountDialog(),
    );
    if (deleted == true && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.deleteAccountDone)));
    }
  }
}

/// Asks for the password, deletes the account, then the local account data.
class _DeleteAccountDialog extends ConsumerStatefulWidget {
  const _DeleteAccountDialog();

  @override
  ConsumerState<_DeleteAccountDialog> createState() =>
      _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends ConsumerState<_DeleteAccountDialog> {
  final _form = GlobalKey<FormState>();
  final _password = TextEditingController();
  bool _busy = false;
  AppFailure? _failure;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !(_form.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _failure = null;
    });
    try {
      await ref
          .read(accountRepositoryProvider)
          .deleteAccount(password: _password.text);
      // The server has no session left to end.
      await ref.read(authSessionProvider).signOutLocally();
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _failure = mapError(error);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final failure = _failure;
    return AlertDialog(
      title: Text(l10n.deleteAccountTitle),
      content: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.deleteAccountBody),
              const SizedBox(height: 16),
              Text(l10n.deleteAccountPasswordPrompt),
              const SizedBox(height: 8),
              PasswordField(
                controller: _password,
                label: l10n.fieldPassword,
                validator: (value) => validateExistingPassword(l10n, value),
                onSubmitted: (_) => _submit(),
              ),
              if (failure != null) ...[
                const SizedBox(height: 16),
                FormErrorBanner(message: failureMessage(l10n, failure)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          onPressed: _busy ? null : _submit,
          child: Text(l10n.deleteAccountTitle),
        ),
      ],
    );
  }
}

void _showFailure(BuildContext context, AppFailure failure) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(failureMessage(AppLocalizations.of(context), failure)),
    ),
  );
}

class _Header extends StatelessWidget {
  const _Header(this.text);

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
