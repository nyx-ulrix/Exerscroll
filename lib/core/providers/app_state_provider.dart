import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/blocked_app.dart';
import '../models/exercise_config.dart';
import '../models/time_bank.dart';
import '../services/background_usage_monitor.dart';
import '../services/overlay_service.dart';
import '../services/storage_service.dart';
import '../services/usage_stats_service.dart';

/// Main application state provider using Provider pattern.
/// Manages:
/// - Blocked apps and their configuration
/// - Time bank (earned vs used minutes)
/// - Exercise configurations per exercise type
/// - Daily statistics and usage tracking
/// - App blocking schedule (optional time-based blocking)
/// - Overlay display when time runs out
class AppStateProvider extends ChangeNotifier {
  final _storage = StorageService.instance;
  final _usageService = UsageStatsService.instance;
  final _overlayService = OverlayService.instance;

  // === State ===
  List<BlockedApp> _blockedApps = [];
  List<ExerciseConfig> _exerciseConfigs = [];
  double _bankedMinutes = 0;
  double _usedTodayMinutes = 0;
  // Track total usage reported by OS for today to calculate deltas
  double _lastKnownUsageTotal = 0;
  Map<String, DailyStats> _dailyStatsHistory = {};
  bool _scheduleEnabled = false;
  int _scheduleStartHour = 20;
  int _scheduleEndHour = 7;
  bool _isLoading = true;
  Timer? _usageTimer;

  List<BlockedApp> get blockedApps => List.unmodifiable(_blockedApps);
  List<ExerciseConfig> get exerciseConfigs =>
      List.unmodifiable(_exerciseConfigs);
  double get bankedMinutes => _bankedMinutes;
  double get usedTodayMinutes => _usedTodayMinutes;
  double get remainingMinutes => _bankedMinutes - _usedTodayMinutes;
  bool get scheduleEnabled => _scheduleEnabled;
  int get scheduleStartHour => _scheduleStartHour;
  int get scheduleEndHour => _scheduleEndHour;
  bool get isLoading => _isLoading;

  DailyStats get todayStats {
    final now = DateTime.now();
    final key =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return _dailyStatsHistory[key] ??
        DailyStats(date: DateTime(now.year, now.month, now.day));
  }

  List<DailyStats> get recentHistory {
    final sorted = _dailyStatsHistory.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return sorted.take(14).toList();
  }

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();

    _blockedApps = await _storage.getBlockedApps();
    _exerciseConfigs = await _storage.getExerciseConfigs();
    _bankedMinutes =
        (await _storage.getBankedMinutes()).clamp(0, double.infinity);
    _usedTodayMinutes =
        (await _storage.getUsedTodayMinutes()).clamp(0, double.infinity);
    _lastKnownUsageTotal =
        (await _storage.getDailyUsageTotal()).clamp(0, double.infinity);
    _dailyStatsHistory = await _storage.getDailyStatsHistory();
    _scheduleEnabled = await _storage.getScheduleEnabled();
    _scheduleStartHour = await _storage.getScheduleStartHour();
    _scheduleEndHour = await _storage.getScheduleEndHour();

    await _maybeResetDailyIfNewDay();

    // Reload state from storage to ensure we have the latest updates from background tasks
    await _refreshStateFromStorage();

    // Start both foreground and background usage tracking
    _startUsageTracking();
    BackgroundUsageMonitor.instance.startPeriodicMonitoring();

    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _usageTimer?.cancel();
    BackgroundUsageMonitor.instance.stopPeriodicMonitoring();
    super.dispose();
  }

  /// Reloads critical state from storage to sync with potential background updates
  Future<void> _refreshStateFromStorage() async {
    // Reload storage from disk to catch updates from background isolate
    await _storage.reload();

    _bankedMinutes =
        (await _storage.getBankedMinutes()).clamp(0, double.infinity);
    _usedTodayMinutes =
        (await _storage.getUsedTodayMinutes()).clamp(0, double.infinity);
    _lastKnownUsageTotal =
        (await _storage.getDailyUsageTotal()).clamp(0, double.infinity);
    _dailyStatsHistory = await _storage.getDailyStatsHistory();
    notifyListeners();
  }

  /// Called when app resumes from background.
  /// Checks current usage and shows overlay if user is out of time.
  Future<void> onAppResume() async {
    if (_blockedApps.isEmpty) return;

    debugPrint('[ExerScroll] App resumed - checking usage...');

    // Refresh state first to get any updates from background tasks
    await _refreshStateFromStorage();

    // Get current usage stats
    final packages = _blockedApps.map((a) => a.packageName).toList();
    final currentTotal = await _usageService.getCumulativeUsageToday(packages);

    // Update tracking
    if (currentTotal > _lastKnownUsageTotal) {
      final delta = currentTotal - _lastKnownUsageTotal;
      if (delta > 0) {
        debugPrint(
            '[ExerScroll] Usage detected: ${delta.toStringAsFixed(1)}min, deducting...');
        await deductUsageTime(delta);
        _lastKnownUsageTotal = currentTotal;
        await _storage.saveDailyUsageTotal(_lastKnownUsageTotal);
      }
    }

    // Check if overlay should be shown
    await _maybeShowOverlay();
  }

  void _startUsageTracking() {
    _usageTimer?.cancel();
    // Check every 10 seconds for app usage changes and show overlay if needed
    _usageTimer =
        Timer.periodic(const Duration(seconds: 10), (_) => _checkUsage());
    // Check immediately for immediate overlay response
    _checkUsage();
  }

  /// Polls device usage stats and deducts time if blocked apps were used.
  /// Also triggers overlay display if user has no remaining time.
  /// This runs periodically to detect app usage in real-time.
  Future<void> _checkUsage() async {
    if (_blockedApps.isEmpty) return;

    final packages = _blockedApps.map((a) => a.packageName).toList();
    final currentTotal = await _usageService.getCumulativeUsageToday(packages);

    if (currentTotal > _lastKnownUsageTotal) {
      // User has used more time on blocked apps since last check
      final delta = currentTotal - _lastKnownUsageTotal;
      if (delta > 0) {
        // Deduct the new usage from banked minutes
        await deductUsageTime(delta);
        _lastKnownUsageTotal = currentTotal;
        await _storage.saveDailyUsageTotal(_lastKnownUsageTotal);

        // Show blocking overlay if user is now out of time
        await _maybeShowOverlay();
      }
    } else if (currentTotal < _lastKnownUsageTotal) {
      // Usage total went down (likely a day reset or clock adjustment)
      _lastKnownUsageTotal = currentTotal;
      await _storage.saveDailyUsageTotal(_lastKnownUsageTotal);
    }

    // Also check if user is already out of time (even if usage didn't increase)
    // This handles the case where app is reopened after being closed
    if (remainingMinutes <= 0 && currentTotal > 0) {
      await _maybeShowOverlay();
    }
  }

  /// Show overlay if user has no remaining time and is using a blocked app.
  Future<void> _maybeShowOverlay() async {
    debugPrint(
        '[ExerScroll] _maybeShowOverlay called. Remaining: $remainingMinutes, BlockedApps: ${_blockedApps.length}');

    if (remainingMinutes > 0) {
      // User has time, no need to show overlay
      try {
        await _overlayService.closeOverlay();
        debugPrint('[ExerScroll] Overlay closed - user has time');
      } catch (_) {
        // Overlay might not be visible, ignore
      }
      return;
    }

    // User is out of time - show overlay immediately
    debugPrint('[ExerScroll] User is out of time! Showing overlay...');
    if (_blockedApps.isNotEmpty) {
      final firstApp = _blockedApps.first;
      try {
        debugPrint(
            '[ExerScroll] Attempting to show overlay for ${firstApp.displayName}');
        await _overlayService.showBlockerOverlay(
          blockedAppName: firstApp.displayName,
          remainingMinutes: remainingMinutes.clamp(0, double.infinity),
          usedMinutes: _usedTodayMinutes,
        );
        debugPrint('[ExerScroll] Overlay shown successfully');
      } catch (e) {
        debugPrint('[ExerScroll] Failed to show overlay: $e');
      }
    } else {
      debugPrint('[ExerScroll] No blocked apps available');
    }
  }

  Future<void> _maybeResetDailyIfNewDay() async {
    final today = DateTime.now();
    final lastKey = _dailyStatsHistory.keys.isNotEmpty
        ? _dailyStatsHistory.keys.reduce(
            (a, b) => a.compareTo(b) > 0 ? a : b,
          )
        : null;
    if (lastKey != null) {
      final lastDate = DateTime.parse(lastKey);
      if (today.day != lastDate.day ||
          today.month != lastDate.month ||
          today.year != lastDate.year) {
        _usedTodayMinutes = 0;
        _lastKnownUsageTotal = 0;
        await _storage.saveUsedTodayMinutes(0);
        await _storage.saveDailyUsageTotal(0);
      }
    }
  }

  Future<void> addBlockedApp(BlockedApp app) async {
    if (_blockedApps.any((a) => a.packageName == app.packageName)) return;
    _blockedApps = [..._blockedApps, app];
    await _storage.saveBlockedApps(_blockedApps);
    notifyListeners();
  }

  Future<void> removeBlockedApp(String packageName) async {
    _blockedApps =
        _blockedApps.where((a) => a.packageName != packageName).toList();
    await _storage.saveBlockedApps(_blockedApps);
    notifyListeners();
  }

  Future<void> updateBlockedApp(BlockedApp app) async {
    _blockedApps = _blockedApps
        .map((a) => a.packageName == app.packageName ? app : a)
        .toList();
    await _storage.saveBlockedApps(_blockedApps);
    notifyListeners();
  }

  Future<void> updateExerciseConfig(ExerciseConfig config) async {
    _exerciseConfigs = _exerciseConfigs
        .map((c) => c.type == config.type ? config : c)
        .toList();
    await _storage.saveExerciseConfigs(_exerciseConfigs);
    notifyListeners();
  }

  ExerciseConfig getConfigFor(ExerciseType type) => _exerciseConfigs.firstWhere(
        (c) => c.type == type,
        orElse: () => ExerciseConfig(type: type),
      );

  Future<void> creditExerciseTime(ExerciseType type, int reps) async {
    final config = getConfigFor(type);
    if (!config.enabled || reps < config.minimumRepsToCredit) return;
    final minutes = reps * config.minutesPerRep;
    _bankedMinutes += minutes;
    await _storage.saveBankedMinutes(_bankedMinutes);

    final stats = todayStats;
    final updated = DailyStats(
      date: stats.date,
      earnedMinutes: stats.earnedMinutes + minutes,
      usedMinutes: stats.usedMinutes,
      pushupReps: type == ExerciseType.pushup
          ? stats.pushupReps + reps
          : stats.pushupReps,
      pullupReps: type == ExerciseType.pullup
          ? stats.pullupReps + reps
          : stats.pullupReps,
    );
    _dailyStatsHistory[
            '${stats.date.year}-${stats.date.month.toString().padLeft(2, '0')}-${stats.date.day.toString().padLeft(2, '0')}'] =
        updated;
    await _storage.saveDailyStats(updated);
    notifyListeners();
  }

  Future<void> deductUsageTime(double minutes) async {
    // Only deduct if we have time available
    final actualDeduction = minutes.clamp(0, _bankedMinutes);
    if (actualDeduction <= 0) return;

    _bankedMinutes =
        (_bankedMinutes - actualDeduction).clamp(0, double.infinity);
    _usedTodayMinutes =
        (_usedTodayMinutes + actualDeduction).clamp(0, double.infinity);
    await _storage.saveBankedMinutes(_bankedMinutes);
    await _storage.saveUsedTodayMinutes(_usedTodayMinutes);

    final stats = todayStats;
    final updated = DailyStats(
      date: stats.date,
      earnedMinutes: stats.earnedMinutes,
      usedMinutes:
          (stats.usedMinutes + actualDeduction).clamp(0, double.infinity),
      pushupReps: stats.pushupReps,
      pullupReps: stats.pullupReps,
    );
    _dailyStatsHistory[
            '${stats.date.year}-${stats.date.month.toString().padLeft(2, '0')}-${stats.date.day.toString().padLeft(2, '0')}'] =
        updated;
    await _storage.saveDailyStats(updated);
    notifyListeners();
  }

  Future<void> setSchedule(bool enabled, {int? startHour, int? endHour}) async {
    _scheduleEnabled = enabled;
    if (startHour != null) _scheduleStartHour = startHour;
    if (endHour != null) _scheduleEndHour = endHour;
    await _storage.setScheduleEnabled(enabled);
    await _storage.setScheduleHours(_scheduleStartHour, _scheduleEndHour);
    notifyListeners();
  }

  bool get isBlockingActive {
    if (!_scheduleEnabled) return true;
    final now = DateTime.now();
    final hour = now.hour + now.minute / 60;
    if (_scheduleStartHour > _scheduleEndHour) {
      return hour >= _scheduleStartHour || hour < _scheduleEndHour;
    }
    return hour >= _scheduleStartHour && hour < _scheduleEndHour;
  }
}
