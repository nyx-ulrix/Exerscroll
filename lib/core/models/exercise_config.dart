enum ExerciseType {
  pushup,
  pullup,
}

extension ExerciseTypeX on ExerciseType {
  String get label {
    switch (this) {
      case ExerciseType.pushup:
        return 'Push-up';
      case ExerciseType.pullup:
        return 'Pull-up';
    }
  }

  double get defaultMinutesPerRep {
    switch (this) {
      case ExerciseType.pushup:
        return 1.0;
      case ExerciseType.pullup:
        return 1.5;
    }
  }
}

class ExerciseConfig {
  final ExerciseType type;
  final double minutesPerRep;
  final int minimumRepsToCredit;
  final bool enabled;

  const ExerciseConfig({
    required this.type,
    this.minutesPerRep = 1.0,
    this.minimumRepsToCredit = 1,
    this.enabled = true,
  });

  ExerciseConfig copyWith({
    ExerciseType? type,
    double? minutesPerRep,
    int? minimumRepsToCredit,
    bool? enabled,
  }) =>
      ExerciseConfig(
        type: type ?? this.type,
        minutesPerRep: minutesPerRep ?? this.minutesPerRep,
        minimumRepsToCredit: minimumRepsToCredit ?? this.minimumRepsToCredit,
        enabled: enabled ?? this.enabled,
      );

  Map<String, dynamic> toJson() => {
        'type': type.index,
        'minutesPerRep': minutesPerRep,
        'minimumRepsToCredit': minimumRepsToCredit,
        'enabled': enabled,
      };

  factory ExerciseConfig.fromJson(Map<String, dynamic> json) =>
      ExerciseConfig(
        type: ExerciseType.values[(json['type'] as num?)?.toInt() ?? 0],
        minutesPerRep:
            (json['minutesPerRep'] as num?)?.toDouble() ?? 1.0,
        minimumRepsToCredit:
            (json['minimumRepsToCredit'] as num?)?.toInt() ?? 1,
        enabled: json['enabled'] as bool? ?? true,
      );
}
