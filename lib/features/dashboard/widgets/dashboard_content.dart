import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/app_state_provider.dart';

class DashboardContent extends StatelessWidget {
  final VoidCallback? onStartSession;

  const DashboardContent({super.key, this.onStartSession});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ExerScroll',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Earn screen time through exercise',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _TimeBankCard(
                  bankedMinutes: provider.bankedMinutes,
                  usedToday: provider.usedTodayMinutes,
                  todayStats: provider.todayStats,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Quick action',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    FilledButton.icon(
                      onPressed: onStartSession ?? () {},
                      icon: const Icon(Icons.fitness_center_rounded, size: 20),
                      label: const Text('Start session'),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _StatsOverview(provider: provider),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Text(
                  'Weekly progress',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _WeeklyChart(stats: provider.recentHistory),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        );
      },
    );
  }
}

class _TimeBankCard extends StatelessWidget {
  final double bankedMinutes;
  final double usedToday;
  final dynamic todayStats;

  const _TimeBankCard({
    required this.bankedMinutes,
    required this.usedToday,
    required this.todayStats,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = bankedMinutes;
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Banked time',
                  style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${remaining.toStringAsFixed(0)} min',
                    style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: bankedMinutes > 60 ? 1 : (bankedMinutes / 60).clamp(0, 1),
                minHeight: 8,
                backgroundColor: theme.colorScheme.surface,
                valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Used today: ${usedToday.toStringAsFixed(0)} min',
              style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsOverview extends StatelessWidget {
  final AppStateProvider provider;

  const _StatsOverview({required this.provider});

  @override
  Widget build(BuildContext context) {
    final stats = provider.todayStats;
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Today's stats",
              style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    icon: Icons.trending_up_rounded,
                    label: 'Earned',
                    value: '${stats.earnedMinutes.toStringAsFixed(0)} min',
                  ),
                ),
                Expanded(
                  child: _StatTile(
                    icon: Icons.fitness_center_rounded,
                    label: 'Push-ups',
                    value: '${stats.pushupReps}',
                  ),
                ),
                Expanded(
                  child: _StatTile(
                    icon: Icons.fitness_center_rounded,
                    label: 'Pull-ups',
                    value: '${stats.pullupReps}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${provider.blockedApps.length} apps blocked',
              style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, size: 24, color: theme.colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

class _WeeklyChart extends StatelessWidget {
  final List<dynamic> stats;

  const _WeeklyChart({required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxEarned = stats.isEmpty
        ? 1.0
        : stats
                .map((s) => s.earnedMinutes)
                .reduce((a, b) => a > b ? a : b)
                .toDouble() +
            1;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          height: 120,
          child: stats.isEmpty
              ? Center(
                  child: Text(
                    'No data yet. Start exercising!',
                    style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                  ),
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: stats.take(7).map((s) {
                    final height = (s.earnedMinutes / maxEarned).clamp(0.1, 1.0);
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          s.earnedMinutes.toStringAsFixed(0),
                          style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 24,
                          height: 80.0 * height,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('E').format(s.date).substring(0, 1),
                          style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
        ),
      ),
    );
  }
}
