import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../core/constants/ble_constants.dart';
import '../models/sensor_data.dart';

/// Connection state exposed to the UI.
enum BleConnectionState {
  disconnected,
  scanning,
  connecting,
  connected,
}

/// Singleton BLE service that manages scanning, connection, and data streaming
/// from the BANDANA_HAR ESP32-C3 device.
class BleService {
  // ── Internal state ──
  BluetoothDevice? _device;
  // ignore: unused_field
  BluetoothCharacteristic? _dataCharacteristic;
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  StreamSubscription<List<int>>? _notifySubscription;

  // ── Public streams ──
  final _sensorController = StreamController<SensorReading>.broadcast();
  final _stateController = StreamController<BleConnectionState>.broadcast();

  /// Stream of parsed IMU sensor readings from the ESP32.
  Stream<SensorReading> get sensorStream => _sensorController.stream;

  /// Stream of high-level connection state changes.
  Stream<BleConnectionState> get connectionState => _stateController.stream;

  BleConnectionState _currentState = BleConnectionState.disconnected;

  /// The current connection state (synchronous access).
  BleConnectionState get currentState => _currentState;

  /// The connected device's platform name, if any.
  String? get deviceName => _device?.platformName;

  /// The connected device's RSSI (null if not connected).
  Future<int?> get rssi async {
    if (_currentState != BleConnectionState.connected || _device == null) {
      return null;
    }
    try {
      return await _device!.readRssi();
    } catch (_) {
      return null;
    }
  }

  // ── Scanning ──

  /// Start scanning for the BANDANA_HAR device and auto-connect.
  Future<void> startScan() async {
    if (_currentState == BleConnectionState.scanning ||
        _currentState == BleConnectionState.connected) {
      return;
    }

    _updateState(BleConnectionState.scanning);

    await _scanSubscription?.cancel();
    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      for (final r in results) {
        if (r.device.platformName == BleConstants.deviceName) {
          FlutterBluePlus.stopScan();
          _connectToDevice(r.device);
          return;
        }
      }
    });

    await FlutterBluePlus.startScan(timeout: BleConstants.scanTimeout);

    // If scan finishes without finding the device:
    if (_currentState == BleConnectionState.scanning) {
      _updateState(BleConnectionState.disconnected);
    }
  }

  /// Stop an ongoing scan.
  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    if (_currentState == BleConnectionState.scanning) {
      _updateState(BleConnectionState.disconnected);
    }
  }

  // ── Connection ──

  Future<void> _connectToDevice(BluetoothDevice device) async {
    _device = device;
    _updateState(BleConnectionState.connecting);

    try {
      // license: nonprofit covers personal/educational/small-team use.
      // mtu: 512 is requested automatically on Android.
      await device.connect(
        license: License.nonprofit,
        autoConnect: false,
        mtu: 512,
      );

      // Listen for disconnection events.
      _connectionSubscription = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _handleDisconnect();
        }
      });

      await _discoverAndSubscribe(device);
      _updateState(BleConnectionState.connected);
    } catch (e) {
      _handleDisconnect();
    }
  }

  Future<void> _discoverAndSubscribe(BluetoothDevice device) async {
    final services = await device.discoverServices();

    for (final service in services) {
      if (service.uuid.toString().toLowerCase() ==
          BleConstants.serviceUuid.toLowerCase()) {
        for (final char in service.characteristics) {
          if (char.uuid.toString().toLowerCase() ==
              BleConstants.characteristicUuid.toLowerCase()) {
            _dataCharacteristic = char;

            // Enable notifications.
            await char.setNotifyValue(true);

            // Subscribe to incoming data.
            _notifySubscription = char.lastValueStream.listen(_onDataReceived);
            // Auto-cancel on disconnect.
            device.cancelWhenDisconnected(_notifySubscription!);
            return;
          }
        }
      }
    }

    // Fallback: if specific UUIDs not found, subscribe to the first notify
    // characteristic available.
    for (final service in services) {
      for (final char in service.characteristics) {
        if (char.properties.notify) {
          _dataCharacteristic = char;
          await char.setNotifyValue(true);
          _notifySubscription = char.lastValueStream.listen(_onDataReceived);
          device.cancelWhenDisconnected(_notifySubscription!);
          return;
        }
      }
    }
  }

  void _onDataReceived(List<int> value) {
    if (value.isEmpty) return;
    try {
      final csv = utf8.decode(value).trim();
      if (csv.isEmpty) return;

      // Handle the case where multiple readings arrive in one packet.
      final lines = csv.split('\n');
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isNotEmpty) {
          final reading = SensorReading.fromCsv(trimmed);
          _sensorController.add(reading);
        }
      }
    } catch (_) {
      // Silently skip malformed data packets.
    }
  }

  // ── Disconnect ──

  /// Manually disconnect from the current device.
  Future<void> disconnect() async {
    try {
      await _notifySubscription?.cancel();
      await _device?.disconnect();
    } catch (_) {
      // Best-effort cleanup.
    }
    _handleDisconnect();
  }

  void _handleDisconnect() {
    _device = null;
    _dataCharacteristic = null;
    _notifySubscription = null;
    _connectionSubscription?.cancel();
    _connectionSubscription = null;
    _updateState(BleConnectionState.disconnected);
  }

  void _updateState(BleConnectionState state) {
    _currentState = state;
    _stateController.add(state);
  }

  // ── Cleanup ──

  /// Release all resources. Call when the app is closing.
  Future<void> dispose() async {
    await disconnect();
    await _scanSubscription?.cancel();
    await _sensorController.close();
    await _stateController.close();
  }
}
