/// A single IMU sensor reading from the ESP32-C3.
class SensorReading {
  /// Accelerometer X-axis (m/s²).
  final double ax;

  /// Accelerometer Y-axis (m/s²).
  final double ay;

  /// Accelerometer Z-axis (m/s²).
  final double az;

  /// Gyroscope X-axis (°/s).
  final double gx;

  /// Gyroscope Y-axis (°/s).
  final double gy;

  /// Gyroscope Z-axis (°/s).
  final double gz;

  /// Timestamp when this reading was received.
  final DateTime timestamp;

  const SensorReading({
    required this.ax,
    required this.ay,
    required this.az,
    required this.gx,
    required this.gy,
    required this.gz,
    required this.timestamp,
  });

  /// Parse a comma-separated UTF-8 string from the ESP32: "ax,ay,az,gx,gy,gz".
  factory SensorReading.fromCsv(String csv) {
    final parts = csv.split(',');
    if (parts.length < 6) {
      throw FormatException('Expected 6 comma-separated values, got ${parts.length}: "$csv"');
    }
    return SensorReading(
      ax: double.parse(parts[0].trim()),
      ay: double.parse(parts[1].trim()),
      az: double.parse(parts[2].trim()),
      gx: double.parse(parts[3].trim()),
      gy: double.parse(parts[4].trim()),
      gz: double.parse(parts[5].trim()),
      timestamp: DateTime.now(),
    );
  }

  /// Return the 6-axis values as a flat list.
  List<double> toList() => [ax, ay, az, gx, gy, gz];

  @override
  String toString() =>
      'SensorReading(ax: ${ax.toStringAsFixed(2)}, ay: ${ay.toStringAsFixed(2)}, '
      'az: ${az.toStringAsFixed(2)}, gx: ${gx.toStringAsFixed(2)}, '
      'gy: ${gy.toStringAsFixed(2)}, gz: ${gz.toStringAsFixed(2)})';
}
