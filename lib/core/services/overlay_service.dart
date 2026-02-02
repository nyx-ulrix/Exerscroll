import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:flutter/foundation.dart';

/// Service for overlay app blocking - requests permission and shows overlay.
class OverlayService {
  OverlayService._();
  static OverlayService? _instance;
  static OverlayService get instance => _instance ??= OverlayService._();

  static const MethodChannel _channel =
      MethodChannel('com.exerscroll.exerscroll/overlay');

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

    if (!hasPermission) {
      // Request permission but don't fail - user can grant it in settings
      debugPrint('[OverlayService] Permission not granted, requesting...');
      await requestOverlayPermission();
      return;
    }

    try {
      debugPrint('[OverlayService] Triggering NATIVE overlay service...');
      // Use our new native service for "immediate" blocking
      await _channel.invokeMethod('startNativeOverlay');

      // OPTIONAL: Still use the Flutter overlay for the nice UI with progress bars if needed,
      // but the native one is "immediate" and robust.
      // If we want to use the native one strictly as requested by the user, we rely on startNativeOverlay.
      // However, the native overlay is simple (XML layout). The user might want the Flutter UI?
      // The user's prompt says "Implement OverlayService... EXACTLY as specified".
      // The specified XML is basic. I will stick to the native one for the blocker.

      debugPrint('[OverlayService] Native overlay started successfully');
    } catch (e) {
      debugPrint('[OverlayService] Error showing native overlay: $e');
      // Fallback to Flutter overlay if native fails?
    }
  }

  /// Close the blocker overlay.
  Future<void> closeOverlay() async {
    debugPrint('[OverlayService] Closing overlay');
    try {
      await _channel.invokeMethod('stopNativeOverlay');
    } catch (e) {
      debugPrint('[OverlayService] Error closing native overlay: $e');
    }
    // Also close flutter overlay just in case
    await FlutterOverlayWindow.closeOverlay();
  }
}
