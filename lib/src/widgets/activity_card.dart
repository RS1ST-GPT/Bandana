import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// A Material 3 card showing summary stats for a recorded activity.
class ActivityCard extends StatelessWidget {
  final String label;
  final int sessionCount;
  final int totalSamples;
  final VoidCallback? onTap;

  const ActivityCard({
    super.key,
    required this.label,
    required this.sessionCount,
    required this.totalSamples,
    this.onTap,
  });

  /// Map activity labels to icons.
  static IconData iconForLabel(String label) {
    return switch (label.toLowerCase()) {
      'walking' => Icons.directions_walk,
      'running' => Icons.directions_run,
      'sitting' => Icons.chair,
      'standing' => Icons.accessibility_new,
      'climbing stairs' => Icons.stairs,
      'descending stairs' => Icons.trending_down,
      _ => Icons.fitness_center,
    };
  }

  /// Map activity labels to gradient colors.
  static List<Color> colorsForLabel(String label) {
    return switch (label.toLowerCase()) {
      'walking' => [const Color(0xFF26A69A), const Color(0xFF80CBC4)],
      'running' => [const Color(0xFFEF5350), const Color(0xFFEF9A9A)],
      'sitting' => [const Color(0xFF42A5F5), const Color(0xFF90CAF9)],
      'standing' => [const Color(0xFFAB47BC), const Color(0xFFCE93D8)],
      'climbing stairs' => [const Color(0xFFFFA726), const Color(0xFFFFCC80)],
      'descending stairs' => [const Color(0xFF66BB6A), const Color(0xFFA5D6A7)],
      _ => [const Color(0xFF78909C), const Color(0xFFB0BEC5)],
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = colorsForLabel(label);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? colors.map((c) => c.withValues(alpha: 0.2)).toList()
                  : colors.map((c) => c.withValues(alpha: 0.12)).toList(),
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors[0].withValues(alpha: isDark ? 0.3 : 0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Icon(
                  iconForLabel(label),
                  color: colors[0],
                  size: 24,
                ),
              ),
              const SizedBox(height: 12),
              // Label
              Text(
                label,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // Stats
              Text(
                '$sessionCount session${sessionCount != 1 ? 's' : ''}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                '$totalSamples samples',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
