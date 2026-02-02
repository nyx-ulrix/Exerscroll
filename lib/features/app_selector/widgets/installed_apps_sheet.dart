import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/app_info.dart';
import '../../../core/models/blocked_app.dart';
import '../../../core/providers/app_state_provider.dart';
import '../../../core/services/usage_stats_service.dart';

class InstalledAppsSheet extends StatefulWidget {
  const InstalledAppsSheet({super.key});

  @override
  State<InstalledAppsSheet> createState() => _InstalledAppsSheetState();
}

class _InstalledAppsSheetState extends State<InstalledAppsSheet> {
  final Map<String, bool> _selectedPackages = {};
  String _searchQuery = '';
  List<AppInfo> _apps = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  Future<void> _loadApps() async {
    final apps = await UsageStatsService.instance.getAllApps();
    // Sort alphabetically
    apps.sort((a, b) => a.name.compareTo(b.name));

    if (mounted) {
      setState(() {
        _apps = apps;
        _isLoading = false;
        _initSelected();
      });
    }
  }

  void _initSelected() {
    final provider = context.read<AppStateProvider>();
    final blocked = provider.blockedApps.map((a) => a.packageName).toSet();
    for (final app in _apps) {
      _selectedPackages[app.packageName] = blocked.contains(app.packageName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        if (_isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search installed apps...',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
                onChanged: (v) =>
                    setState(() => _searchQuery = v.toLowerCase()),
              ),
            ),
            Expanded(
              child: _buildList(scrollController),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saveSelected,
                    child: const Text('Add selected apps'),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildList(ScrollController scrollController) {
    final filtered = _searchQuery.isEmpty
        ? _apps
        : _apps
            .where((a) =>
                a.name.toLowerCase().contains(_searchQuery) ||
                a.packageName.toLowerCase().contains(_searchQuery))
            .toList();

    return ListView.builder(
      controller: scrollController,
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final app = filtered[index];
        final pkg = app.packageName;
        final isSelected = _selectedPackages[pkg] ?? false;

        Widget? icon;
        if (app.icon != null) {
          icon = Image.memory(app.icon!, width: 40, height: 40);
        } else {
          icon = const Icon(Icons.android);
        }

        return CheckboxListTile(
          secondary: icon,
          title: Text(app.name),
          subtitle: Text(
            pkg,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          value: isSelected,
          onChanged: (v) {
            setState(() => _selectedPackages[pkg] = v ?? false);
          },
        );
      },
    );
  }

  Future<void> _saveSelected() async {
    final provider = context.read<AppStateProvider>();
    final existing = provider.blockedApps.map((a) => a.packageName).toSet();

    for (final app in _apps) {
      final pkg = app.packageName;

      final selected = _selectedPackages[pkg] ?? false;
      if (selected && !existing.contains(pkg)) {
        await provider.addBlockedApp(BlockedApp(
          packageName: pkg,
          displayName: app.name,
          dailyLimitMinutes: 60,
        ));
      }
    }

    if (!mounted) return;
    Navigator.pop(context);
  }
}
