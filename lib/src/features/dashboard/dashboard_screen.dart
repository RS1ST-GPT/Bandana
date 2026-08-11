import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/di/service_locator.dart';
import '../../core/theme/app_theme.dart';
import '../../services/ble_service.dart';
import '../../services/database_service.dart';
import '../../services/ml_service.dart';
import '../../widgets/activity_card.dart';
import '../../widgets/ble_status_indicator.dart';

/// Dashboard screen – high-level summary of recorded activities and model status.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _db = getIt<DatabaseService>();
  final _ml = getIt<MlService>();
  final _ble = getIt<BleService>();

  Map<String, ({int sessionCount, int totalSamples})> _summaries = {};
  bool _isLoading = true;
  bool _isTraining = false;
  String? _trainingError;
  StreamSubscription<BleConnectionState>? _bleSub;
  BleConnectionState _bleState = BleConnectionState.disconnected;

  @override
  void initState() {
    super.initState();
    _loadData();
    _bleState = _ble.currentState;
    _bleSub = _ble.connectionState.listen((state) {
      if (mounted) setState(() => _bleState = state);
    });
  }

  @override
  void dispose() {
    _bleSub?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final summaries = await _db.getSessionSummaries();
    if (mounted) {
      setState(() {
        _summaries = summaries;
        _isLoading = false;
      });
    }
  }

  Future<void> _trainModel() async {
    setState(() {
      _isTraining = true;
      _trainingError = null;
    });

    try {
      final data = await _db.getAllWindowsForTraining();
      if (data.length < 2) {
        setState(() {
          _trainingError = 'Need at least 2 labeled windows to train.';
          _isTraining = false;
        });
        return;
      }

      final labels = data.map((d) => d.label).toSet();
      if (labels.length < 2) {
        setState(() {
          _trainingError = 'Need at least 2 different activity labels.';
          _isTraining = false;
        });
        return;
      }

      // Run training (computationally intensive for large datasets).
      final success = _ml.train(data);

      if (mounted) {
        setState(() {
          _isTraining = false;
          if (!success) {
            _trainingError = 'Training failed. Check your data.';
          }
        });
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Model trained! ${_ml.trainedClassCount} classes, '
                '${_ml.trainedSampleCount} samples.',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTraining = false;
          _trainingError = 'Error: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalSamples =
        _summaries.values.fold<int>(0, (sum, v) => sum + v.totalSamples);
    final totalSessions =
        _summaries.values.fold<int>(0, (sum, v) => sum + v.sessionCount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bandana'),
        actions: [
          BleStatusIndicator(state: _bleState),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                children: [
                  // ── Model Status Card ──
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.spacingMd),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _ml.isTrained
                                    ? Icons.check_circle
                                    : Icons.model_training,
                                color: _ml.isTrained
                                    ? Colors.green
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'ML Model',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildStatRow(
                            'Status',
                            _ml.isTrained ? 'Trained ✓' : 'Not trained',
                            theme,
                          ),
                          if (_ml.isTrained) ...[
                            _buildStatRow(
                              'Classes',
                              '${_ml.trainedClassCount}',
                              theme,
                            ),
                            _buildStatRow(
                              'Training Samples',
                              '${_ml.trainedSampleCount}',
                              theme,
                            ),
                          ],
                          _buildStatRow(
                            'Total Recordings',
                            '$totalSessions sessions',
                            theme,
                          ),
                          _buildStatRow(
                            'Total Windows',
                            '$totalSamples',
                            theme,
                          ),
                          if (_trainingError != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              _trainingError!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.error,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingMd),

                  // ── Section header ──
                  Text(
                    'Recorded Activities',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingSm),

                  // ── Activity Grid ──
                  if (_summaries.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppTheme.spacingLg),
                        child: Column(
                          children: [
                            Icon(
                              Icons.sensors_off,
                              size: 48,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No recordings yet',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Go to the Record tab to start collecting data.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 1.1,
                      ),
                      itemCount: _summaries.length,
                      itemBuilder: (context, index) {
                        final entry = _summaries.entries.elementAt(index);
                        return ActivityCard(
                          label: entry.key,
                          sessionCount: entry.value.sessionCount,
                          totalSamples: entry.value.totalSamples,
                        );
                      },
                    ),
                ],
              ),
      ),
      // ── Train FAB ──
      floatingActionButton: _isTraining
          ? FloatingActionButton.extended(
              onPressed: null,
              icon: const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              label: const Text('Training…'),
            )
          : FloatingActionButton.extended(
              onPressed: _trainModel,
              icon: const Icon(Icons.model_training),
              label: const Text('Train Model'),
            ),
    );
  }

  Widget _buildStatRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
