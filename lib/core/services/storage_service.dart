import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../models/blocked_app.dart';
import '../models/exercise_config.dart';
import '../models/time_bank.dart';

class StorageService {
  StorageService._();
  static StorageService? _instance;
  static StorageService get instance => _instance ??= StorageService._();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<List<BlockedApp>> getBlockedApps() async {
    await init();
    final json = _prefs!.getString(AppConstants.storageKeyBlockedApps);
    if (json == null) return [];
    try {
      final list = jsonDecode(json) as List;
      return list
          .map((e) => BlockedApp.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveBlockedApps(List<BlockedApp> apps) async {
    await init();
    final list = apps.map((e) => e.toJson()).toList();
    await _prefs!.setString(
      AppConstants.storageKeyBlockedApps,
      jsonEncode(list),
    );
  }

  Future<List<ExerciseConfig>> getExerciseConfigs() async {
    await init();
    final json = _prefs!.getString(AppConstants.storageKeyExerciseConfigs);
    if (json == null) {
      return ExerciseType.values
          .map((t) => ExerciseConfig(
                type: t,
                minutesPerRep: t.defaultMinutesPerRep,
              ))
          .toList();
    }
    try {
      final list = jsonDecode(json) as List;
      return list
          .map((e) => ExerciseConfig.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return ExerciseType.values.map((t) => ExerciseConfig(type: t)).toList();
    }
  }

  Future<void> saveExerciseConfigs(List<ExerciseConfig> configs) async {
    await init();
    final list = configs.map((e) => e.toJson()).toList();
    await _prefs!.setString(
      AppConstants.storageKeyExerciseConfigs,
      jsonEncode(list),
    );
  }

  Future<double> getBankedMinutes() async {
    await init();
    return _prefs!.getDouble(AppConstants.storageKeyTimeBank) ?? 0;
  }

  Future<void> saveBankedMinutes(double minutes) async {
    await init();
    await _prefs!.setDouble(AppConstants.storageKeyTimeBank, minutes);
  }

  Future<double> getUsedTodayMinutes() async {
    await init();
    final key = _todayKey();
    return _prefs!.getDouble('used_$key') ?? 0;
  }

  Future<void> saveUsedTodayMinutes(double minutes) async {
    await init();
    final key = _todayKey();
    await _prefs!.setDouble('used_$key', minutes);
  }

  Future<double> getDailyUsageTotal() async {
    await init();
    return _prefs!.getDouble('daily_usage_total') ?? 0;
  }

  Future<void> saveDailyUsageTotal(double minutes) async {
    await init();
    await _prefs!.setDouble('daily_usage_total', minutes);
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<Map<String, DailyStats>> getDailyStatsHistory() async {
    await init();
    final json = _prefs!.getString(AppConstants.storageKeyDailyStats);
    if (json == null) return {};
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return map.map(
        (k, v) => MapEntry(k, DailyStats.fromJson(v as Map<String, dynamic>)),
      );
    } catch (_) {
      return {};
    }
  }

  Future<void> saveDailyStats(DailyStats stats) async {
    await init();
    final history = await getDailyStatsHistory();
    final key =
        '${stats.date.year}-${stats.date.month.toString().padLeft(2, '0')}-${stats.date.day.toString().padLeft(2, '0')}';
    history[key] = stats;
    final map = history.map((k, v) => MapEntry(k, v.toJson()));
    await _prefs!.setString(
      AppConstants.storageKeyDailyStats,
      jsonEncode(map),
    );
  }

  Future<bool> getScheduleEnabled() async {
    await init();
    return _prefs!.getBool(AppConstants.storageKeyScheduleEnabled) ?? false;
  }

  Future<void> setScheduleEnabled(bool enabled) async {
    await init();
    await _prefs!.setBool(AppConstants.storageKeyScheduleEnabled, enabled);
  }

  Future<int> getScheduleStartHour() async {
    await init();
    return _prefs!.getInt(AppConstants.storageKeyScheduleStartHour) ??
        AppConstants.defaultScheduleStartHour;
  }

  Future<int> getScheduleEndHour() async {
    await init();
    return _prefs!.getInt(AppConstants.storageKeyScheduleEndHour) ??
        AppConstants.defaultScheduleEndHour;
  }

  Future<void> setScheduleHours(int start, int end) async {
    await init();
    await _prefs!.setInt(AppConstants.storageKeyScheduleStartHour, start);
    await _prefs!.setInt(AppConstants.storageKeyScheduleEndHour, end);
  }
}
