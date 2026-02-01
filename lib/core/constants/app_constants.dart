class AppConstants {
  AppConstants._();

  static const String storageKeyBlockedApps = 'blocked_apps';
  static const String storageKeyExerciseConfigs = 'exercise_configs';
  static const String storageKeyTimeBank = 'time_bank';
  static const String storageKeyDailyStats = 'daily_stats';
  static const String storageKeyScheduleEnabled = 'schedule_enabled';
  static const String storageKeyScheduleStartHour = 'schedule_start_hour';
  static const String storageKeyScheduleEndHour = 'schedule_end_hour';

  static const int defaultScheduleStartHour = 20; // 8 PM
  static const int defaultScheduleEndHour = 7; // 7 AM next day
}
