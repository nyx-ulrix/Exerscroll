import '../models/exercise_config.dart';
import 'exercise_service.dart';

/// Calculates unlock time (Duration) from exercise reps.
class RewardCalculator {
  RewardCalculator._();
  static RewardCalculator? _instance;
  static RewardCalculator get instance => _instance ??= RewardCalculator._();

  final _exerciseService = ExerciseService.instance;

  /// Returns the unlock duration for [reps] of exercise [exerciseId].
  /// [exerciseId] can be 'pushup', 'pullup', etc.
  Future<Duration> calculateReward(String exerciseId, int reps) async {
    final config = await _exerciseService.getConfig(exerciseId);
    if (!config.enabled || reps < config.minimumRepsToCredit) {
      return Duration.zero;
    }
    final minutes = reps * config.minutesPerRep;
    final seconds = (minutes * 60).round().clamp(0, 0x7FFFFFFF);
    return Duration(seconds: seconds);
  }

  /// Synchronous version using preloaded config.
  static Duration calculateFromConfig(ExerciseConfig config, int reps) {
    if (!config.enabled || reps < config.minimumRepsToCredit) {
      return Duration.zero;
    }
    final minutes = reps * config.minutesPerRep;
    final seconds = (minutes * 60).round().clamp(0, 0x7FFFFFFF);
    return Duration(seconds: seconds);
  }
}
