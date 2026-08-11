/// Metadata for a recorded activity session.
class ActivitySession {
  final int? id;
  final String label;
  final DateTime startTime;
  final DateTime? endTime;
  final int sampleCount;

  const ActivitySession({
    this.id,
    required this.label,
    required this.startTime,
    this.endTime,
    this.sampleCount = 0,
  });

  /// Duration of the session (returns zero if still ongoing).
  Duration get duration => (endTime ?? DateTime.now()).difference(startTime);

  /// Human-readable duration string.
  String get durationString {
    final d = duration;
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '${minutes}m ${seconds}s';
  }

  ActivitySession copyWith({
    int? id,
    String? label,
    DateTime? startTime,
    DateTime? endTime,
    int? sampleCount,
  }) {
    return ActivitySession(
      id: id ?? this.id,
      label: label ?? this.label,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      sampleCount: sampleCount ?? this.sampleCount,
    );
  }

  @override
  String toString() =>
      'ActivitySession(id: $id, label: $label, samples: $sampleCount, '
      'duration: $durationString)';
}
