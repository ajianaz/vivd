import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:vivd/vivd.dart';

/// Identity screen — register face + identify against stored faces.
class IdentityScreen extends StatefulWidget {
  const IdentityScreen({super.key});

  @override
  State<IdentityScreen> createState() => _IdentityScreenState();
}

class _IdentityScreenState extends State<IdentityScreen> {
  final Vivd _vivd = Vivd();
  bool _initialized = false;
  String? _error;
  bool _isRegistering = false;
  bool _isIdentifying = false;

  /// Registered faces (in-memory for demo).
  final List<_RegisteredFace> _faces = [];

  /// Most recent identification result.
  FaceIdResult? _identificationResult;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      await _vivd.initialize();
      if (mounted) setState(() => _initialized = true);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  void dispose() {
    _vivd.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Face Identity')),
      body: _error != null
          ? Center(child: Text('Error: $_error'))
          : !_initialized
              ? const Center(child: CircularProgressIndicator())
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Face Identity Demo',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Register faces with labels, then identify against them. '
          'In production, use real camera frames. '
          'This demo uses synthetic embeddings.',
          style: TextStyle(color: Colors.white54, fontSize: 13),
        ),
        const SizedBox(height: 24),

        // Register section
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Register',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isRegistering ? null : _registerRandomFace,
                        icon: _isRegistering
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.person_add),
                        label: Text(_isRegistering
                            ? 'Registering...'
                            : 'Register Demo Face'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Identify section
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Identify',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _faces.isEmpty || _isIdentifying
                      ? null
                      : _identifyRandomFace,
                  icon: _isIdentifying
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                  label: Text(_isIdentifying
                      ? 'Identifying...'
                      : 'Identify Demo Face'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Identification result
        if (_identificationResult != null)
          Card(
            color: _identificationResult!.isMatch
                ? Colors.green.withValues(alpha: 0.1)
                : Colors.orange.withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _identificationResult!.isMatch
                        ? '✅ Match Found'
                        : '❌ No Match',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _identificationResult!.isMatch
                          ? Colors.green
                          : Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_identificationResult!.isMatch) ...[
                    Text('Label: ${_identificationResult!.label}'),
                    Text(
                        'Score: ${(identificationResult!.score * 100).toStringAsFixed(1)}%'),
                    Text('Face ID: ${_identificationResult!.faceId}'),
                  ] else
                    const Text(
                      'No face matched the registered faces.',
                      style: TextStyle(color: Colors.white54),
                    ),
                ],
              ),
            ),
          ),

        const SizedBox(height: 16),

        // Registered faces list
        const Text(
          'Registered Faces',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        if (_faces.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No faces registered yet.',
                style: TextStyle(color: Colors.white38),
              ),
            ),
          )
        else
          ..._faces.asMap().entries.map((entry) {
            final i = entry.key;
            final face = entry.value;
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.deepPurple.withValues(alpha: 0.2),
                  child: Text(
                    face.label.substring(0, 1).toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(face.label),
                subtitle: Text('${face.faceId} · ${face.embeddingDims}D embedding'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _removeFace(i),
                ),
              ),
            );
          }),
      ],
    );
  }

  /// Register a demo face with a synthetic face image.
  Future<void> _registerRandomFace() async {
    setState(() => _isRegistering = true);

    try {
      // Generate synthetic face bytes (simulating a camera frame crop)
      final random = Random();
      final faceBytes = Uint8List.fromList(
        List.generate(128 * 128 * 3, (_) => random.nextInt(256)),
      );

      final label = 'user_${_faces.length + 1}';
      final result = await _vivd.registerFace(
        faceBytes,
        label: label,
        width: 128,
        height: 128,
      );

      if (mounted) {
        setState(() {
          _faces.add(_RegisteredFace(
            faceId: result.faceId,
            label: label,
            embeddingDims: 128,
          ));
          _identificationResult = null;
          _isRegistering = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registered: $label (${result.faceId})')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRegistering = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  /// Identify a random face against registered faces.
  Future<void> _identifyRandomFace() async {
    setState(() => _isIdentifying = true);

    try {
      // Generate synthetic face bytes
      final random = Random();
      final faceBytes = Uint8List.fromList(
        List.generate(128 * 128 * 3, (_) => random.nextInt(256)),
      );

      final result = await _vivd.identifyFace(
        faceBytes,
        threshold: 0.3, // Low threshold for demo with synthetic embeddings
        width: 128,
        height: 128,
      );

      if (mounted) {
        setState(() {
          _identificationResult = result ?? FaceIdResult(
            faceId: 'N/A',
            score: 0.0,
            isMatch: false,
          );
          _isIdentifying = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isIdentifying = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _removeFace(int index) {
    final face = _faces[index];
    _vivd.removeFace(face.faceId);
    setState(() {
      _faces.removeAt(index);
      _identificationResult = null;
    });
  }
}

class _RegisteredFace {
  final String faceId;
  final String label;
  final int embeddingDims;

  const _RegisteredFace({
    required this.faceId,
    required this.label,
    required this.embeddingDims,
  });
}
