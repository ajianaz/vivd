import 'package:flutter/material.dart';
import 'screens/liveness_screen.dart';
import 'screens/identity_screen.dart';
import 'screens/settings_screen.dart';

/// Home screen — feature cards linking to each demo.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vivd — Advanced Example'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Explore all Vivd features',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Each demo shows a different aspect of the SDK.',
            style: TextStyle(color: Colors.white54),
          ),
          const SizedBox(height: 24),

          // Liveness detection
          _FeatureCard(
            icon: Icons.face_retouching_natural,
            title: 'Liveness Detection',
            description: 'Custom config, action progress, detailed result',
            color: Colors.deepPurple,
            onTap: () => _navigate(context, const LivenessScreen()),
          ),
          const SizedBox(height: 16),

          // Face identity
          _FeatureCard(
            icon: Icons.fingerprint,
            title: 'Face Identity',
            description: 'Register faces, identify against stored faces',
            color: Colors.teal,
            onTap: () => _navigate(context, const IdentityScreen()),
          ),
          const SizedBox(height: 16),

          // Settings
          _FeatureCard(
            icon: Icons.tune,
            title: 'Settings',
            description: 'Configure VivdConfig parameters',
            color: Colors.orange,
            onTap: () => _navigate(context, const SettingsScreen()),
          ),
        ],
      ),
    );
  }

  void _navigate(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white38),
            ],
          ),
        ),
      ),
    );
  }
}
