import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import 'core/providers/app_state_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/blocker/blocker_overlay_app.dart';
import 'features/dashboard/dashboard_screen.dart';

/// Overlay entry point - runs in separate isolate when overlay is shown.
@pragma('vm:entry-point')
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BlockerOverlayApp());
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Permission.camera.request();
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
