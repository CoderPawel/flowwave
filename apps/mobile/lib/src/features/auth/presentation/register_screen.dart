import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../app/failure_messages.dart';
import '../../../app/providers.dart';
import '../../../app/routes.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/errors/error_mapper.dart';
import '../../onboarding/presentation/onboarding_screen.dart';
import 'auth_form.dart';

/// The device's IANA time zone, sent as the account's home time zone.
final _homeTimeZoneProvider = FutureProvider.autoDispose<String>(
  (ref) => ref.watch(zonedClockProvider).timeZone(),
);

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key, required this.fromOnboarding});

  /// Opened from onboarding: registering also completes onboarding.
  final bool fromOnboarding;

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _repeat = TextEditingController();
  bool _busy = false;
  AppFailure? _failure;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _repeat.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !(_form.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _failure = null;
    });
    try {
      final zone = await ref.read(_homeTimeZoneProvider.future);
      await ref
          .read(authSessionProvider)
          .register(
            email: _email.text.trim(),
            password: _password.text,
            homeTimeZone: zone,
          );
      if (widget.fromOnboarding) {
        await completeOnboarding(ref);
      } else if (mounted) {
        context.pop();
      }
    } catch (error) {
      if (mounted) setState(() => _failure = mapError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final failure = _failure;
    final zone = ref.watch(_homeTimeZoneProvider).value;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.registerTitle)),
      body: SafeArea(
        child: Form(
          key: _form,
          child: AutofillGroup(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                if (failure != null) ...[
                  FormErrorBanner(message: failureMessage(l10n, failure)),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  autocorrect: false,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: l10n.fieldEmail,
                    helperText: l10n.registerEmailNote,
                    helperMaxLines: 2,
                  ),
                  validator: (value) => validateEmail(l10n, value),
                ),
                const SizedBox(height: 16),
                PasswordField(
                  controller: _password,
                  label: l10n.fieldPassword,
                  helperText: l10n.passwordHint,
                  autofillHints: const [AutofillHints.newPassword],
                  textInputAction: TextInputAction.next,
                  validator: (value) => validateNewPassword(l10n, value),
                ),
                const SizedBox(height: 16),
                PasswordField(
                  controller: _repeat,
                  label: l10n.fieldPasswordRepeat,
                  autofillHints: const [AutofillHints.newPassword],
                  validator: (value) => value == _password.text
                      ? null
                      : l10n.validationPasswordMismatch,
                  onSubmitted: (_) => _submit(),
                ),
                if (zone != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    l10n.registerTimeZoneNote(zone),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: _busy
                      ? SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            semanticsLabel: l10n.registerAction,
                          ),
                        )
                      : Text(l10n.registerAction),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => context.pushReplacement(
                          widget.fromOnboarding
                              ? Routes.welcomeLogin
                              : Routes.settingsLogin,
                        ),
                  child: Text(l10n.registerToLogin),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
