import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

part 'database_service.g.dart';

// ── Table Definitions ──

/// Recording sessions table.
class Sessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get label => text()();
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime().nullable()();
  IntColumn get sampleCount => integer().withDefault(const Constant(0))();
}

/// Feature windows extracted from sensor data during recording.
class SensorWindows extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sessionId => integer().references(Sessions, #id)();
  TextColumn get features => text()(); // JSON-encoded list of doubles
  TextColumn get label => text()();
  DateTimeColumn get timestamp => dateTime()();
}

// ── Database ──

@DriftDatabase(tables: [Sessions, SensorWindows])
class DatabaseService extends _$DatabaseService {
  DatabaseService() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // ── Sessions ──

  /// Create a new recording session and return its ID.
  Future<int> createSession(String label) async {
    final id = await into(sessions).insert(
      SessionsCompanion.insert(
        label: label,
        startTime: DateTime.now(),
      ),
    );
    return id;
  }

  /// End a session by setting its endTime and final sample count.
  Future<void> endSession(int sessionId, int sampleCount) async {
    await (update(sessions)..where((s) => s.id.equals(sessionId))).write(
      SessionsCompanion(
        endTime: Value(DateTime.now()),
        sampleCount: Value(sampleCount),
      ),
    );
  }

  /// Get all sessions, most recent first.
  Future<List<Session>> getAllSessions() async {
    return (select(sessions)
          ..orderBy([(s) => OrderingTerm.desc(s.startTime)]))
        .get();
  }

  /// Get session summaries grouped by label.
  Future<Map<String, ({int sessionCount, int totalSamples})>>
      getSessionSummaries() async {
    final allSessions = await getAllSessions();
    final map = <String, ({int sessionCount, int totalSamples})>{};
    for (final session in allSessions) {
      final existing = map[session.label];
      map[session.label] = (
        sessionCount: (existing?.sessionCount ?? 0) + 1,
        totalSamples: (existing?.totalSamples ?? 0) + session.sampleCount,
      );
    }
    return map;
  }

  /// Delete a session and its associated windows.
  Future<void> deleteSession(int sessionId) async {
    await (delete(sensorWindows)
          ..where((w) => w.sessionId.equals(sessionId)))
        .go();
    await (delete(sessions)..where((s) => s.id.equals(sessionId))).go();
  }

  // ── Sensor Windows ──

  /// Insert a feature window for a session.
  Future<void> insertWindow({
    required int sessionId,
    required List<double> featureVector,
    required String label,
  }) async {
    await into(sensorWindows).insert(
      SensorWindowsCompanion.insert(
        sessionId: sessionId,
        features: jsonEncode(featureVector),
        label: label,
        timestamp: DateTime.now(),
      ),
    );
  }

  /// Load all feature windows for ML training.
  /// Returns a list of (featureVector, label) pairs.
  Future<List<({List<double> features, String label})>>
      getAllWindowsForTraining() async {
    final rows = await select(sensorWindows).get();
    return rows.map((row) {
      final featureList =
          (jsonDecode(row.features) as List).cast<num>().map((n) => n.toDouble()).toList();
      return (features: featureList, label: row.label);
    }).toList();
  }

  /// Total number of stored windows across all sessions.
  Future<int> get totalWindowCount async {
    final count = countAll();
    final query = selectOnly(sensorWindows)..addColumns([count]);
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  /// Number of distinct labels that have training data.
  Future<int> get distinctLabelCount async {
    final rows = await (selectOnly(sensorWindows, distinct: true)
          ..addColumns([sensorWindows.label]))
        .get();
    return rows.length;
  }

  // ── Danger zone ──

  /// Delete all sessions and windows.
  Future<void> clearAll() async {
    await delete(sensorWindows).go();
    await delete(sessions).go();
  }
}

// ── Connection helper ──

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'bandana.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
