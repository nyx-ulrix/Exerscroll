import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/blocked_app.dart';
import '../../core/providers/app_state_provider.dart';
import 'widgets/add_app_sheet.dart';
import 'widgets/installed_apps_sheet.dart';

class AppSelectorScreen extends StatelessWidget {
  const AppSelectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blocked apps'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: () => _showInfo(context),
          ),
        ],
      ),
      body: Consumer<AppStateProvider>(
        builder: (context, provider, _) {
          // Progress tracker logic
          final remaining = (provider.bankedMinutes - provider.usedTodayMinutes)
              .clamp(0, double.infinity);
          final progress = provider.bankedMinutes > 0
              ? (remaining / provider.bankedMinutes).clamp(0.0, 1.0)
              : 0.0;
          final statusColor = remaining > 60
              ? Colors.green
              : remaining > 15
                  ? Colors.orange
                  : Colors.red;
          final hours = remaining.toInt() ~/ 60;
          final minutes = (remaining.toInt() % 60);

          return Column(
            children: [
              // Progress Card
              Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Time remaining',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                          Text(
                            '$hours:${minutes.toString().padLeft(2, '0')} hrs',
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation(statusColor),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Used today: ${provider.usedTodayMinutes.toStringAsFixed(1)} min',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                          Text(
                            'Earned: ${provider.bankedMinutes.toStringAsFixed(1)} min',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // App List
              Expanded(
                child: provider.blockedApps.isEmpty
                    ? _buildEmptyState(context, provider)
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                        itemCount: provider.blockedApps.length,
                        itemBuilder: (context, index) {
                          final app = provider.blockedApps[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                                child: Icon(
                                  Icons.apps_rounded,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              title: Text(app.displayName),
                              subtitle: Text(
                                '${app.dailyLimitMinutes} min daily limit',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_rounded),
                                    onPressed: () => _showEditAppSheet(
                                        context, provider, app),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete_rounded,
                                      color:
                                          Theme.of(context).colorScheme.error,
                                    ),
                                    onPressed: () =>
                                        _confirmRemove(context, provider, app),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Consumer<AppStateProvider>(
        builder: (context, provider, _) {
          return FloatingActionButton(
            onPressed: () => _showInstalledAppsSheet(context, provider),
            child: const Icon(Icons.add_rounded),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppStateProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.apps_rounded,
              size: 80,
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant
                  .withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No apps blocked yet',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Add apps you want to limit. You\'ll need to earn time through exercise to use them.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _showInstalledAppsSheet(context, provider),
              icon: const Icon(Icons.apps_rounded),
              label: const Text('Quick add common apps'),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => _showAddAppSheet(context, provider),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add app manually'),
            ),
          ],
        ),
      ),
    );
  }

  void _showInstalledAppsSheet(
      BuildContext context, AppStateProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => const InstalledAppsSheet(),
    );
  }

  void _showAddAppSheet(BuildContext context, AppStateProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddAppSheet(
        onAdd: (name, package, limit) async {
          await provider.addBlockedApp(BlockedApp(
            packageName: package,
            displayName: name,
            dailyLimitMinutes: limit,
          ));
          if (context.mounted) Navigator.pop(context);
        },
      ),
    );
  }

  void _showEditAppSheet(
      BuildContext context, AppStateProvider provider, BlockedApp app) {
    // Re-use AddAppSheet for editing, pre-filled
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddAppSheet(
        initialName: app.displayName,
        initialPackage: app.packageName,
        initialLimit: app.dailyLimitMinutes,
        onAdd: (name, package, limit) async {
          await provider.updateBlockedApp(BlockedApp(
            packageName: package,
            displayName: name,
            dailyLimitMinutes: limit,
          ));
          if (context.mounted) Navigator.pop(context);
        },
      ),
    );
  }

  void _confirmRemove(
    BuildContext context,
    AppStateProvider provider,
    BlockedApp app,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove app'),
        content: Text(
          'Stop blocking ${app.displayName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await provider.removeBlockedApp(app.packageName);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _showInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About app blocking'),
        content: const Text(
          'ExerScroll blocks selected apps until you earn time by exercising.\n\n'
          'Use "Quick add common apps" for Instagram, TikTok, YouTube, etc., '
          'or "Add app manually" with any package name. On Android, grant "Usage access" for blocking.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
