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
    color: AgonezColors.textPrimary,
  );

  static const exerciseTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 27,
    height: 1.1,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.54,
    color: AgonezColors.textPrimary,
  );

  static const sheetTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    height: 1.2,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    color: AgonezColors.textPrimary,
  );

  static const title = TextStyle(
    fontFamily: fontFamily,
    fontSize: 17,
    height: 1.25,
    fontWeight: FontWeight.w600,
    color: AgonezColors.textPrimary,
  );

  static const bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    height: 1.45,
    fontWeight: FontWeight.w400,
    color: AgonezColors.textPrimary,
  );

  static const body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13.5,
    height: 1.45,
    fontWeight: FontWeight.w400,
    color: AgonezColors.textSecondary,
  );

  static const label = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    height: 1.25,
    fontWeight: FontWeight.w500,
    color: AgonezColors.textSecondary,
  );

  static const caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11.5,
    height: 1.35,
    fontWeight: FontWeight.w400,
    color: AgonezColors.textMuted,
  );

  static const eyebrow = TextStyle(
    fontFamily: monoFontFamily,
    fontSize: 10.5,
    height: 1.25,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.47,
    color: AgonezColors.textMuted,
  );

  static const monoSmall = TextStyle(
    fontFamily: monoFontFamily,
    fontSize: 11,
    height: 1.3,
    fontWeight: FontWeight.w400,
    color: AgonezColors.textMuted,
  );

  static const inputNumber = TextStyle(
    fontFamily: monoFontFamily,
    fontSize: 26,
    height: 1.05,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.52,
    color: AgonezColors.textPrimary,
  );

  static const clock = TextStyle(
    fontFamily: monoFontFamily,
    fontSize: 44,
    height: 1,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.88,
    color: AgonezColors.goldText,
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
}
