import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/exercise_config.dart';
import '../../core/providers/app_state_provider.dart';
import '../../services/overlay_manager.dart';
import 'widgets/exercise_settings_slider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with WidgetsBindingObserver {
  bool _overlayGranted = false;
  bool _usageStatsGranted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (Platform.isAndroid) _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    final overlay = await OverlayManager.hasOverlayPermission();
    final usage = await OverlayManager.hasUsageStatsPermission();
    if (mounted) {
      setState(() {
        _overlayGranted = overlay;
        _usageStatsGranted = usage;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  Future<void> _requestOverlayPermission() async {
    await OverlayManager.requestOverlayPermission();
    await Future.delayed(const Duration(seconds: 1));
    await _checkPermissions();
  }

  Future<void> _requestUsageStatsPermission() async {
    await OverlayManager.requestUsageStatsPermission();
    await Future.delayed(const Duration(seconds: 1));
    await _checkPermissions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Consumer<AppStateProvider>(
        builder: (context, provider, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (Platform.isAndroid) ...[
                const _SectionHeader(title: 'App Blocking Permissions'),
                _buildPermissionCard(
                  context: context,
                  title: 'Display over other apps',
                  subtitle: _overlayGranted
                      ? 'Enabled'
                      : 'Required to show blocking screen',
                  isGranted: _overlayGranted,
                  onPressed: _requestOverlayPermission,
                ),
                const SizedBox(height: 8),
                _buildPermissionCard(
                  context: context,
                  title: 'Usage Access',
                  subtitle: _usageStatsGranted
                      ? 'Enabled'
                      : 'Required to detect when blocked apps are opened',
                  isGranted: _usageStatsGranted,
                  onPressed: _requestUsageStatsPermission,
                ),
                const SizedBox(height: 24),
              ],
              const _SectionHeader(title: 'Exercise Rewards'),
              ...ExerciseType.values.map((type) {
                final config = provider.getConfigFor(type);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ExerciseSettingsSlider(
                    config: config,
                    onSave: (updated) => provider.updateExerciseConfig(updated),
                    onTapAdvanced: () =>
                        _showExerciseConfig(context, provider, config),
                  ),
                );
              }),
              const SizedBox(height: 8),
              const _SectionHeader(title: 'Blocking schedule'),
              Card(
                child: SwitchListTile(
                  title: const Text('Schedule blocking'),
                  subtitle: Text(
                    provider.scheduleEnabled
                        ? '${provider.scheduleStartHour}:00 - ${provider.scheduleEndHour}:00'
                        : 'Always on',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  value: provider.scheduleEnabled,
                  onChanged: (v) async {
                    if (v) {
                      await _showSchedulePicker(context, provider);
                    } else {
                      await provider.setSchedule(false);
                    }
                  },
                ),
              ),
              if (provider.scheduleEnabled) ...[
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.schedule_rounded),
                  title: const Text('Change schedule'),
                  onTap: () => _showSchedulePicker(context, provider),
                ),
              ],
              const SizedBox(height: 24),
              const _SectionHeader(title: 'About'),
              ListTile(
                leading: const Icon(Icons.phone_android_rounded),
                title: const Text('Cover Screen Setup'),
                subtitle: const Text('Guide for Oppo N3 Flip & foldables'),
                onTap: () => _showCoverScreenGuide(context),
              ),
              ListTile(
                leading: const Icon(Icons.info_outline_rounded),
                title: const Text('ExerScroll v1.0'),
                subtitle: Text(
                  'Earn screen time through exercise',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showCoverScreenGuide(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cover Screen Setup'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'To use ExerScroll on the cover screen of Oppo N3 Flip or similar devices:'),
            SizedBox(height: 16),
            Text('1. Go to System Settings'),
            Text('2. Select "Foldable features" or "Cover Screen"'),
            Text('3. Tap "Apps on cover screen" or "Mini apps"'),
            Text('4. Find ExerScroll and enable it'),
            SizedBox(height: 16),
            Text(
                'This allows the blocking overlay to work when the phone is folded.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showExerciseConfig(
    BuildContext context,
    AppStateProvider provider,
    ExerciseConfig config,
  ) {
    double minutes = config.minutesPerRep;
    int minReps = config.minimumRepsToCredit;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    config.type.label,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Minutes per rep: ${minutes.toStringAsFixed(1)}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  Slider(
                    value: minutes,
                    min: 0.5,
                    max: 5,
                    divisions: 9,
                    label: minutes.toStringAsFixed(1),
                    onChanged: (v) => setModalState(() => minutes = v),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Minimum reps to credit: $minReps',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  Slider(
                    value: minReps.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: '$minReps',
                    onChanged: (v) => setModalState(() => minReps = v.round()),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () async {
                      await provider.updateExerciseConfig(config.copyWith(
                        minutesPerRep: minutes,
                        minimumRepsToCredit: minReps,
                      ));
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showSchedulePicker(
    BuildContext context,
    AppStateProvider provider,
  ) async {
    int start = provider.scheduleStartHour;
    int end = provider.scheduleEndHour;
    final result = await showDialog<({int start, int end})>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Blocking schedule'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                    'Block from ${start.toString().padLeft(2, '0')}:00 to ${end.toString().padLeft(2, '0')}:00'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          const Text('Start hour'),
                          DropdownButton<int>(
                            value: start,
                            isExpanded: true,
                            items: List.generate(
                                24,
                                (i) => DropdownMenuItem(
                                    value: i,
                                    child: Text(
                                        '${i.toString().padLeft(2, '0')}:00'))),
                            onChanged: (v) => setState(() => start = v ?? 20),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        children: [
                          const Text('End hour'),
                          DropdownButton<int>(
                            value: end,
                            isExpanded: true,
                            items: List.generate(
                                24,
                                (i) => DropdownMenuItem(
                                    value: i,
                                    child: Text(
                                        '${i.toString().padLeft(2, '0')}:00'))),
                            onChanged: (v) => setState(() => end = v ?? 7),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () =>
                    Navigator.pop(context, (start: start, end: end)),
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
    if (result != null && context.mounted) {
      await provider.setSchedule(true,
          startHour: result.start, endHour: result.end);
    }
  }

  Widget _buildPermissionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required bool isGranted,
    required VoidCallback onPressed,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(
          isGranted ? Icons.check_circle_rounded : Icons.warning_rounded,
          color: isGranted
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.error,
        ),
        title: Text(title),
        subtitle: Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        trailing: isGranted
            ? null
            : FilledButton(
                onPressed: onPressed,
                child: const Text('Enable'),
              ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
