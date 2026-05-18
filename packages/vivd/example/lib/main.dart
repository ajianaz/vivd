import 'package:flutter/material.dart';
import 'package:vivd/vivd.dart';

void main() => runApp(const BasicExample());

/// Basic Vivd example — minimal integration with default config.
///
/// This demonstrates the simplest possible integration:
/// 1. Add VivdLivenessDetector to your widget tree
/// 2. Handle the onResult callback
/// 3. Done.
class BasicExample extends StatelessWidget {
  const BasicExample({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vivd — Basic Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const LivenessScreen(),
    );
  }
}

class LivenessScreen extends StatelessWidget {
  const LivenessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vivd — Basic Example'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: VivdLivenessDetector(
        config: const VivdConfig(
          actions: [
            VivdAction.blink,
            VivdAction.headTurnLeft,
            VivdAction.headTurnRight,
            VivdAction.lookUp,
            VivdAction.lookDown,
            VivdAction.smile,
          ],
        ),
        onResult: (result) {
          // The widget shows the result view automatically.
          // You can also handle the result programmatically here.
          debugPrint('Result: ${result.isLive ? "LIVE" : "SPOOF"} '
              '(score: ${result.score})');
        },
        onProgress: (action, index, total) {
          debugPrint('Progress: ${action.label} (${index + 1}/$total)');
        },
      ),
    );
  }
}
