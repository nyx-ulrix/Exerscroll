import 'package:flutter/services.dart';
import 'package:usage_stats/usage_stats.dart';
import '../models/app_info.dart';
import 'storage_service.dart';

class UsageStatsService {
  UsageStatsService._();
  static UsageStatsService? _instance;
  static UsageStatsService get instance => _instance ??= UsageStatsService._();

  static const MethodChannel _channel =
      MethodChannel('com.exerscroll.exerscroll/overlay');
  final _storage = StorageService.instance;

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

  Future<double> getCumulativeUsageToday(List<String> packageNames) async {
    if (packageNames.isEmpty) return 0;

    final now = DateTime.now();
    // Start of day
    final startOfDay = DateTime(now.year, now.month, now.day);
    // End of day
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    try {
      double totalMilliseconds = 0;
      // Some devices work better with queryAndAggregateUsageStats if available,
      // but usage_stats package exposes queryUsageStats.
      // We'll stick to queryUsageStats but be robust.

      // Attempt to query per-package if list is small to avoid huge list?
      // No, queryUsageStats takes range.

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
