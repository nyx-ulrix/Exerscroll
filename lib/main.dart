import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import 'core/providers/app_state_provider.dart';
import 'core/services/background_usage_monitor.dart';
import 'core/theme/app_theme.dart';
import 'features/blocker/blocker_overlay_app.dart';
import 'features/dashboard/dashboard_screen.dart';

/// Entry point for the blocker overlay running in a separate isolate.
/// This is shown on top of blocked apps when user has no remaining time.
/// Runs in its own isolate to avoid conflicts with main app.
@pragma('vm:entry-point')
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BlockerOverlayApp());
}

/// Main app entry point.
/// Initializes permissions, orientation, background monitoring, and starts the dashboard.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize background usage monitoring (runs even when app is closed)
  BackgroundUsageMonitor.initialize();

  // Request camera permission for pose detection
  await Permission.camera.request();
  // Lock app to portrait/landscape modes (no reverse)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const ExerScrollApp());
}

class ExerScrollApp extends StatelessWidget {
  const ExerScrollApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppStateProvider()..load(),
      child: MaterialApp(
        title: 'ExerScroll',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const DashboardScreen(),
      ),
    );
  }
}
