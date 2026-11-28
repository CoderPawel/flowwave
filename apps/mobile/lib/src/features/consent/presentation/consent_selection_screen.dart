import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../app/routes.dart';
import 'consent_panel.dart';

/// Welcome flow step: the user switches on only what they want.
class ConsentSelectionScreen extends StatelessWidget {
  const ConsentSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go(Routes.privacyIntro)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                    child: Semantics(
                      header: true,
                      child: Text(
                        l10n.consentTitle,
                        style: theme.textTheme.headlineMedium,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                    child: Text(l10n.consentLead),
                  ),
                  const ConsentPanel(),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      l10n.consentChangeLater,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => context.go(Routes.onboarding),
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
