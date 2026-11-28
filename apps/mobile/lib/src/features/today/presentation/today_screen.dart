import 'package:material_ui/material_ui.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../app/widgets/placeholder_view.dart';

/// Today dashboard placeholder. Estimates arrive with the rhythm engine; the
/// disclaimer is shown from the start (AGENTS.md rules 1 and 2).
class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PlaceholderView(
      title: l10n.navToday,
      icon: Icons.wb_sunny_outlined,
      description: l10n.todayPlaceholder,
      footer: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline),
              const SizedBox(width: 12),
              Expanded(child: Text(l10n.disclaimer)),
            ],
          ),
        ),
      ),
    );
  }
}
