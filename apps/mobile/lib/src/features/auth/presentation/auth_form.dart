import 'package:material_ui/material_ui.dart';

import '../../../../l10n/generated/app_localizations.dart';

/// Matches the API's email check, so most mistakes are caught offline.
final RegExp _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

const int passwordMinLength = 12;
const int passwordMaxLength = 128;

String? validateEmail(AppLocalizations l10n, String? value) {
  final email = value?.trim() ?? '';
  return email.length <= 254 && _email.hasMatch(email)
      ? null
      : l10n.validationEmail;
}

String? validateNewPassword(AppLocalizations l10n, String? value) {
  final length = value?.length ?? 0;
  return length >= passwordMinLength && length <= passwordMaxLength
      ? null
      : l10n.validationPasswordLength;
}

String? validateExistingPassword(AppLocalizations l10n, String? value) =>
    value == null || value.isEmpty ? l10n.validationPasswordRequired : null;

/// A password field with a labeled show/hide button.
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    required this.label,
    this.helperText,
    this.validator,
    this.autofillHints = const [AutofillHints.password],
    this.textInputAction = TextInputAction.done,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final String? helperText;
  final FormFieldValidator<String>? validator;
  final Iterable<String> autofillHints;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TextFormField(
      controller: widget.controller,
      obscureText: !_visible,
      enableSuggestions: false,
      autocorrect: false,
      autofillHints: widget.autofillHints,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onSubmitted,
      validator: widget.validator,
      decoration: InputDecoration(
        labelText: widget.label,
        helperText: widget.helperText,
        helperMaxLines: 2,
        suffixIcon: IconButton(
          icon: Icon(_visible ? Icons.visibility_off : Icons.visibility),
          tooltip: _visible ? l10n.hidePassword : l10n.showPassword,
          onPressed: () => setState(() => _visible = !_visible),
        ),
      ),
    );
  }
}

/// An error message that screen readers announce when it appears.
class FormErrorBanner extends StatelessWidget {
  const FormErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: scheme.onErrorContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: scheme.onErrorContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
