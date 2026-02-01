import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:provider/provider.dart';

import '../../core/models/exercise_config.dart';
import '../../core/providers/app_state_provider.dart';
import 'utils/rep_counter.dart';

class ExerciseSessionScreen extends StatefulWidget {
  const ExerciseSessionScreen({super.key});

  @override
  State<ExerciseSessionScreen> createState() => _ExerciseSessionScreenState();
}

class _ExerciseSessionScreenState extends State<ExerciseSessionScreen> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  bool _isProcessing = false;
  String? _error;
  late PoseDetector _poseDetector;
  ExerciseType _exerciseType = ExerciseType.pushup;
  int _reps = 0;
  RepCounter? _repCounter;
  Timer? _captureTimer;
  bool _sessionActive = false;

  @override
  void initState() {
    super.initState();
    _poseDetector = PoseDetector(
      options: PoseDetectorOptions(
        mode: PoseDetectionMode.stream,
        model: PoseDetectionModel.accurate,
      ),
    );
    _initCamera();
  }

  @override
  void dispose() {
    _captureTimer?.cancel();
    _poseDetector.close();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() {
          _error = 'No cameras found';
        });
        return;
      }
      _controller = CameraController(
        _cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      await _controller!.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _error = null;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Camera error: $e';
      });
    }
  }

  void _startSession() {
    final provider = context.read<AppStateProvider>();
    final config = provider.getConfigFor(_exerciseType);
    if (!config.enabled) return;
    _repCounter = RepCounter(exerciseType: _exerciseType);
    setState(() {
      _sessionActive = true;
      _reps = 0;
    });
    _captureTimer = Timer.periodic(
      const Duration(milliseconds: 400),
      (_) => _processFrame(),
    );
  }

  void _stopSession() {
    _captureTimer?.cancel();
    _captureTimer = null;
    setState(() => _sessionActive = false);
    if (_reps > 0) {
      context.read<AppStateProvider>().creditExerciseTime(_exerciseType, _reps);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Credited $_reps ${_exerciseType.label} reps!'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }
  }

  Future<void> _processFrame() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isProcessing ||
        !_sessionActive) return;

    _isProcessing = true;
    try {
      final image = await _controller!.takePicture();
      final inputImage = InputImage.fromFilePath(image.path);
      final poses = await _poseDetector.processImage(inputImage);

      if (poses.isNotEmpty && mounted) {
        final pose = poses.first;
        final count = _repCounter?.tick(pose);
        if (count != null && count > _reps) {
          setState(() => _reps = count);
        }
      }
    } catch (_) {
      // Ignore processing errors
    } finally {
      _isProcessing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercise session'),
        actions: [
          if (_sessionActive)
            TextButton(
              onPressed: _stopSession,
              child: const Text('End session'),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => _initCamera(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized || _controller == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    height: constraints.maxWidth * 9 / 16,
                    child: CameraPreview(_controller!),
                  ),
                ),
                const SizedBox(height: 24),
                if (!_sessionActive) ...[
                  Text(
                    'Select exercise',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<ExerciseType>(
                    segments: ExerciseType.values
                        .map((t) => ButtonSegment(
                              value: t,
                              label: Text(t.label),
                              icon: Icon(t == ExerciseType.pushup
                                  ? Icons.fitness_center_rounded
                                  : Icons.pull_rounded),
                            ))
                        .toList(),
                    selected: {_exerciseType},
                    onSelectionChanged: (s) =>
                        setState(() => _exerciseType = s.first),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _startSession,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Start session'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ] else ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Text(
                            _exerciseType.label,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '$_reps',
                            style: Theme.of(context).textTheme.displayLarge
                                ?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'reps',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Face the camera and perform reps. End session to credit time.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: _stopSession,
                    icon: const Icon(Icons.stop_rounded),
                    label: const Text('End session & claim time'),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
