import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

class OverlayManager {
  static const MethodChannel _channel =
      MethodChannel('com.exerscroll.exerscroll/overlay');

  static Future<bool> hasOverlayPermission() async {
    if (Platform.isAndroid) {
      return await FlutterOverlayWindow.isPermissionGranted();
    }
    return false;
  }

  static Future<void> requestOverlayPermission() async {
    if (Platform.isAndroid) {
      await FlutterOverlayWindow.requestPermission();
    }
  }

  static Future<bool> hasUsageStatsPermission() async {
    if (Platform.isAndroid) {
      try {
        final result =
            await _channel.invokeMethod<bool>('checkUsageStatsPermission');
        return result ?? false;
      } catch (e) {
        return false;
      }
    }
    return false;
  }

  static Future<void> requestUsageStatsPermission() async {
    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod('requestUsageStatsPermission');
      } catch (e) {
        // Ignore
      }
    }
  }

  static Future<bool> isServiceRunning() async {
    if (Platform.isAndroid) {
      return true;
    }
    return false;
  }
}
