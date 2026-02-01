import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/exercise_config.dart';
import '../../core/providers/app_state_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Consumer<AppStateProvider>(
        builder: (context, provider, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SectionHeader(title: 'Exercise values'),
              Card(
                child: Column(
                  children: ExerciseType.values.map((type) {
                    final config = provider.getConfigFor(type);
                    return ListTile(
                      title: Text(config.type.label),
                      subtitle: Text(
                        '${config.minutesPerRep} min per rep',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                      trailing: Switch(
                        value: config.enabled,
                        onChanged: (v) => provider.updateExerciseConfig(
                          config.copyWith(enabled: v),
                        ),
                      ),
                      onTap: () => _showExerciseConfig(context, provider, config),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),
              _SectionHeader(title: 'Blocking schedule'),
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
              _SectionHeader(title: 'About'),
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
                Text('Block from ${start.toString().padLeft(2, '0')}:00 to ${end.toString().padLeft(2, '0')}:00'),
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
                            items: List.generate(24, (i) => DropdownMenuItem(value: i, child: Text('${i.toString().padLeft(2, '0')}:00'))),
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
                            items: List.generate(24, (i) => DropdownMenuItem(value: i, child: Text('${i.toString().padLeft(2, '0')}:00'))),
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
                onPressed: () => Navigator.pop(context, (start: start, end: end)),
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
    if (result != null && context.mounted) {
      await provider.setSchedule(true, startHour: result.start, endHour: result.end);
    }
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
