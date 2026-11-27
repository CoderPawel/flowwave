import 'package:material_ui/material_ui.dart';

/// Placeholder until the check-in flow (roadmap step 6) replaces it.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const String disclaimer =
      'FlowWave shows personal rhythm estimates based on the data you choose '
      'to share. They are not medical assessments or diagnoses.';

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('FlowWave')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your energy and focus rhythm',
                style: textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(
                'Check-ins and rhythm insights are coming soon. '
                'Everything you record will stay on this device until you choose to sync.',
                style: textTheme.bodyLarge,
              ),
              const Spacer(),
              Text(disclaimer, style: textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
