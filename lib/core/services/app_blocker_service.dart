import '../models/blocked_app.dart';
import 'storage_service.dart';

/// Service for checking if an app is blocked and has enough time.
class AppBlockerService {
  AppBlockerService._();
  static AppBlockerService? _instance;
  static AppBlockerService get instance => _instance ??= AppBlockerService._();

  final _storage = StorageService.instance;

  Future<bool> isAppBlocked(String packageName) async {
    final apps = await _storage.getBlockedApps();
    return apps.any((a) => a.packageName == packageName && a.enabled);
  }

  Future<bool> hasEnoughTime(String packageName) async {
    final banked = await _storage.getBankedMinutes();
    return banked > 0;
  }

  Future<BlockedApp?> getBlockedApp(String packageName) async {
    final apps = await _storage.getBlockedApps();
    try {
      return apps.firstWhere((a) => a.packageName == packageName);
    } catch (_) {
      return null;
    }
  }
}
