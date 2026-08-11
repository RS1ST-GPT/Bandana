import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/sensor_data.dart';

/// Real-time line chart for 3-axis accelerometer data.
///
/// Displays a rolling window of the most recent [maxPoints] readings,
/// with separate colored lines for aX, aY, aZ.
class SensorChart extends StatelessWidget {
  /// Sensor readings to plot (most recent at the end).
  final List<SensorReading> readings;

  /// Maximum number of data points to display.
  final int maxPoints;

  /// Whether to show all 6 axes or just accelerometer (3).
  final bool showGyro;

  const SensorChart({
    super.key,
    required this.readings,
    this.maxPoints = 50,
    this.showGyro = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayCount = showGyro ? 6 : 3;

    // Build spots for each axis.
    final allSpots = <int, List<FlSpot>>{};
    for (int axis = 0; axis < displayCount; axis++) {
      allSpots[axis] = [];
    }

    final startIndex =
        readings.length > maxPoints ? readings.length - maxPoints : 0;
    for (int i = startIndex; i < readings.length; i++) {
      final x = (i - startIndex).toDouble();
      final r = readings[i];
      final values = r.toList();
      for (int axis = 0; axis < displayCount; axis++) {
        allSpots[axis]!.add(FlSpot(x, values[axis]));
      }
    }

    // Determine Y bounds from data.
    double minY = -2;
    double maxY = 2;
    for (final spots in allSpots.values) {
      for (final spot in spots) {
        if (spot.y < minY) minY = spot.y;
        if (spot.y > maxY) maxY = spot.y;
      }
    }
    // Add 10% padding.
    final range = maxY - minY;
    minY -= range * 0.1;
    maxY += range * 0.1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Legend
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Wrap(
            spacing: 12,
            children: List.generate(displayCount, (i) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 3,
                    decoration: BoxDecoration(
                      color: AppTheme.axisColors[i],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    AppTheme.axisLabels[i],
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppTheme.axisColors[i],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
        // Chart
        Expanded(
          child: LineChart(
            LineChartData(
              minY: minY,
              maxY: maxY,
              minX: 0,
              maxX: (maxPoints - 1).toDouble(),
              clipData: const FlClipData.all(),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: (maxY - minY) / 4,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                  strokeWidth: 0.5,
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toStringAsFixed(1),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 9,
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: List.generate(displayCount, (axis) {
                return LineChartBarData(
                  spots: allSpots[axis]!,
                  isCurved: true,
                  curveSmoothness: 0.2,
                  color: AppTheme.axisColors[axis],
                  barWidth: 1.5,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(show: false),
                );
              }),
              lineTouchData: const LineTouchData(enabled: false),
            ),
            duration: const Duration(milliseconds: 150),
            curve: Curves.linear,
          ),
        ),
      ],
    );
  }
}
