import 'package:get_it/get_it.dart';

import '../../services/ble_service.dart';
import '../../services/database_service.dart';
import '../../services/ml_service.dart';

/// Global service locator instance.
final getIt = GetIt.instance;

/// Register all singleton services.
/// Must be called before [runApp].
Future<void> setupServiceLocator() async {
  // Database – initialise first since other services may depend on it.
  final db = DatabaseService();
  getIt.registerSingleton<DatabaseService>(db);

  // BLE
  getIt.registerLazySingleton<BleService>(() => BleService());

  // ML
  getIt.registerLazySingleton<MlService>(() => MlService());
}
