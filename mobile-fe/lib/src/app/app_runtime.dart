import 'dart:async';

import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../api/agonez_api_client.dart';
import '../config/app_config.dart';
import '../data/mobile_repository.dart';
import '../platform/rest_notification_service.dart';
import '../platform/system_theme_bridge.dart';
import '../settings/app_settings_controller.dart';
import '../storage/app_database.dart';
import '../sync/workout_sync_engine.dart';
import '../workout/workout_repository.dart';
import '../workout/workout_recovery_repository.dart';

class AppRuntime {
  AppRuntime._({
    required this.database,
    required this.settings,
    required this.api,
    required this.mobileRepository,
    required this.syncEngine,
    required this.workoutRepository,
    required this.workoutRecoveryRepository,
    required this.notifications,
    required this.deviceId,
    required this.contextRefreshes,
  });

  static Future<AppRuntime> create(AppConfig config) async {
    final database = AppDatabase();
    final settings = await AppSettingsController.load(database);
    // Keeps the next system splash in the app's theme; the listener ends
    // with settings.dispose().
    const SystemThemeBridge().bind(settings);
    final deviceId = await database.installationId();
    final packageInfo = await PackageInfo.fromPlatform();
    final clientInfo =
        'agonez-mobile/${packageInfo.version} (android; ${packageInfo.buildNumber})';
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 8),
        sendTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        responseType: ResponseType.json,
        headers: const <String, Object?>{'Accept': 'application/json'},
      ),
    );
    final api = AgonezApiClient(
      dio: dio,
      baseUrl: config.apiBaseUrl,
      deviceId: () => deviceId,
      clientInfo: () => clientInfo,
      locale: () => settings.locale.languageCode,
    );
    final contextRefreshes = StreamController<int>.broadcast();
    late final AppRuntime runtime;
    final syncEngine = WorkoutSyncEngine(
      database: database,
      api: api,
      onWorkoutFinalized: () => runtime.refreshContext(),
    );
    final workoutRepository = WorkoutRepository(
      database: database,
      requestSync: syncEngine.kick,
    );
    final workoutRecoveryRepository = WorkoutRecoveryRepository(
      database: database,
      api: api,
      deviceId: deviceId,
    );
    return runtime = AppRuntime._(
      database: database,
      settings: settings,
      api: api,
      mobileRepository: MobileRepository(database: database, api: api),
      syncEngine: syncEngine,
      workoutRepository: workoutRepository,
      workoutRecoveryRepository: workoutRecoveryRepository,
      notifications: RestNotificationService(),
      deviceId: deviceId,
      contextRefreshes: contextRefreshes,
    );
  }

  final AppDatabase database;
  final AppSettingsController settings;
  final AgonezApiClient api;
  final MobileRepository mobileRepository;
  final WorkoutSyncEngine syncEngine;
  final WorkoutRepository workoutRepository;
  final WorkoutRecoveryRepository workoutRecoveryRepository;
  final RestNotificationService notifications;
  final String deviceId;
  final StreamController<int> contextRefreshes;
  var _refreshRevision = 0;

  /// Asks every screen built on today's context to reload it.
  void refreshContext() {
    if (!contextRefreshes.isClosed) contextRefreshes.add(++_refreshRevision);
  }

  Future<void> dispose() async {
    await syncEngine.dispose();
    await notifications.cancel();
    await contextRefreshes.close();
    settings.dispose();
    await database.close();
  }
}
