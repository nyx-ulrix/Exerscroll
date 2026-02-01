import '../models/exercise_config.dart';
import 'storage_service.dart';

/// Service for loading and persisting exercise configurations.
class ExerciseService {
  ExerciseService._();
  static ExerciseService? _instance;
  static ExerciseService get instance => _instance ??= ExerciseService._();

  final _storage = StorageService.instance;

  static const _defaultConfigs = [
    ExerciseConfig(type: ExerciseType.pushup, minutesPerRep: 1.0),
    ExerciseConfig(type: ExerciseType.pullup, minutesPerRep: 1.5),
  ];

  Future<List<ExerciseConfig>> loadAllConfigs() async {
    return _storage.getExerciseConfigs();
  }

  Future<void> saveConfig(ExerciseConfig config) async {
    final configs = await loadAllConfigs();
    final updated = configs
        .map((c) => c.type == config.type ? config : c)
        .toList();
    if (!updated.any((c) => c.type == config.type)) {
      updated.add(config);
    }
    await _storage.saveExerciseConfigs(updated);
  }

  Future<ExerciseConfig> getConfig(String id) async {
    final configs = await loadAllConfigs();
    final type = _idToType(id);
    return configs.firstWhere(
      (c) => c.type == type,
      orElse: () => _defaultConfigs.firstWhere(
        (c) => c.type == type,
        orElse: () => ExerciseConfig(type: type),
      ),
    );
  }

  ExerciseType _idToType(String id) {
    switch (id.toLowerCase()) {
      case 'pushup':
      case 'pushups':
        return ExerciseType.pushup;
      case 'pullup':
      case 'pullups':
      case 'pull-up':
      case 'pull-ups':
        return ExerciseType.pullup;
      default:
        return ExerciseType.pushup;
    }
  }
}
