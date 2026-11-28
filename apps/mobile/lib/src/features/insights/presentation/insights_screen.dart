import 'package:material_ui/material_ui.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../app/widgets/placeholder_view.dart';

/// Insights placeholder. Insights will always name the factors they are
/// based on (AGENTS.md rule 10).
class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PlaceholderView(
      title: l10n.navInsights,
      icon: Icons.insights,
      description: l10n.insightsPlaceholder,
    );
  }
}
