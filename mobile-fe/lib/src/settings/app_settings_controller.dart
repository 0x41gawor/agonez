import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../storage/app_database.dart';

class AppSettingsController extends ChangeNotifier {
  AppSettingsController._({
    required AppDatabase database,
    required Locale locale,
    required ThemeMode themeMode,
    required this.hapticsEnabled,
    required this.restNotificationsEnabled,
    required this.restSoundEnabled,
    required this.compoundRestSeconds,
    required this.accessoryRestSeconds,
    required this.setNumberingStart,
  }) : _database = database,
       _locale = locale,
       _themeMode = themeMode;

  static Future<AppSettingsController> load(AppDatabase database) async {
    final storedLocale = await database.readSetting('locale');
    final systemLanguage = PlatformDispatcher.instance.locale.languageCode;
    final language = storedLocale == 'pl' || storedLocale == 'en'
        ? storedLocale!
        : (systemLanguage == 'pl' ? 'pl' : 'en');
    final themeMode = switch (await database.readSetting('theme_mode')) {
      'system' => ThemeMode.system,
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.dark,
    };
    return AppSettingsController._(
      database: database,
      locale: Locale(language),
      themeMode: themeMode,
      hapticsEnabled: await database.readSetting('haptics_enabled') != 'false',
      restNotificationsEnabled:
          await database.readSetting('rest_notifications_enabled') != 'false',
      restSoundEnabled:
          await database.readSetting('rest_sound_enabled') == 'true',
      compoundRestSeconds:
          int.tryParse(
            await database.readSetting('compound_rest_seconds') ?? '',
          ) ??
          180,
      accessoryRestSeconds:
          int.tryParse(
            await database.readSetting('accessory_rest_seconds') ?? '',
          ) ??
          90,
      setNumberingStart:
          await database.readSetting('set_numbering_start') == '0' ? 0 : 1,
    );
  }

  final AppDatabase _database;
  Locale _locale;
  ThemeMode _themeMode;

  Locale get locale => _locale;
  ThemeMode get themeMode => _themeMode;
  bool hapticsEnabled;
  bool restNotificationsEnabled;
  bool restSoundEnabled;
  int compoundRestSeconds;
  int accessoryRestSeconds;

  /// The number the first set of an exercise is shown with: 1 by default,
  /// or 0 for athletes who count from zero. Display only; stored and synced
  /// set ordinals never change.
  int setNumberingStart;

  Future<void> setLocale(Locale value) async {
    if (value.languageCode != 'en' && value.languageCode != 'pl') return;
    if (_locale == value) return;
    _locale = value;
    notifyListeners();
    await _database.writeSetting('locale', value.languageCode);
  }

  Future<void> setThemeMode(ThemeMode value) async {
    if (_themeMode == value) return;
    _themeMode = value;
    notifyListeners();
    await _database.writeSetting('theme_mode', value.name);
  }

  Future<void> setHaptics(bool value) async {
    hapticsEnabled = value;
    notifyListeners();
    await _database.writeSetting('haptics_enabled', value.toString());
  }

  Future<void> setRestNotifications(bool value) async {
    restNotificationsEnabled = value;
    notifyListeners();
    await _database.writeSetting(
      'rest_notifications_enabled',
      value.toString(),
    );
  }

  Future<void> setRestSound(bool value) async {
    restSoundEnabled = value;
    notifyListeners();
    await _database.writeSetting('rest_sound_enabled', value.toString());
  }

  Future<void> setCompoundRestSeconds(int value) async {
    compoundRestSeconds = value.clamp(30, 900);
    notifyListeners();
    await _database.writeSetting(
      'compound_rest_seconds',
      compoundRestSeconds.toString(),
    );
  }

  Future<void> setSetNumberingStart(int value) async {
    if (value != 0 && value != 1) return;
    setNumberingStart = value;
    notifyListeners();
    await _database.writeSetting('set_numbering_start', value.toString());
  }

  Future<void> setAccessoryRestSeconds(int value) async {
    accessoryRestSeconds = value.clamp(30, 900);
    notifyListeners();
    await _database.writeSetting(
      'accessory_rest_seconds',
      accessoryRestSeconds.toString(),
    );
  }
}
