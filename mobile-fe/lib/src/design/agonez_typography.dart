import 'package:flutter/material.dart';

import 'agonez_colors.dart';

abstract final class AgonezTypography {
  /// Kept in one place so a bundled Agonez family can replace the platform
  /// default without changing feature widgets.
  static const String? fontFamily = null;
  static const monoFontFamily = 'monospace';

  static const display = TextStyle(
    fontFamily: fontFamily,
    fontSize: 34,
    height: 1.05,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.68,
  );

  static const exerciseTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 27,
    height: 1.1,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.54,
  );

  static const sheetTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    height: 1.2,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
  );

  static const title = TextStyle(
    fontFamily: fontFamily,
    fontSize: 17,
    height: 1.25,
    fontWeight: FontWeight.w600,
  );

  static const bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    height: 1.45,
    fontWeight: FontWeight.w400,
  );

  static const body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13.5,
    height: 1.45,
    fontWeight: FontWeight.w400,
  );

  static const label = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    height: 1.25,
    fontWeight: FontWeight.w500,
  );

  static const caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11.5,
    height: 1.35,
    fontWeight: FontWeight.w400,
  );

  static const eyebrow = TextStyle(
    fontFamily: monoFontFamily,
    fontSize: 10.5,
    height: 1.25,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.47,
  );

  static const monoSmall = TextStyle(
    fontFamily: monoFontFamily,
    fontSize: 11,
    height: 1.3,
    fontWeight: FontWeight.w400,
  );

  static const inputNumber = TextStyle(
    fontFamily: monoFontFamily,
    fontSize: 26,
    height: 1.05,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.52,
  );

  static const clock = TextStyle(
    fontFamily: monoFontFamily,
    fontSize: 44,
    height: 1,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.88,
  );

  static const button = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    height: 1.1,
    fontWeight: FontWeight.w600,
  );

  static const buttonSupporting = TextStyle(
    fontFamily: monoFontFamily,
    fontSize: 11,
    height: 1.2,
    fontWeight: FontWeight.w500,
  );

  static const textTheme = TextTheme(
    displayLarge: display,
    headlineLarge: exerciseTitle,
    headlineMedium: sheetTitle,
    titleLarge: title,
    bodyLarge: bodyLarge,
    bodyMedium: body,
    bodySmall: caption,
    labelLarge: button,
    labelMedium: label,
    labelSmall: monoSmall,
  );

  /// Returns the semantic type scale for the active palette.
  ///
  /// Feature widgets should use these resolved roles instead of the metric-only
  /// constants above whenever the text does not set an explicit semantic color.
  static TextTheme of(BuildContext context) => Theme.of(context).textTheme;

  static TextStyle eyebrowOf(BuildContext context) =>
      eyebrow.copyWith(color: context.agonezColors.textMuted);

  static TextStyle inputNumberOf(BuildContext context) =>
      inputNumber.copyWith(color: context.agonezColors.textPrimary);

  static TextStyle clockOf(BuildContext context) =>
      clock.copyWith(color: context.agonezColors.goldText);

  /// Applies palette colours to the type scale installed on [ThemeData].
  ///
  /// The reusable metric styles above intentionally stay colourless. Widgets
  /// resolve their semantic role through [of] (or a custom `...Of` resolver)
  /// so a theme switch updates both typography metrics and foreground color.
  static TextTheme themedTextTheme(AgonezThemeColors colors) {
    return textTheme.copyWith(
      displayLarge: display.copyWith(color: colors.textPrimary),
      headlineLarge: exerciseTitle.copyWith(color: colors.textPrimary),
      headlineMedium: sheetTitle.copyWith(color: colors.textPrimary),
      titleLarge: title.copyWith(color: colors.textPrimary),
      bodyLarge: bodyLarge.copyWith(color: colors.textPrimary),
      bodyMedium: body.copyWith(color: colors.textSecondary),
      bodySmall: caption.copyWith(color: colors.textMuted),
      labelLarge: button.copyWith(color: colors.textPrimary),
      labelMedium: label.copyWith(color: colors.textSecondary),
      labelSmall: monoSmall.copyWith(color: colors.textMuted),
    );
  }
}
