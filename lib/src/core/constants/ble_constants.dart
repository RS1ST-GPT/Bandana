/// BLE and sensor constants for the Bandana HAR system.
class BleConstants {
  BleConstants._();

  /// The advertised name of the ESP32-C3 peripheral.
  static const String deviceName = 'BANDANA_HAR';

  /// Default GATT Service UUID exposed by the ESP32 firmware.
  /// Update this to match your actual firmware configuration.
  static const String serviceUuid = '0000ffe0-0000-1000-8000-00805f9b34fb';

  /// Default GATT Characteristic UUID (notify) for IMU data.
  static const String characteristicUuid = '0000ffe1-0000-1000-8000-00805f9b34fb';

  /// IMU sample rate in Hz.
  static const int sampleRateHz = 10;

  /// Number of samples in one sliding window (2 seconds at 10 Hz).
  static const int windowSize = 20;

  /// Number of axes in the IMU data stream (ax, ay, az, gx, gy, gz).
  static const int axisCount = 6;

  /// Number of statistical features per axis (mean, std, variance, min, max).
  static const int featuresPerAxis = 5;

  /// Total feature vector length: axisCount × featuresPerAxis.
  static const int featureVectorLength = axisCount * featuresPerAxis;

  /// Scan timeout duration.
  static const Duration scanTimeout = Duration(seconds: 15);

  /// Default activity labels available for recording.
  static const List<String> defaultLabels = [
    'Walking',
    'Running',
    'Sitting',
    'Standing',
    'Climbing Stairs',
    'Descending Stairs',
  ];
}
