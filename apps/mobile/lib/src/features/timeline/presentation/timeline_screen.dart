import 'package:material_ui/material_ui.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../app/widgets/placeholder_view.dart';

/// Timeline placeholder.
class TimelineScreen extends StatelessWidget {
  const TimelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PlaceholderView(
      title: l10n.navTimeline,
      icon: Icons.timeline,
      description: l10n.timelinePlaceholder,
    );
  }
}
