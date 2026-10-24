import 'package:agonez/src/platform/system_theme_bridge.dart';
import 'package:agonez/src/settings/app_settings_controller.dart';
import 'package:agonez/src/storage/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('agonez/system_ui');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  test('mirrors the theme setting to Android now and on each change', () async {
    final calls = <String>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add('${call.method}:${call.arguments}');
      return null;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final settings = await AppSettingsController.load(database);
    addTearDown(settings.dispose);

    final unbind = const SystemThemeBridge().bind(settings);
    await pumpEventQueue();
    expect(calls, ['setNightMode:dark']);

    await settings.setThemeMode(ThemeMode.light);
    await settings.setHaptics(false);
    await pumpEventQueue();
    expect(calls, ['setNightMode:dark', 'setNightMode:light']);

    unbind();
    await settings.setThemeMode(ThemeMode.system);
    await pumpEventQueue();
    expect(calls, hasLength(2));
  });

  test('a missing native handler is harmless', () async {
    await const SystemThemeBridge().sync(ThemeMode.dark);
  });
}
