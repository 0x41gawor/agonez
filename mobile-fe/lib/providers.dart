import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'core/config.dart';
import 'data/api.dart';
import 'data/database.dart';
import 'data/sync_engine.dart';
import 'data/workout_repository.dart';
import 'domain/models.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase.open();
  ref.onDispose(db.close);
  return db;
});
final deviceIdProvider = FutureProvider<String>((ref) async {
  debugPrint('[bootstrap] loading device id');
  final db = ref.read(databaseProvider);
  final old = await db.setting('device_id');
  if (old != null) {
    debugPrint('[bootstrap] device id ready');
    return old;
  }
  final id = const Uuid().v4();
  await db.putSetting('device_id', id);
  debugPrint('[bootstrap] device id created');
  return id;
});
final apiProvider = FutureProvider<MobileApi>((ref) async {
  final deviceId = await ref.watch(deviceIdProvider.future);
  debugPrint('[bootstrap] API client ready');
  return MobileApi(
    AppConfig.fromEnvironment,
    deviceId: deviceId,
    locale: () => PlatformDispatcher.instance.locale.toLanguageTag(),
  );
});
final repositoryProvider = FutureProvider<WorkoutRepository>(
  (ref) async => WorkoutRepository(
    ref.read(databaseProvider),
    await ref.watch(apiProvider.future),
  ),
);
final syncProvider = FutureProvider<SyncEngine>(
  (ref) async => SyncEngine(
    ref.read(databaseProvider),
    await ref.watch(apiProvider.future),
  ),
);
final activeWorkoutProvider = StreamProvider<LocalWorkout?>(
  (ref) => ref.watch(databaseProvider).watchActiveWorkout(),
);
final workoutProvider = StreamProvider.family<LocalWorkout?, String>(
  (ref, id) => ref.watch(databaseProvider).watchWorkout(id),
);
final contextProvider = FutureProvider<MobileContext>((ref) async {
  debugPrint('[context] loading');
  try {
    final db = ref.read(databaseProvider);
    final selected = int.tryParse(await db.setting('plan_run_id') ?? '');
    final value = await (await ref.watch(
      apiProvider.future,
    )).context(planRunId: selected);
    debugPrint('[context] loaded ${value.contextVersion}');
    return value;
  } catch (error, stack) {
    debugPrint('[context] failed: $error\n$stack');
    rethrow;
  }
});
