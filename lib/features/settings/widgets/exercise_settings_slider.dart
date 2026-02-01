import 'package:flutter/material.dart';

import '../../../core/models/exercise_config.dart';

/// Slider widget for editing minutes-per-rep with live preview.
/// Spec: range 0.5–5.0, divisions 9, validation > 0.1.
class ExerciseSettingsSlider extends StatefulWidget {
  const ExerciseSettingsSlider({
    super.key,
    required this.config,
    required this.onSave,
    this.onTapAdvanced,
  });

  final ExerciseConfig config;
  final void Function(ExerciseConfig) onSave;
  final VoidCallback? onTapAdvanced;

  @override
  State<ExerciseSettingsSlider> createState() => _ExerciseSettingsSliderState();
}

class _ExerciseSettingsSliderState extends State<ExerciseSettingsSlider> {
  late double _minutesPerRep;

  static const _min = 0.5;
  static const _max = 5.0;
  static const _divisions = 9;

  @override
  void initState() {
    super.initState();
    _minutesPerRep = widget.config.minutesPerRep.clamp(_min, _max);
  }

  @override
  void didUpdateWidget(ExerciseSettingsSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config.minutesPerRep != widget.config.minutesPerRep) {
      _minutesPerRep = widget.config.minutesPerRep.clamp(_min, _max);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final previewMinutes = (5 * _minutesPerRep).toStringAsFixed(1);

    return Card(
      child: InkWell(
        onTap: widget.onTapAdvanced,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.config.type.label,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        '${_minutesPerRep.toStringAsFixed(1)} min/rep',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      if (widget.onTapAdvanced != null) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.settings_rounded,
                          size: 18,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              Slider(
                value: _minutesPerRep,
                min: _min,
                max: _max,
                divisions: _divisions,
                label: _minutesPerRep.toStringAsFixed(1),
                onChanged: (v) {
                  final validated = v.clamp(0.1, _max);
                  setState(() => _minutesPerRep = validated);
                },
                onChangeEnd: (v) {
                  final value = v.clamp(0.1, _max);
                  widget.onSave(
                    widget.config.copyWith(minutesPerRep: value),
                  );
                },
              ),
              Text(
                '5 reps = $previewMinutes min unlocked',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
