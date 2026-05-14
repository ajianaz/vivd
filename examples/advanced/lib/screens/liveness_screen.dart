import 'package:flutter/material.dart';
import 'package:vivd/vivd.dart';

/// Liveness screen — full config + action progress + result breakdown.
class LivenessScreen extends StatefulWidget {
  const LivenessScreen({super.key});

  @override
  State<LivenessScreen> createState() => _LivenessScreenState();
}

class _LivenessScreenState extends State<LivenessScreen> {
  LivenessResult? _result;
  bool _isRunning = false;

  // Config state (synced with SettingsScreen via shared state)
  List<VivdAction> _selectedActions = const [
    VivdAction.blink,
    VivdAction.smile,
  ];
  int _confirmationFrames = 3;
  int _actionTimeoutMs = 10000;
  double _passThreshold = 0.7;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Liveness Detection'),
      ),
      body: _result != null ? _buildResultView() : _buildConfigView(),
    );
  }

  Widget _buildConfigView() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Configuration',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Actions selector
          const Text('Actions:'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: VivdAction.values.map((action) {
              final selected = _selectedActions.contains(action);
              return FilterChip(
                label: Text(action.label),
                selected: selected,
                onSelected: (value) {
                  setState(() {
                    if (value) {
                      _selectedActions = [..._selectedActions, action];
                    } else if (_selectedActions.length > 1) {
                      _selectedActions = _selectedActions
                          .where((a) => a != action)
                          .toList();
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Confirmation frames
          Row(
            children: [
              const Text('Confirmation frames: '),
              Text('$_confirmationFrames'),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: _confirmationFrames > 1
                    ? () => setState(() => _confirmationFrames--)
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: _confirmationFrames < 10
                    ? () => setState(() => _confirmationFrames++)
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Pass threshold
          Row(
            children: [
              const Text('Pass threshold: '),
              Text(_passThreshold.toStringAsFixed(1)),
              const Spacer(),
              Slider(
                value: _passThreshold,
                min: 0.3,
                max: 1.0,
                divisions: 7,
                onChanged: (v) => setState(() => _passThreshold = v),
              ),
            ],
          ),
          const Spacer(),

          // Start button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: _isRunning ? null : _startLiveness,
              icon: _isRunning
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.play_arrow),
              label: Text(_isRunning ? 'Running...' : 'Start Liveness'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildResultView() {
    final result = _result!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary
        Card(
          color: result.isLive ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Icon(
                  result.isLive ? Icons.verified : Icons.cancel,
                  size: 48,
                  color: result.isLive ? Colors.green : Colors.red,
                ),
                const SizedBox(height: 12),
                Text(
                  result.isLive ? 'LIVE' : 'SPOOF DETECTED',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: result.isLive ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Score: ${(result.score * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(fontSize: 16, color: Colors.white70),
                ),
                if (result.durationMs != null)
                  Text(
                    'Duration: ${result.durationMs!}ms',
                    style: const TextStyle(fontSize: 14, color: Colors.white54),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Per-action breakdown
        const Text(
          'Action Breakdown',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...result.actions.map((action) => Card(
              child: ListTile(
                leading: Icon(
                  action.passed ? Icons.check_circle : Icons.cancel,
                  color: action.passed ? Colors.green : Colors.red,
                ),
                title: Text(action.action.label),
                subtitle: Text(
                  'Score: ${(action.score * 100).toStringAsFixed(0)}% · '
                  '${action.durationMs}ms · ${action.frameCount} frames',
                  style: const TextStyle(fontSize: 12, color: Colors.white54),
                ),
                trailing: action.failureReason != null
                    ? const Tooltip(
                        message: 'Failure reason',
                        child: Icon(Icons.warning_amber,
                            color: Colors.amber, size: 20),
                      )
                    : null,
              ),
            )),

        const SizedBox(height: 24),

        // Session export
        OutlinedButton.icon(
          onPressed: () => _showSessionJson(context, result),
          icon: const Icon(Icons.data_object),
          label: const Text('Export Session JSON'),
        ),
        const SizedBox(height: 12),

        // Restart
        FilledButton.icon(
          onPressed: () => setState(() {
            _result = null;
            _isRunning = false;
          }),
          icon: const Icon(Icons.refresh),
          label: const Text('Try Again'),
        ),
      ],
    );
  }

  void _startLiveness() {
    setState(() => _isRunning = true);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            title: const Text('Liveness Check'),
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
          body: VivdLivenessDetector(
            config: VivdConfig(
              actions: _selectedActions,
              minConfirmationFrames: _confirmationFrames,
              actionTimeoutMs: _actionTimeoutMs,
              actionPassThreshold: _passThreshold,
            ),
            onResult: (result) {
              Navigator.pop(context);
              setState(() {
                _result = result;
                _isRunning = false;
              });
            },
            onProgress: (action, index, total) {
              debugPrint('Progress: ${action.label} ($index/$total)');
            },
          ),
        ),
      ),
    );
  }

  void _showSessionJson(BuildContext context, LivenessResult result) {
    final json = result.toJson();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Session Payload'),
        content: SingleChildScrollView(
          child: SelectableText(
            const JsonEncoder.withIndent('  ').convert(json),
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
