import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/ble_constants.dart';
import '../../core/di/service_locator.dart';
import '../../core/theme/app_theme.dart';
import '../../models/sensor_data.dart';
import '../../services/ble_service.dart';
import '../../services/database_service.dart';
import '../../services/ml_service.dart';
import '../../widgets/ble_status_indicator.dart';
import '../../widgets/sensor_chart.dart';

/// Record Mode screen – tag and record IMU data streams with activity labels.
class RecordScreen extends StatefulWidget {
  const RecordScreen({super.key});

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen>
    with SingleTickerProviderStateMixin {
  final _ble = getIt<BleService>();
  final _db = getIt<DatabaseService>();

  // ── Recording state ──
  String _selectedLabel = BleConstants.defaultLabels.first;
  bool _isRecording = false;
  int? _sessionId;
  int _sampleCount = 0;

  // ── Sensor buffer ──
  final List<SensorReading> _chartBuffer = [];
  List<SensorReading> _windowBuffer = [];
  StreamSubscription<SensorReading>? _sensorSub;
  StreamSubscription<BleConnectionState>? _bleSub;
  BleConnectionState _bleState = BleConnectionState.disconnected;

  // ── Animation ──
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _bleState = _ble.currentState;
    _bleSub = _ble.connectionState.listen((state) {
      if (mounted) setState(() => _bleState = state);
    });
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  @override
  void dispose() {
    _stopRecording(showSnackbar: false);
    _sensorSub?.cancel();
    _bleSub?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startRecording() async {
    if (_bleState != BleConnectionState.connected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connect to BANDANA_HAR first (Settings tab).'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Create a new session in the DB.
    final sessionId = await _db.createSession(_selectedLabel);

    setState(() {
      _isRecording = true;
      _sessionId = sessionId;
      _sampleCount = 0;
      _windowBuffer = [];
      _chartBuffer.clear();
    });

    _pulseController.repeat(reverse: true);

    // Subscribe to sensor stream.
    _sensorSub = _ble.sensorStream.listen(_onSensorData);
  }

  void _onSensorData(SensorReading reading) {
    if (!_isRecording) return;

    setState(() {
      // Add to chart display buffer (rolling).
      _chartBuffer.add(reading);
      if (_chartBuffer.length > 50) {
        _chartBuffer.removeAt(0);
      }
    });

    // Add to window buffer for feature extraction.
    _windowBuffer.add(reading);

    // When we have a full window, extract features and save.
    if (_windowBuffer.length >= BleConstants.windowSize) {
      _processWindow();
    }
  }

  Future<void> _processWindow() async {
    if (_sessionId == null) return;

    final window = List<SensorReading>.from(_windowBuffer);
    _windowBuffer.clear();

    final features = MlService.extractFeatures(window);

    await _db.insertWindow(
      sessionId: _sessionId!,
      featureVector: features,
      label: _selectedLabel,
    );

    if (mounted) {
      setState(() => _sampleCount++);
    }
  }

  Future<void> _stopRecording({bool showSnackbar = true}) async {
    _sensorSub?.cancel();
    _sensorSub = null;
    _pulseController.stop();
    _pulseController.reset();

    if (_sessionId != null) {
      await _db.endSession(_sessionId!, _sampleCount);
    }

    if (showSnackbar && mounted && _sessionId != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Session saved: $_selectedLabel – $_sampleCount windows.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    if (mounted) {
      setState(() {
        _isRecording = false;
        _sessionId = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Record'),
        actions: [
          BleStatusIndicator(state: _bleState),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          children: [
            // ── Label Selector ──
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingMd,
                  vertical: AppTheme.spacingSm,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.label_outline,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedLabel,
                          isExpanded: true,
                          onChanged: _isRecording
                              ? null
                              : (value) {
                                  if (value != null) {
                                    setState(() => _selectedLabel = value);
                                  }
                                },
                          items: BleConstants.defaultLabels.map((label) {
                            return DropdownMenuItem(
                              value: label,
                              child: Text(label),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingMd),

            // ── Stats Bar ──
            if (_isRecording)
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingMd,
                      vertical: AppTheme.spacingSm,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer.withValues(
                        alpha: 0.3 + _pulseController.value * 0.3,
                      ),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.fiber_manual_record,
                          color: theme.colorScheme.error,
                          size: 14,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Recording: $_selectedLabel',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '$_sampleCount windows',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

            const SizedBox(height: AppTheme.spacingMd),

            // ── Real-time Chart ──
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
                  child: _chartBuffer.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.show_chart,
                                size: 48,
                                color: theme.colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _isRecording
                                    ? 'Waiting for data…'
                                    : 'Start recording to see chart',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        )
                      : SensorChart(
                          readings: _chartBuffer,
                          maxPoints: 50,
                        ),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingMd),

            // ── Start / Stop Button ──
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.icon(
                onPressed: _isRecording ? _stopRecording : _startRecording,
                icon: Icon(_isRecording ? Icons.stop : Icons.fiber_manual_record),
                label: Text(
                  _isRecording ? 'Stop Recording' : 'Start Recording',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: _isRecording
                      ? theme.colorScheme.error
                      : theme.colorScheme.primary,
                  foregroundColor: _isRecording
                      ? theme.colorScheme.onError
                      : theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
