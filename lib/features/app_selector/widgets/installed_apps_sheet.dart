import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/blocked_app.dart';
import '../../../core/providers/app_state_provider.dart';
import '../common_apps_list.dart';

/// Bottom sheet to add common apps to block list (no device scan; Android 14+ compatible).
class InstalledAppsSheet extends StatefulWidget {
  const InstalledAppsSheet({super.key});

  @override
  State<InstalledAppsSheet> createState() => _InstalledAppsSheetState();
}

class _InstalledAppsSheetState extends State<InstalledAppsSheet> {
  final Map<String, bool> _selectedPackages = {};
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _initSelected();
  }

  void _initSelected() {
    final provider = context.read<AppStateProvider>();
    final blocked = provider.blockedApps.map((a) => a.packageName).toSet();
    for (final app in commonApps) {
      _selectedPackages[app.package] = blocked.contains(app.package);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search common apps...',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
                onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
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
        ? commonApps
        : commonApps.where((a) =>
            a.name.toLowerCase().contains(_searchQuery) ||
            a.package.toLowerCase().contains(_searchQuery)).toList();

    return ListView.builder(
      controller: scrollController,
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final app = filtered[index];
        final isSelected = _selectedPackages[app.package] ?? false;
        return CheckboxListTile(
          title: Text(app.name),
          subtitle: Text(
            app.package,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          value: isSelected,
          onChanged: (v) {
            setState(() => _selectedPackages[app.package] = v ?? false);
          },
        );
      },
    );
  }

  Future<void> _saveSelected() async {
    final provider = context.read<AppStateProvider>();
    final existing = provider.blockedApps.map((a) => a.packageName).toSet();

    for (final app in commonApps) {
      final selected = _selectedPackages[app.package] ?? false;
      if (selected && !existing.contains(app.package)) {
        await provider.addBlockedApp(BlockedApp(
          packageName: app.package,
          displayName: app.name,
          dailyLimitMinutes: 60,
        ));
      }
    }

    if (!mounted) return;
    Navigator.pop(context);
  }
}
