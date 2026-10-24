import 'dart:io';

import 'package:agonez/src/design/design.dart';
import 'package:flutter_test/flutter_test.dart';

/// The system splash is native, so its colours live in Android resources.
/// They must stay equal to the palette the Flutter boot screen draws with,
/// or the hand-off between the two would flash.
void main() {
  test('Android launch colours match the app palette', () {
    final light = _colors('android/app/src/main/res/values/colors.xml');
    final dark = _colors('android/app/src/main/res/values-night/colors.xml');

    expect(
      light['splash_background'],
      AgonezThemeColors.light.ground.toARGB32(),
    );
    expect(
      light['splash_emblem'],
      AgonezThemeColors.light.textPrimary.toARGB32(),
    );
    expect(dark['splash_background'], AgonezThemeColors.dark.ground.toARGB32());
    expect(dark['splash_emblem'], AgonezThemeColors.dark.goldText.toARGB32());
  });

  // AAPT2 stores longer XML strings as "STRING_TOO_LARGE", so the drawable
  // silently fails to load and Android shows its default icon instead.
  test('generated vector paths fit the Android string pool', () {
    const res = 'android/app/src/main/res';
    for (final drawable in [
      '$res/drawable/splash_emblem.xml',
      '$res/drawable-night/splash_emblem.xml',
      '$res/drawable/ic_launcher_foreground.xml',
      '$res/drawable/ic_stat_agonez.xml',
    ]) {
      final paths = RegExp(
        r'pathData="([^"]*)"',
      ).allMatches(File(drawable).readAsStringSync());
      expect(paths, isNotEmpty, reason: drawable);
      for (final path in paths) {
        expect(path.group(1)!.length, lessThan(32767), reason: drawable);
      }
    }
  });
}

Map<String, int> _colors(String path) => {
  for (final match in RegExp(
    r'<color name="(\w+)">#([0-9A-Fa-f]{8})</color>',
  ).allMatches(File(path).readAsStringSync()))
    match.group(1)!: int.parse(match.group(2)!, radix: 16),
};
