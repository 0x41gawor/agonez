import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../settings/app_settings_controller.dart';

/// Tells Android which theme the app uses.
///
/// The system splash is drawn before any Dart runs, so it cannot read the
/// settings database. From Android 12 it follows the application night mode
/// set here, so the next launch opens in the theme chosen in the app. The
/// native side is `MainActivity.kt`.
class SystemThemeBridge {
  const SystemThemeBridge([
    this._channel = const MethodChannel('agonez/system_ui'),
  ]);

  final MethodChannel _channel;

  Future<void> sync(ThemeMode mode) async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _channel.invokeMethod<void>('setNightMode', mode.name);
    } on MissingPluginException {
      // Widget tests and other embedders have no native handler.
    } on PlatformException {
      // A failed hint only affects the next splash, never the running app.
    }
  }

  /// Syncs the current theme mode of [settings] and every later change.
  /// Returns a callback that stops listening.
  VoidCallback bind(AppSettingsController settings) {
    var synced = settings.themeMode;
    unawaited(sync(synced));
    void listener() {
      if (settings.themeMode == synced) return;
      synced = settings.themeMode;
      unawaited(sync(synced));
    }

    settings.addListener(listener);
    return () => settings.removeListener(listener);
  }
}
