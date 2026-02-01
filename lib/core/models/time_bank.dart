import 'package:intl/intl.dart';

class DailyStats {
  final DateTime date;
  final double earnedMinutes;
  final double usedMinutes;
  final int pushupReps;
  final int pullupReps;

  const DailyStats({
    required this.date,
    this.earnedMinutes = 0,
    this.usedMinutes = 0,
    this.pushupReps = 0,
    this.pullupReps = 0,
  });

  double get netMinutes => earnedMinutes - usedMinutes;

  Map<String, dynamic> toJson() => {
        'date': DateFormat('yyyy-MM-dd').format(date),
        'earnedMinutes': earnedMinutes,
        'usedMinutes': usedMinutes,
        'pushupReps': pushupReps,
        'pullupReps': pullupReps,
      };

  factory DailyStats.fromJson(Map<String, dynamic> json) {
    final dateStr = json['date'] as String? ?? '';
    return DailyStats(
      date: dateStr.isNotEmpty
          ? DateFormat('yyyy-MM-dd').parse(dateStr)
          : DateTime.now(),
      earnedMinutes: (json['earnedMinutes'] as num?)?.toDouble() ?? 0,
      usedMinutes: (json['usedMinutes'] as num?)?.toDouble() ?? 0,
      pushupReps: (json['pushupReps'] as num?)?.toInt() ?? 0,
      pullupReps: (json['pullupReps'] as num?)?.toInt() ?? 0,
    );
  }
}

class TimeBank {
  final double bankedMinutes;
  final double usedTodayMinutes;
  final DailyStats todayStats;
  final List<DailyStats> history;

  const TimeBank({
    this.bankedMinutes = 0,
    this.usedTodayMinutes = 0,
    required this.todayStats,
    this.history = const [],
  });

  double get remainingMinutes => bankedMinutes - usedTodayMinutes;

  TimeBank copyWith({
    double? bankedMinutes,
    double? usedTodayMinutes,
    DailyStats? todayStats,
    List<DailyStats>? history,
  }) =>
      TimeBank(
        bankedMinutes: bankedMinutes ?? this.bankedMinutes,
        usedTodayMinutes: usedTodayMinutes ?? this.usedTodayMinutes,
        todayStats: todayStats ?? this.todayStats,
        history: history ?? this.history,
      );
}
