import 'package:flutter/material.dart';
import 'package:vivd/vivd.dart';

/// Settings screen — VivdConfig parameter builder with descriptions.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _confirmationFrames = 3;
  int _maxSessionMs = 30000;
  int _actionTimeoutMs = 10000;
  double _passThreshold = 0.7;
  bool _enableAntiSpoof = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('VivdConfig Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'VivdConfig Parameters',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Configure the Vivd SDK behavior. These values are reference — '
            'the Liveness screen uses its own config state.',
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 24),

          // Confirmation frames
          _SettingsSlider(
            title: 'Confirmation Frames',
            subtitle: 'Minimum frames to confirm an action (default: 3)',
            icon: Icons.repeat,
            value: _confirmationFrames.toDouble(),
            min: 1,
            max: 10,
            divisions: 9,
            label: _confirmationFrames.toString(),
            onChanged: (v) =>
                setState(() => _confirmationFrames = v.toInt()),
          ),
          const SizedBox(height: 8),

          // Max session duration
          _SettingsSlider(
            title: 'Max Session Duration',
            subtitle: 'Maximum time for the entire session (ms)',
            icon: Icons.timer,
            value: _maxSessionMs.toDouble(),
            min: 10000,
            max: 60000,
            divisions: 10,
            label: '${(_maxSessionMs / 1000).round()}s',
            onChanged: (v) => setState(() => _maxSessionMs = v.toInt()),
          ),
          const SizedBox(height: 8),

          // Action timeout
          _SettingsSlider(
            title: 'Action Timeout',
            subtitle: 'Timeout per individual action (ms)',
            icon: Icons.hourglass_top,
            value: _actionTimeoutMs.toDouble(),
            min: 3000,
            max: 20000,
            divisions: 17,
            label: '${(_actionTimeoutMs / 1000).round()}s',
            onChanged: (v) =>
                setState(() => _actionTimeoutMs = v.toInt()),
          ),
          const SizedBox(height: 8),

          // Pass threshold
          _SettingsSlider(
            title: 'Pass Threshold',
            subtitle: 'Minimum confidence to pass an action (0.0 - 1.0)',
            icon: Icons.tune,
            value: _passThreshold,
            min: 0.3,
            max: 1.0,
            divisions: 7,
            label: _passThreshold.toStringAsFixed(1),
            onChanged: (v) => setState(() => _passThreshold = v),
          ),
          const SizedBox(height: 16),

          // Anti-spoof toggle
          SwitchListTile(
            title: const Text('Enable Anti-Spoof'),
            subtitle: const Text(
              'Basic texture analysis to detect screen replay attacks',
            ),
            value: _enableAntiSpoof,
            onChanged: (v) => setState(() => _enableAntiSpoof = v),
            secondary: const Icon(Icons.shield),
          ),
          const SizedBox(height: 24),

          // Generated config preview
          const Text(
            'Generated Config',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white24),
            ),
            child: SelectableText(
              _buildConfigCode(),
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: Colors.greenAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _buildConfigCode() {
    return '''VivdConfig(
  minConfirmationFrames: $_confirmationFrames,
  maxSessionDurationMs: $_maxSessionMs,
  actionTimeoutMs: $_actionTimeoutMs,
  actionPassThreshold: ${_passThreshold.toStringAsFixed(1)},
  enableAntiSpoof: $_enableAntiSpoof,
)''';
  }
}

class _SettingsSlider extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String label;
  final ValueChanged<double> onChanged;

  const _SettingsSlider({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: Colors.white70),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(subtitle,
                          style: const TextStyle(
                              fontSize: 11, color: Colors.white38)),
                    ],
                  ),
                ),
                Text(label,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
            Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}
