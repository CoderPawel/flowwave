import 'package:material_ui/material_ui.dart';

import 'home/home_screen.dart';

class FlowWaveApp extends StatelessWidget {
  const FlowWaveApp({super.key});

  static const Color _seed = Color(0xFF2F6F8F);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlowWave',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: _seed),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seed,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
