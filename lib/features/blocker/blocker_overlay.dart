import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/providers/app_state_provider.dart';

/// Full-screen overlay shown when user tries to access a blocked app.
/// In a full implementation, this would be displayed via SYSTEM_ALERT_WINDOW
/// on top of the blocked app. For now, it can be shown within the app.
class BlockerOverlay extends StatelessWidget {
  const BlockerOverlay({
    super.key,
    this.blockedAppName,
    this.remainingMinutes = 0,
    this.onDismiss,
  });

  final String? blockedAppName;
  final double remainingMinutes;
  final VoidCallback? onDismiss;

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
              Consumer<AppStateProvider>(
                builder: (context, provider, _) {
                  final remaining = provider.remainingMinutes;
                  return Card(
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
                            '${remaining.toStringAsFixed(0)} min',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: onDismiss ?? () => Navigator.of(context).maybePop(),
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
