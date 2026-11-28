import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../app/routes.dart';

/// First screen of the welcome flow: how FlowWave treats data, before the
/// user is asked for any consent.
class PrivacyIntroScreen extends StatelessWidget {
  const PrivacyIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final points = [
      (Icons.phone_android, l10n.privacyIntroLocal),
      (Icons.toggle_on_outlined, l10n.privacyIntroConsent),
      (Icons.visibility_off_outlined, l10n.privacyIntroNoContent),
      (Icons.medical_information_outlined, l10n.privacyIntroNotMedical),
      (Icons.cloud_outlined, l10n.privacyIntroAccount),
    ];
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Semantics(
                    header: true,
                    child: Text(
                      l10n.privacyIntroTitle,
                      style: theme.textTheme.headlineMedium,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(l10n.privacyIntroLead, style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 16),
                  for (final (icon, text) in points)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(icon, color: theme.colorScheme.primary),
                      title: Text(text),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => context.go(Routes.consents),
                  child: Text(l10n.actionContinue),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
