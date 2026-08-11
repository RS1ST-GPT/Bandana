/// Result of an ML prediction on a sensor data window.
class PredictionResult {
  /// The predicted activity label (e.g., "Walking").
  final String label;

  /// Confidence score between 0.0 and 1.0.
  final double confidence;

  /// Timestamp of prediction.
  final DateTime timestamp;

  PredictionResult({
    required this.label,
    required this.confidence,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Confidence as an integer percentage (0–100).
  int get confidencePercent => (confidence * 100).round();

  @override
  String toString() =>
      'PredictionResult(label: $label, confidence: $confidencePercent%)';
}
