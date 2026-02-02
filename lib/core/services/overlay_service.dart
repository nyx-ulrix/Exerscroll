import 'dart:convert';

import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:flutter/foundation.dart';

/// Service for overlay app blocking - requests permission and shows overlay.
class OverlayService {
  OverlayService._();
  static OverlayService? _instance;
  static OverlayService get instance => _instance ??= OverlayService._();

  /// Check if overlay (display over other apps) permission is granted.
  Future<bool> isOverlayPermissionGranted() async {
    return FlutterOverlayWindow.isPermissionGranted();
  }

  /// Request overlay permission. Opens system settings.
  /// Returns true once user grants permission.
  Future<bool> requestOverlayPermission() async {
    return (await FlutterOverlayWindow.requestPermission()) ?? false;
  }

  /// Show the blocker overlay (full screen over other apps).
  Future<void> showBlockerOverlay({
    String? blockedAppName,
    double remainingMinutes = 0,
    double usedMinutes = 0,
  }) async {
    // Check if permission is granted before attempting to show overlay
    final hasPermission = await isOverlayPermissionGranted();
    debugPrint(
        '[OverlayService] Attempting to show overlay. Permission granted: $hasPermission');
    debugPrint(
        '[OverlayService] Blocked app: $blockedAppName, Remaining: $remainingMinutes, Used: $usedMinutes');
    if (!hasPermission) {
      // Request permission but don't fail - user can grant it in settings
      debugPrint('[OverlayService] Permission not granted, requesting...');
      await requestOverlayPermission();
      return;
    }

    try {
      debugPrint('[OverlayService] Sharing data with overlay...');
      await FlutterOverlayWindow.shareData(jsonEncode({
        'blockedAppName': blockedAppName,
        'remainingMinutes': remainingMinutes,
        'usedMinutes': usedMinutes,
      }));
      debugPrint('[OverlayService] Data shared, showing overlay...');
      await FlutterOverlayWindow.showOverlay(
        height: WindowSize.matchParent,
        width: WindowSize.matchParent,
        alignment: OverlayAlignment.center,
        overlayTitle: 'ExerScroll',
        overlayContent: 'App blocking active',
      );
      debugPrint('[OverlayService] Overlay shown successfully');
    } catch (e) {
      debugPrint('[OverlayService] Error showing overlay: $e');
      rethrow;
    }
  }

  /// Close the blocker overlay.
  Future<void> closeOverlay() async {
    debugPrint('[OverlayService] Closing overlay');
    await FlutterOverlayWindow.closeOverlay();
  }
}
