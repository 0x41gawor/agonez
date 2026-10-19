import 'package:agonez/src/settings/app_settings_controller.dart';
import 'package:agonez/src/storage/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('theme mode defaults to dark and persists each selection', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    final settings = await AppSettingsController.load(database);
    addTearDown(settings.dispose);
    expect(settings.themeMode, ThemeMode.dark);

    await settings.setThemeMode(ThemeMode.light);
    expect(settings.themeMode, ThemeMode.light);
    expect(await database.readSetting('theme_mode'), 'light');

    final restored = await AppSettingsController.load(database);
    addTearDown(restored.dispose);
    expect(restored.themeMode, ThemeMode.light);

    await restored.setThemeMode(ThemeMode.system);
    expect(await database.readSetting('theme_mode'), 'system');
  });
}
