import 'dart:typed_data';

class AppInfo {
  final String name;
  final String packageName;
  final Uint8List? icon;

  AppInfo({
    required this.name,
    required this.packageName,
    this.icon,
  });

  factory AppInfo.fromMap(Map<String, dynamic> map) {
    return AppInfo(
      name: map['name'] ?? '',
      packageName: map['packageName'] ?? '',
      icon: map['icon'] as Uint8List?,
    );
  }
}
