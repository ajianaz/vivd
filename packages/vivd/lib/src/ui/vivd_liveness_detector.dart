import 'dart:async';

import 'package:flutter/material.dart';

import '../camera/camera_service_impl.dart';
import '../models/liveness_action.dart';
import '../models/liveness_result.dart';
import '../vivd.dart';

/// VivdLivenessDetector — drop-in face liveness detection widget.
///
/// Handles camera initialization, liveness session, and result callback.
/// All processing happens on-device.
class VivdLivenessDetector extends StatefulWidget {
  final VivdConfig? config;
  final void Function(LivenessResult result)? onResult;
  final void Function(VivdAction action, int index, int total)? onProgress;
  final Widget? loadingWidget;
  final Widget Function(BuildContext context, String error)? errorBuilder;
  final Widget Function(
    BuildContext context,
    VivdAction? currentAction,
    int actionIndex,
    int totalActions,
    bool isRunning,
  )? overlayBuilder;
  final Widget Function(BuildContext context, CameraServiceImpl camera)?
      cameraPreviewBuilder;
  final bool autoStart;

  const VivdLivenessDetector({
    super.key,
    this.config,
    this.onResult,
    this.onProgress,
    this.loadingWidget,
    this.errorBuilder,
    this.overlayBuilder,
    this.cameraPreviewBuilder,
    this.autoStart = true,
  });

  @override
  State<VivdLivenessDetector> createState() => _VivdLivenessDetectorState();
}

class _VivdLivenessDetectorState extends State<VivdLivenessDetector>
    with TickerProviderStateMixin {
  late Vivd _vivd;
  CameraServiceImpl? _camera;
  bool _initialized = false;
  bool _running = false;
  bool _completed = false;
  String? _error;
  VivdAction? _currentAction;
  int _actionIndex = 0;
  int _totalActions = 0;
  LivenessResult? _result;

  // Track completed action steps for step indicator
  List<bool> _actionCompleted = [];
  List<bool?> _actionResults = []; // null=pending, true=passed, false=failed

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _init();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _vivd.dispose();
    _camera?.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    try {
      _camera = CameraServiceImpl();
      await _camera!.initialize();

      _vivd = Vivd(config: widget.config);
      await _vivd.initialize();

      if (mounted) {
        setState(() => _initialized = true);
        if (widget.autoStart) {
          _startLiveness();
        }
      }
    } catch (e) {
      _log('[Vivd] Init error: $e');
      if (mounted) {
        setState(() => _error = e.toString());
      }
    }
  }

  /// Stop camera stream and release camera resources.
  /// Call after session completes or when restarting.
  Future<void> _releaseCamera() async {
    if (_camera == null) return;
    try {
      await _camera!.stop();
    } catch (_) {}
    // Don't dispose controller — just stop streaming.
    // Camera preview still shows last frame.
  }

  Future<void> _startLiveness() async {
    if (!_initialized || _running || _completed) return;

    final actionCount = widget.config?.actions.length ?? 2;
    setState(() {
      _running = true;
      _actionCompleted = List.filled(actionCount, false);
      _actionResults = List.filled(actionCount, null);
    });

    try {
      await _camera!.start();

      final result = await _vivd.startLiveness(
        frameStream: _camera!.frameStream,
        actions: widget.config?.actions,
        onProgress: (action, index, total) {
          if (mounted) {
            if (index > 0 && index <= _actionCompleted.length) {
              _actionCompleted[index - 1] = true;
            }
            setState(() {
              _currentAction = action;
              _actionIndex = index;
              _totalActions = total;
            });
            widget.onProgress?.call(action, index, total);
          }
        },
      );

      // Session done — stop camera immediately
      await _releaseCamera();

      if (mounted) {
        setState(() {
          _running = false;
          _completed = true;
          _result = result;
          _currentAction = null;
          for (var i = 0; i < result.actions.length; i++) {
            if (i < _actionCompleted.length) {
              _actionCompleted[i] = true;
              _actionResults[i] = result.actions[i].passed;
            }
          }
        });
        widget.onResult?.call(result);
        _log('[Vivd] Session complete — camera stopped');
      }
    } catch (e) {
      await _releaseCamera();
      if (mounted) {
        setState(() {
          _running = false;
          _error = e.toString();
        });
      }
    }
  }

  bool _restarting = false;

  void restart() {
    if (_restarting) return;
    _restarting = true;
    _log('[Vivd] Restarting...');

    setState(() {
      _running = false;
      _completed = false;
      _result = null;
      _error = null;
      _currentAction = null;
      _actionIndex = 0;
      _totalActions = 0;
      _actionCompleted.clear();
      _actionResults.clear();
    });

    _doRestart();
  }

  Future<void> _doRestart() async {
    _log('[Vivd] Restart: disposing old Vivd...');
    try {
      _vivd.dispose();
      _log('[Vivd] Restart: old Vivd disposed');
    } catch (e) {
      _log('[Vivd] Restart: Vivd dispose error: $e');
    }

    _log('[Vivd] Restart: creating new Vivd...');
    _vivd = Vivd(config: widget.config);

    try {
      _log('[Vivd] Restart: initializing new Vivd...');
      await _vivd.initialize();
      _log('[Vivd] Restart: Vivd initialized OK');
    } catch (e) {
      _log('[Vivd] Restart init error: $e');
      if (mounted) {
        setState(() {
          _restarting = false;
          _error = e.toString();
        });
      }
      return;
    }

    _log('[Vivd] Restart ready, calling _startLiveness...');
    _restarting = false;

    if (mounted) {
      _startLiveness();
    } else {
      _log('[Vivd] Restart: widget not mounted, aborting');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return widget.errorBuilder?.call(context, _error!) ??
          _DefaultErrorWidget(
            error: _error!,
            onRetry: _initialized ? restart : _init,
          );
    }

    if (!_initialized) {
      return widget.loadingWidget ??
          _buildLoadingScreen();
    }

    if (_completed && _result != null) {
      return _buildResultView();
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Camera preview
        _buildCameraPreview(),

        // Dark vignette around face area
        _buildVignette(),

        // Face oval guide
        if (_running)
          Center(
            child: _buildFaceOval(),
          ),

        // Step indicator (top)
        if (_running || _completed)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildStepIndicator(),
          ),

        // Action overlay (bottom)
        if (widget.overlayBuilder != null)
          widget.overlayBuilder!(
            context,
            _currentAction,
            _actionIndex,
            _totalActions,
            _running,
          )
        else if (_running)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildActionOverlay(),
          )
        else if (!_completed)
          const Positioned(
            left: 0,
            right: 0,
            bottom: 80,
            child: _WaitingPrompt(),
          ),
      ],
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Initializing Camera...',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (widget.cameraPreviewBuilder != null && _camera != null) {
      return widget.cameraPreviewBuilder!(context, _camera!);
    }
    if (_camera != null) {
      return _camera!.buildPreview();
    }
    return const SizedBox.shrink();
  }

  Widget _buildVignette() {
    return IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: 0.3),
              Colors.black.withValues(alpha: 0.7),
            ],
            stops: const [0.4, 0.7, 1.0],
            radius: 0.8,
          ),
        ),
      ),
    );
  }

  Widget _buildFaceOval() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        final scale = _currentAction != null ? _pulseAnimation.value : 1.0;
        return Transform.scale(
          scale: scale,
          child: CustomPaint(
            size: const Size(240, 320),
            painter: _OvalPainter(
              color: _currentAction != null
                  ? Colors.white.withValues(alpha: 0.6)
                  : Colors.white.withValues(alpha: 0.3),
              strokeWidth: 2,
            ),
          ),
        );
      },
    );
  }

  Widget _buildStepIndicator() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            for (var i = 0; i < _totalActions; i++)
              Expanded(
                child: _buildStepPill(i),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepPill(int index) {
    final isCurrent = index == _actionIndex && _running;
    final isCompleted = index < _actionCompleted.length && _actionCompleted[index];
    final passed = index < _actionResults.length ? _actionResults[index] : null;

    Color color;
    if (isCompleted && passed == true) {
      color = Colors.green;
    } else if (isCompleted && passed == false) {
      color = Colors.redAccent;
    } else if (isCurrent) {
      color = Colors.white;
    } else {
      color = Colors.white24;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 4,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildActionOverlay() {
    if (_currentAction == null) return const SizedBox.shrink();

    final action = _currentAction!;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.8),
          ],
          stops: const [0.0, 0.3],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Step label
              Text(
                'Step ${_actionIndex + 1} of $_totalActions',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),

              // Action emoji
              Text(
                action.emoji,
                style: const TextStyle(fontSize: 48),
              ),
              const SizedBox(height: 12),

              // Action label
              Text(
                action.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),

              // Instruction
              Text(
                action.instruction,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 24),

              // Timeout progress bar
              _buildTimeoutBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeoutBar() {
    // Simple animated indicator showing time remaining
    return Container(
      height: 3,
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(1.5),
      ),
    );
  }

  Widget _buildResultView() {
    final result = _result!;
    final isLive = result.isLive;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Result icon
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.elasticOut,
                          builder: (context, scale, child) {
                            return Transform.scale(
                              scale: scale,
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isLive
                                      ? Colors.green.withValues(alpha: 0.15)
                                      : Colors.red.withValues(alpha: 0.15),
                                ),
                                child: Icon(
                                  isLive ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                  size: 56,
                                  color: isLive ? Colors.green : Colors.red,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),

                        // Result text
                        Text(
                          isLive ? 'Verified!' : 'Verification Failed',
                          style: TextStyle(
                            color: isLive ? Colors.green : Colors.red,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Score
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Score: ${(result.score * 100).toStringAsFixed(1)}%',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Action breakdown chips
                        if (result.actions.isNotEmpty) ...[
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: result.actions.map((a) {
                              final passed = a.passed;
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: passed
                                      ? Colors.green.withValues(alpha: 0.12)
                                      : Colors.red.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: passed
                                        ? Colors.green.withValues(alpha: 0.3)
                                        : Colors.red.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      passed ? Icons.check_circle : Icons.cancel,
                                      size: 16,
                                      color: passed ? Colors.green : Colors.red,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${a.action.emoji} ${a.action.label}',
                                      style: TextStyle(
                                        color: passed ? Colors.greenAccent : Colors.redAccent,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],

                        const Spacer(),

                        // Retry button — always visible at bottom
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: restart,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Try Again'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white10,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Waiting prompt shown before session starts.
class _WaitingPrompt extends StatelessWidget {
  const _WaitingPrompt();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.face, color: Colors.white70, size: 20),
                  SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      'Position your face in the frame',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Default error widget with retry button.
class _DefaultErrorWidget extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _DefaultErrorWidget({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Camera Error',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                style: const TextStyle(color: Colors.white54, fontSize: 13),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OvalPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  _OvalPainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: size.width,
        height: size.height,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _OvalPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
  }
}

void _log(String message) {
  // ignore: avoid_print
  print(message);
}
