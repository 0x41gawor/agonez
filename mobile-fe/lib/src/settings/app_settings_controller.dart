import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../storage/app_database.dart';

class AppSettingsController extends ChangeNotifier {
  AppSettingsController._({
    required AppDatabase database,
    required Locale locale,
    required this.hapticsEnabled,
    required this.restNotificationsEnabled,
    required this.restSoundEnabled,
    required this.compoundRestSeconds,
    required this.accessoryRestSeconds,
  }) : _database = database,
       _locale = locale;

  static Future<AppSettingsController> load(AppDatabase database) async {
    final storedLocale = await database.readSetting('locale');
    final systemLanguage = PlatformDispatcher.instance.locale.languageCode;
    final language = storedLocale == 'pl' || storedLocale == 'en'
        ? storedLocale!
        : (systemLanguage == 'pl' ? 'pl' : 'en');
    return AppSettingsController._(
      database: database,
      locale: Locale(language),
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
    );
  }

  final AppDatabase _database;
  Locale _locale;

  Locale get locale => _locale;
  bool hapticsEnabled;
  bool restNotificationsEnabled;
  bool restSoundEnabled;
  int compoundRestSeconds;
  int accessoryRestSeconds;

  Future<void> setLocale(Locale value) async {
    if (value.languageCode != 'en' && value.languageCode != 'pl') return;
    if (_locale == value) return;
    _locale = value;
    notifyListeners();
    await _database.writeSetting('locale', value.languageCode);
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

  Future<void> setAccessoryRestSeconds(int value) async {
    accessoryRestSeconds = value.clamp(30, 900);
    notifyListeners();
    await _database.writeSetting(
      'accessory_rest_seconds',
      accessoryRestSeconds.toString(),
    );
  }
}
