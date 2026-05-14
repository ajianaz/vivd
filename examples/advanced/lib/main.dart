import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() => runApp(const AdvancedExample());

/// Advanced Vivd example — demonstrates all SDK features.
///
/// Screens:
/// 1. Home — feature cards linking to each demo
/// 2. Liveness — custom config + action progress + result
/// 3. Identity — register face + identify
/// 4. Settings — VivdConfig builder
class AdvancedExample extends StatelessWidget {
  const AdvancedExample({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vivd — Advanced Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
