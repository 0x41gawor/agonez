import 'package:flutter/material.dart';

abstract final class AgonezColors {
  static const ground = Color(0xFF0D0F12);
  static const panel = Color(0xFF14171B);
  static const raised = Color(0xFF181C21);
  static const line = Color(0xFF23272D);
  static const text = Color(0xFFE9E7E2);
  static const muted = Color(0xFF9AA0A8);
  static const gold = Color(0xFFC2A36B);
  static const prescription = Color(0xFFAFC2D6);
  static const success = Color(0xFF7FC4A0);
  static const warning = Color(0xFFE8B06A);
  static const error = Color(0xFFE5735C);
}

ThemeData agonezTheme() => ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: AgonezColors.ground,
  colorScheme: const ColorScheme.dark(
    surface: AgonezColors.panel,
    primary: AgonezColors.gold,
    secondary: AgonezColors.prescription,
    error: AgonezColors.error,
  ),
  fontFamily: 'Geist',
  textTheme: const TextTheme(
    headlineLarge: TextStyle(
      fontSize: 34,
      fontWeight: FontWeight.w600,
      letterSpacing: -.7,
    ),
    headlineMedium: TextStyle(
      fontSize: 27,
      fontWeight: FontWeight.w600,
      letterSpacing: -.5,
    ),
    titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
    bodyMedium: TextStyle(fontSize: 14, color: AgonezColors.text),
    labelSmall: TextStyle(
      fontSize: 11,
      letterSpacing: 1.4,
      color: AgonezColors.muted,
    ),
  ),
  cardTheme: const CardThemeData(
    color: AgonezColors.panel,
    elevation: 0,
    margin: EdgeInsets.zero,
  ),
  navigationBarTheme: const NavigationBarThemeData(
    backgroundColor: AgonezColors.panel,
    indicatorColor: Color(0x332E9E78),
    height: 72,
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: AgonezColors.gold,
      foregroundColor: const Color(0xFF17140D),
      minimumSize: const Size.fromHeight(56),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
    ),
  ),
  useMaterial3: true,
);
