import 'package:flutter/material.dart';

import '../services/ble_service.dart';

/// A compact chip indicator showing BLE connection state.
///
/// Displays a colored dot and label. Taps invoke [onTap] (typically
/// to navigate to the Settings screen).
class BleStatusIndicator extends StatelessWidget {
  final BleConnectionState state;
  final VoidCallback? onTap;

  const BleStatusIndicator({
    super.key,
    required this.state,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (color, label, icon) = switch (state) {
      BleConnectionState.connected => (
          Colors.green,
          'Connected',
          Icons.bluetooth_connected,
        ),
      BleConnectionState.scanning => (
          Colors.blue,
          'Scanning',
          Icons.bluetooth_searching,
        ),
      BleConnectionState.connecting => (
          Colors.orange,
          'Connecting',
          Icons.bluetooth,
        ),
      BleConnectionState.disconnected => (
          Colors.red,
          'Disconnected',
          Icons.bluetooth_disabled,
        ),
    };

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated dot
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.5),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
