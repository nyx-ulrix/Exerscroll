import 'package:flutter/services.dart';
import 'package:usage_stats/usage_stats.dart';
import '../models/app_info.dart';

/// Service for tracking app usage statistics across the device.
/// Uses platform-specific channels to access Android's UsageStatsManager API.
class UsageStatsService {
  UsageStatsService._();
  static UsageStatsService? _instance;
  static UsageStatsService get instance => _instance ??= UsageStatsService._();

  static const MethodChannel _channel =
      MethodChannel('com.exerscroll.exerscroll/overlay');

  Future<List<AppInfo>> getAllApps() async {
    try {
      final List<dynamic>? apps =
          await _channel.invokeMethod('getInstalledApps');
      if (apps == null) return [];

      return apps
          .map((e) => AppInfo.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      print('Error getting installed apps: $e');
      return [];
    }
  }

  /// Returns the cumulative foreground time (in minutes) for a list of package names today.
  /// This sums up all foreground time for the specified apps from midnight to now.
  /// Returns 0.0 if no usage found or on error.
  Future<double> getCumulativeUsageToday(List<String> packageNames) async {
    if (packageNames.isEmpty) return 0;

    final now = DateTime.now();
    // Start of day (midnight)
    final startOfDay = DateTime(now.year, now.month, now.day);
    // End of day (23:59:59)
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    try {
      double totalMilliseconds = 0;

      final List<UsageInfo> stats = await UsageStats.queryUsageStats(
        startOfDay,
        endOfDay,
      );

      for (var info in stats) {
        if (packageNames.contains(info.packageName)) {
          if (info.totalTimeInForeground != null) {
            totalMilliseconds +=
                double.tryParse(info.totalTimeInForeground!) ?? 0;
          }
        }
      }

      return totalMilliseconds / 1000 / 60; // Return minutes
    } catch (e) {
      print('Error querying usage stats: $e');
      return 0;
    }
  }
}
