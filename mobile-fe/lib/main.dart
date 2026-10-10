import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/app/app.dart';
import 'src/app/app_providers.dart';
import 'src/app/app_router.dart';
import 'src/app/app_runtime.dart';
import 'src/config/app_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final runtime = await AppRuntime.create(AppConfig.fromEnvironment());
    final router = createAppRouter();
    await runtime.notifications.initialize(
      onOpenWorkout: () => router.go('/focus'),
    );
    if (runtime.settings.restNotificationsEnabled) {
      await runtime.notifications.requestPermission();
    }
    runApp(
      ProviderScope(
        overrides: [appRuntimeProvider.overrideWithValue(runtime)],
        child: AgonezApp(runtime: runtime, router: router),
      ),
    );
  } on Object catch (error, stackTrace) {
    debugPrint('Agonez startup failed: $error\n$stackTrace');
    developer.log(
      'Agonez startup failed',
      name: 'agonez.startup',
      error: error,
      stackTrace: stackTrace,
    );
    runApp(AppStartupError(message: error.toString()));
  }
}
