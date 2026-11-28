import 'package:material_ui/material_ui.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../app/widgets/placeholder_view.dart';

/// Check-in placeholder; manual check-ins arrive in roadmap step 6.
class CheckInScreen extends StatelessWidget {
  const CheckInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PlaceholderView(
      title: l10n.navCheckIn,
      icon: Icons.edit_note,
      description: l10n.checkInPlaceholder,
    );
  }
}
