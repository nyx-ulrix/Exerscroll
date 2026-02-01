class BlockedApp {
  final String packageName;
  final String displayName;
  final int dailyLimitMinutes;
  final bool enabled;

  const BlockedApp({
    required this.packageName,
    required this.displayName,
    this.dailyLimitMinutes = 60,
    this.enabled = true,
  });

  BlockedApp copyWith({
    String? packageName,
    String? displayName,
    int? dailyLimitMinutes,
    bool? enabled,
  }) =>
      BlockedApp(
        packageName: packageName ?? this.packageName,
        displayName: displayName ?? this.displayName,
        dailyLimitMinutes: dailyLimitMinutes ?? this.dailyLimitMinutes,
        enabled: enabled ?? this.enabled,
      );

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'displayName': displayName,
        'dailyLimitMinutes': dailyLimitMinutes,
        'enabled': enabled,
      };

  factory BlockedApp.fromJson(Map<String, dynamic> json) => BlockedApp(
        packageName: json['packageName'] as String,
        displayName: json['displayName'] as String,
        dailyLimitMinutes: (json['dailyLimitMinutes'] as num?)?.toInt() ?? 60,
        enabled: json['enabled'] as bool? ?? true,
      );
}
