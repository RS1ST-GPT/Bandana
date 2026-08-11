import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/di/service_locator.dart';
import '../../core/theme/app_theme.dart';
import '../../services/ble_service.dart';
import '../../services/database_service.dart';
import '../../services/ml_service.dart';

/// Settings screen – device info, BLE controls, data management.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _ble = getIt<BleService>();
  final _db = getIt<DatabaseService>();
  final _ml = getIt<MlService>();

  StreamSubscription<BleConnectionState>? _bleSub;
  BleConnectionState _bleState = BleConnectionState.disconnected;
  int? _rssi;
  bool _isClearing = false;

  @override
  void initState() {
    super.initState();
    _bleState = _ble.currentState;
    _bleSub = _ble.connectionState.listen((state) {
      if (mounted) {
        setState(() => _bleState = state);
        if (state == BleConnectionState.connected) {
          _refreshRssi();
        }
      }
    });
    if (_bleState == BleConnectionState.connected) {
      _refreshRssi();
    }
  }

  @override
  void dispose() {
    _bleSub?.cancel();
    super.dispose();
  }

  Future<void> _refreshRssi() async {
    final rssi = await _ble.rssi;
    if (mounted) setState(() => _rssi = rssi);
  }

  Future<void> _toggleConnection() async {
    if (_bleState == BleConnectionState.connected) {
      await _ble.disconnect();
    } else if (_bleState == BleConnectionState.disconnected) {
      await _ble.startScan();
    }
  }

  Future<void> _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This will delete all recorded sessions, training data, '
          'and reset the ML model. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isClearing = true);
    await _db.clearAll();
    _ml.reset();
    setState(() => _isClearing = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All data cleared.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final stateLabel = switch (_bleState) {
      BleConnectionState.connected => 'Connected',
      BleConnectionState.scanning => 'Scanning…',
      BleConnectionState.connecting => 'Connecting…',
      BleConnectionState.disconnected => 'Disconnected',
    };

    final stateColor = switch (_bleState) {
      BleConnectionState.connected => Colors.green,
      BleConnectionState.scanning => Colors.blue,
      BleConnectionState.connecting => Colors.orange,
      BleConnectionState.disconnected => Colors.red,
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        children: [
          // ── Device Section ──
          Text(
            'BLE Device',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              child: Column(
                children: [
                  _buildSettingsRow(
                    theme,
                    icon: Icons.bluetooth,
                    label: 'Device Name',
                    value: _ble.deviceName ?? 'BANDANA_HAR',
                  ),
                  const Divider(height: 24),
                  _buildSettingsRow(
                    theme,
                    icon: Icons.signal_cellular_alt,
                    label: 'Status',
                    valueWidget: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: stateColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(stateLabel, style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                  if (_rssi != null && _bleState == BleConnectionState.connected) ...[
                    const Divider(height: 24),
                    _buildSettingsRow(
                      theme,
                      icon: Icons.signal_wifi_4_bar,
                      label: 'RSSI',
                      value: '$_rssi dBm',
                    ),
                  ],
                  const Divider(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: _bleState == BleConnectionState.scanning ||
                            _bleState == BleConnectionState.connecting
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(8),
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          )
                        : OutlinedButton.icon(
                            onPressed: _toggleConnection,
                            icon: Icon(
                              _bleState == BleConnectionState.connected
                                  ? Icons.bluetooth_disabled
                                  : Icons.bluetooth_searching,
                            ),
                            label: Text(
                              _bleState == BleConnectionState.connected
                                  ? 'Disconnect'
                                  : 'Scan & Connect',
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),

          // ── Data Section ──
          Text(
            'Data Management',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              child: Column(
                children: [
                  _buildSettingsRow(
                    theme,
                    icon: Icons.model_training,
                    label: 'ML Model',
                    value: _ml.isTrained
                        ? 'Trained (${_ml.trainedClassCount} classes)'
                        : 'Not trained',
                  ),
                  const Divider(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: _isClearing
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(8),
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          )
                        : OutlinedButton.icon(
                            onPressed: _clearAllData,
                            icon: const Icon(Icons.delete_forever),
                            label: const Text('Clear All Data'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: theme.colorScheme.error,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),

          // ── About Section ──
          Text(
            'About',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              child: Column(
                children: [
                  _buildSettingsRow(
                    theme,
                    icon: Icons.info_outline,
                    label: 'App Version',
                    value: '1.0.0',
                  ),
                  const Divider(height: 24),
                  _buildSettingsRow(
                    theme,
                    icon: Icons.memory,
                    label: 'ML Engine',
                    value: 'KNN (ml_algo)',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsRow(
    ThemeData theme, {
    required IconData icon,
    required String label,
    String? value,
    Widget? valueWidget,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: theme.textTheme.bodyMedium),
        ),
        valueWidget ??
            Text(
              value ?? '',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
      ],
    );
  }
}
