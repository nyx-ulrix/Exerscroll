import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'overlay_service.dart';
import 'storage_service.dart';
import 'usage_stats_service.dart';

/// Background task that runs periodically to monitor app usage even when ExerScroll is closed.
/// Uses WorkManager to schedule tasks with the Android system.
class BackgroundUsageMonitor {
  BackgroundUsageMonitor._();
  static BackgroundUsageMonitor? _instance;
  static BackgroundUsageMonitor get instance =>
      _instance ??= BackgroundUsageMonitor._();

  static const String _taskName = 'checkUsageBackground';
  static const String _periodicTaskName = 'checkUsagePeriodicBackground';

  /// Initialize background task scheduling with platform channels.
  /// Must be called from main.dart as a top-level function.
  static void initialize() {
    Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: kDebugMode,
    );
  }

  /// Start periodic background monitoring (every 15 minutes).
  /// This runs even when the app is closed or backgrounded.
  Future<void> startPeriodicMonitoring() async {
    try {
      await Workmanager().registerPeriodicTask(
        _periodicTaskName,
        _periodicTaskName,
        frequency: const Duration(minutes: 15),
        backoffPolicy: BackoffPolicy.exponential,
        backoffPolicyDelay: const Duration(minutes: 1),
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
      );
      debugPrint(
          '[ExerScroll] Background monitoring started (15 min interval)');
    } catch (e) {
      debugPrint('[ExerScroll] Error starting background monitoring: $e');
    }
  }

  /// Stop periodic background monitoring.
  Future<void> stopPeriodicMonitoring() async {
    try {
      await Workmanager().cancelByTag(_periodicTaskName);
      debugPrint('[ExerScroll] Background monitoring stopped');
    } catch (e) {
      debugPrint('[ExerScroll] Error stopping background monitoring: $e');
    }
  }

  /// Check usage and update stored values.
  /// Called by WorkManager in background, or by app when in foreground.
  /// Returns true if usage was detected and time was deducted.
  static Future<bool> checkUsageInBackground() async {
    try {
      final storage = StorageService.instance;
      final usageService = UsageStatsService.instance;

      debugPrint('[ExerScroll-BG] Checking usage in background...');

      // Get blocked apps
      final blockedApps = await storage.getBlockedApps();
      if (blockedApps.isEmpty) {
        debugPrint('[ExerScroll-BG] No blocked apps configured');
        return false;
      }

      final packages = blockedApps.map((a) => a.packageName).toList();

      // Get current usage stats from OS
      final currentTotal = await usageService.getCumulativeUsageToday(packages);
      debugPrint(
          '[ExerScroll-BG] Current OS usage total: ${currentTotal.toStringAsFixed(1)} min');

      // Get last known total from storage
      final lastKnownTotal = await storage.getDailyUsageTotal();
      debugPrint(
          '[ExerScroll-BG] Last known total: ${lastKnownTotal.toStringAsFixed(1)} min');

      // Calculate delta
      if (currentTotal > lastKnownTotal) {
        final delta = currentTotal - lastKnownTotal;
        debugPrint(
            '[ExerScroll-BG] Usage delta detected: ${delta.toStringAsFixed(1)} min');

        // Get current banked time
        var bankedMinutes = await storage.getBankedMinutes();
        var usedTodayMinutes = await storage.getUsedTodayMinutes();

        // Deduct time
        final actualDeduction = delta.clamp(0, bankedMinutes);
        bankedMinutes =
            (bankedMinutes - actualDeduction).clamp(0, double.infinity);
        usedTodayMinutes =
            (usedTodayMinutes + actualDeduction).clamp(0, double.infinity);

        // Save updated values
        await storage.saveBankedMinutes(bankedMinutes);
        await storage.saveUsedTodayMinutes(usedTodayMinutes);
        await storage.saveDailyUsageTotal(currentTotal);

        debugPrint(
            '[ExerScroll-BG] Time deducted: ${actualDeduction.toStringAsFixed(1)} min');
        debugPrint(
            '[ExerScroll-BG] Remaining banked: ${bankedMinutes.toStringAsFixed(1)} min');

        // Check if user is out of time
        if (bankedMinutes <= 0 && currentTotal > 0) {
          debugPrint(
              '[ExerScroll-BG] USER OUT OF TIME! Triggering overlay from background...');

          // Attempt to show overlay immediately from background
          try {
            final overlayService = OverlayService.instance;
            // We use a generic name or the first blocked app name since we don't know exactly which one is foreground
            final appName = blockedApps.isNotEmpty
                ? blockedApps.first.displayName
                : 'Blocked App';

            await overlayService.showBlockerOverlay(
              blockedAppName: appName,
              remainingMinutes: 0,
              usedMinutes: usedTodayMinutes,
            );
            debugPrint('[ExerScroll-BG] Background overlay trigger requested');
          } catch (e) {
            debugPrint(
                '[ExerScroll-BG] Failed to show overlay from background: $e');
          }

          // Mark that overlay should be shown on app resume (backup)
          await storage.saveBankedMinutes(bankedMinutes);
        }

        return true;
      } else if (currentTotal < lastKnownTotal) {
        // Usage went backwards (likely day reset)
        debugPrint(
            '[ExerScroll-BG] Usage reset detected (new day or clock adjustment)');
        await storage.saveDailyUsageTotal(currentTotal);
      }

      return false;
    } catch (e) {
      debugPrint('[ExerScroll-BG] Error checking background usage: $e');
      return false;
    }
  }
}

/// Top-level callback function for WorkManager.
/// MUST be a top-level function, not a class method.
/// Called by the Android system in a separate isolate.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      if (taskName == BackgroundUsageMonitor._periodicTaskName ||
          taskName == BackgroundUsageMonitor._taskName) {
        debugPrint('[ExerScroll-BG] WorkManager task started: $taskName');
        await BackgroundUsageMonitor.checkUsageInBackground();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[ExerScroll-BG] WorkManager task error: $e');
      return false;
    }
  });
}
