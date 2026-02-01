import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

import '../../core/theme/app_theme.dart';

/// Standalone overlay app - runs in overlay isolate, no Provider.
class BlockerOverlayApp extends StatefulWidget {
  const BlockerOverlayApp({super.key});

  @override
  State<BlockerOverlayApp> createState() => _BlockerOverlayAppState();
}

class _BlockerOverlayAppState extends State<BlockerOverlayApp> {
  String? _blockedAppName;
  double _remainingMinutes = 0;

  @override
  void initState() {
    super.initState();
    FlutterOverlayWindow.overlayListener.listen(_onOverlayData);
  }

  void _onOverlayData(dynamic event) {
    if (event is String) {
      try {
        final map = jsonDecode(event) as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _blockedAppName = map['blockedAppName'] as String?;
            _remainingMinutes = (map['remainingMinutes'] as num?)?.toDouble() ?? 0;
          });
        }
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: _BlockerOverlayScreen(
        blockedAppName: _blockedAppName,
        remainingMinutes: _remainingMinutes,
        onEarnTime: () => FlutterOverlayWindow.closeOverlay(),
      ),
    );
  }
}

class _BlockerOverlayScreen extends StatelessWidget {
  const _BlockerOverlayScreen({
    this.blockedAppName,
    required this.remainingMinutes,
    required this.onEarnTime,
  });

  final String? blockedAppName;
  final double remainingMinutes;
  final VoidCallback onEarnTime;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_rounded,
                size: 80,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 24),
              Text(
                'App blocked',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                blockedAppName != null
                    ? '$blockedAppName is blocked until you earn more time.'
                    : 'Earn time by exercising to unlock.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        'Banked time',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${remainingMinutes.toStringAsFixed(0)} min',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: onEarnTime,
                icon: const Icon(Icons.fitness_center_rounded),
                label: const Text('Earn time with exercise'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
