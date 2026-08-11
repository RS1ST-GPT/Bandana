import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/ble_constants.dart';
import '../../core/di/service_locator.dart';
import '../../core/theme/app_theme.dart';
import '../../models/prediction_result.dart';
import '../../models/sensor_data.dart';
import '../../services/ble_service.dart';
import '../../services/ml_service.dart';
import '../../widgets/activity_card.dart';
import '../../widgets/ble_status_indicator.dart';
import '../../widgets/confidence_gauge.dart';

/// Live Mode screen – real-time activity classification.
class LiveScreen extends StatefulWidget {
  const LiveScreen({super.key});

  @override
  State<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends State<LiveScreen> {
  final _ble = getIt<BleService>();
  final _ml = getIt<MlService>();

  // ── State ──
  bool _isRunning = false;
  PredictionResult? _currentPrediction;
  final List<PredictionResult> _history = [];
  final List<SensorReading> _windowBuffer = [];

  StreamSubscription<SensorReading>? _sensorSub;
  StreamSubscription<BleConnectionState>? _bleSub;
  BleConnectionState _bleState = BleConnectionState.disconnected;

  @override
  void initState() {
    super.initState();
    _bleState = _ble.currentState;
    _bleSub = _ble.connectionState.listen((state) {
      if (mounted) setState(() => _bleState = state);
    });
  }

  @override
  void dispose() {
    _stop();
    _bleSub?.cancel();
    super.dispose();
  }

  void _start() {
    if (!_ml.isTrained) return;
    if (_bleState != BleConnectionState.connected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connect to BANDANA_HAR first (Settings tab).'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isRunning = true);
    _sensorSub = _ble.sensorStream.listen(_onSensorData);
  }

  void _stop() {
    _sensorSub?.cancel();
    _sensorSub = null;
    _windowBuffer.clear();
    if (mounted) setState(() => _isRunning = false);
  }

  void _onSensorData(SensorReading reading) {
    _windowBuffer.add(reading);

    if (_windowBuffer.length >= BleConstants.windowSize) {
      final window = List<SensorReading>.from(_windowBuffer);
      _windowBuffer.clear();

      final result = _ml.predictFromWindow(window);
      if (result != null && mounted) {
        setState(() {
          _currentPrediction = result;
          _history.insert(0, result);
          if (_history.length > 20) _history.removeLast();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live'),
        actions: [
          BleStatusIndicator(state: _bleState),
          const SizedBox(width: 8),
        ],
      ),
      body: !_ml.isTrained
          ? _buildNotTrainedView(theme)
          : Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              child: Column(
                children: [
                  // ── Main prediction display ──
                  Expanded(
                    flex: 3,
                    child: Card(
                      child: Center(
                        child: _currentPrediction == null
                            ? _buildWaitingView(theme)
                            : _buildPredictionView(theme),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingMd),

                  // ── Start / Stop ──
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton.icon(
                      onPressed: _isRunning ? _stop : _start,
                      icon: Icon(
                        _isRunning
                            ? Icons.stop
                            : Icons.play_arrow,
                      ),
                      label: Text(
                        _isRunning ? 'Stop Inference' : 'Start Inference',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: _isRunning
                            ? theme.colorScheme.error
                            : theme.colorScheme.primary,
                        foregroundColor: _isRunning
                            ? theme.colorScheme.onError
                            : theme.colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMd),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingMd),

                  // ── Prediction History ──
                  if (_history.isNotEmpty) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Recent Predictions',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    Expanded(
                      flex: 2,
                      child: ListView.builder(
                        itemCount: _history.length,
                        itemBuilder: (context, index) {
                          final pred = _history[index];
                          final timeStr =
                              '${pred.timestamp.hour.toString().padLeft(2, '0')}:'
                              '${pred.timestamp.minute.toString().padLeft(2, '0')}:'
                              '${pred.timestamp.second.toString().padLeft(2, '0')}';
                          return ListTile(
                            dense: true,
                            leading: Icon(
                              ActivityCard.iconForLabel(pred.label),
                              color: ActivityCard.colorsForLabel(
                                  pred.label)[0],
                            ),
                            title: Text(pred.label),
                            trailing: Text(
                              timeStr,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildNotTrainedView(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.model_training,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Model Not Trained',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Record some activities in the Record tab, then train '
              'the model from the Dashboard before using Live mode.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaitingView(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ConfidenceGauge(
          confidence: 0,
          child: Icon(
            Icons.sensors,
            size: 32,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _isRunning ? 'Waiting for data…' : 'Press Start to begin',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildPredictionView(ThemeData theme) {
    final pred = _currentPrediction!;
    final colors = ActivityCard.colorsForLabel(pred.label);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ConfidenceGauge(
          confidence: pred.confidence,
          size: 180,
          child: Icon(
            ActivityCard.iconForLabel(pred.label),
            size: 36,
            color: colors[0],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          pred.label,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: colors[0],
          ),
        ),
      ],
    );
  }
}
