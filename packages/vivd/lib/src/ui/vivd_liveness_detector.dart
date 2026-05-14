import 'dart:async';

import 'package:flutter/material.dart';

import '../camera/camera_service.dart';
import '../camera/camera_service_impl.dart';
import '../models/liveness_action.dart';
import '../models/liveness_result.dart';
import '../vivd.dart';

/// VivdLivenessDetector — drop-in face liveness detection widget.
///
/// Handles camera initialization, liveness session, and result callback.
/// All processing happens on-device.
///
/// ```dart
/// VivdLivenessDetector(
///   onResult: (result) {
///     print('Live: ${result.isLive}');
///   },
/// )
/// ```
class VivdLivenessDetector extends StatefulWidget {
  /// Vivd configuration. Uses defaults if not provided.
  final VivdConfig? config;

  /// Called when the liveness session completes.
  final void Function(LivenessResult result)? onResult;

  /// Called when a new action starts during the session.
  final void Function(VivdAction action, int index, int total)? onProgress;

  /// Widget shown while camera initializes.
  final Widget? loadingWidget;

  /// Builder for error state. Receives the error message.
  final Widget Function(BuildContext context, String error)? errorBuilder;

  /// Custom overlay builder for action prompts.
  /// If null, uses default [ActionPromptOverlay].
  final Widget Function(
    BuildContext context,
    VivdAction? currentAction,
    int actionIndex,
    int totalActions,
    bool isRunning,
  )? overlayBuilder;

  /// Custom camera preview builder.
  /// If null, uses [CameraServiceImpl.buildPreview].
  final Widget Function(BuildContext context, CameraServiceImpl camera)?
      cameraPreviewBuilder;

  /// Whether to start liveness automatically after init.
  /// Default: `true`.
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

class _VivdLivenessDetectorState extends State<VivdLivenessDetector> {
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

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      // Initialize camera
      _camera = CameraServiceImpl();
      await _camera!.initialize();

      // Initialize Vivd SDK
      _vivd = Vivd(config: widget.config);
      await _vivd.initialize();

      if (mounted) {
        setState(() => _initialized = true);
        if (widget.autoStart) {
          _startLiveness();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    }
  }

  Future<void> _startLiveness() async {
    if (!_initialized || _running || _completed) return;
    setState(() => _running = true);

    try {
      await _camera!.start();

      final result = await _vivd.startLiveness(
        frameStream: _camera!.frameStream,
        actions: widget.config?.actions,
        onProgress: (action, index, total) {
          if (mounted) {
            setState(() {
              _currentAction = action;
              _actionIndex = index;
              _totalActions = total;
            });
            widget.onProgress?.call(action, index, total);
          }
        },
      );

      if (mounted) {
        setState(() {
          _running = false;
          _completed = true;
          _result = result;
          _currentAction = null;
        });
        widget.onResult?.call(result);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _running = false;
          _error = e.toString();
        });
      }
    }
  }

  /// Restart the liveness session (e.g., after failure).
  void restart() {
    setState(() {
      _completed = false;
      _result = null;
      _error = null;
      _currentAction = null;
      _actionIndex = 0;
      _totalActions = 0;
    });
    _startLiveness();
  }

  @override
  void dispose() {
    _vivd.dispose();
    _camera?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Error state
    if (_error != null) {
      return widget.errorBuilder?.call(context, _error!) ??
          _DefaultErrorWidget(
            error: _error!,
            onRetry: _initialized ? restart : _init,
          );
    }

    // Loading state
    if (!_initialized) {
      return widget.loadingWidget ??
          const Center(child: CircularProgressIndicator());
    }

    // Completed state with result
    if (_completed && _result != null) {
      return _buildResultView();
    }

    // Active session or ready to start
    return Stack(
      fit: StackFit.expand,
      children: [
        // Camera preview
        _buildCameraPreview(),

        // Action overlay
        if (widget.overlayBuilder != null)
          widget.overlayBuilder!(
            context,
            _currentAction,
            _actionIndex,
            _totalActions,
            _running,
          )
        else
          ActionPromptOverlay(
            currentAction: _currentAction,
            actionIndex: _actionIndex,
            totalActions: _totalActions,
            isRunning: _running,
          ),
      ],
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

  Widget _buildResultView() {
    final result = _result!;
    final isLive = result.isLive;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isLive ? Icons.verified : Icons.cancel,
              size: 80,
              color: isLive ? Colors.green : Colors.red,
            ),
            const SizedBox(height: 24),
            Text(
              isLive ? 'Verified!' : 'Verification Failed',
              style: TextStyle(
                color: isLive ? Colors.green : Colors.red,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Score: ${(result.score * 100).toStringAsFixed(1)}%',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            if (result.passedActions > 0)
              Text(
                '${result.passedActions}/${result.totalActions} actions passed',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                ),
              ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: restart,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Default action prompt overlay.
class ActionPromptOverlay extends StatelessWidget {
  final VivdAction? currentAction;
  final int actionIndex;
  final int totalActions;
  final bool isRunning;

  const ActionPromptOverlay({
    super.key,
    this.currentAction,
    required this.actionIndex,
    required this.totalActions,
    required this.isRunning,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 48,
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(16),
          ),
          child: isRunning && currentAction != null
              ? _buildActionPrompt(context)
              : _buildWaitingPrompt(context),
        ),
      ),
    );
  }

  Widget _buildActionPrompt(BuildContext context) {
    final icon = switch (currentAction!) {
      VivdAction.blink => Icons.remove_red_eye,
      VivdAction.smile => Icons.sentiment_satisfied,
      VivdAction.headTurnLeft => Icons.arrow_back,
      VivdAction.headTurnRight => Icons.arrow_forward,
      VivdAction.lookUp => Icons.arrow_upward,
      VivdAction.lookDown => Icons.arrow_downward,
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            Text(
              currentAction!.label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Step ${actionIndex + 1} of $totalActions',
          style: const TextStyle(color: Colors.white54, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildWaitingPrompt(BuildContext context) {
    return const Text(
      'Position your face in the frame',
      style: TextStyle(color: Colors.white70, fontSize: 16),
      textAlign: TextAlign.center,
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
              Text(
                'Camera Error',
                style: const TextStyle(
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
