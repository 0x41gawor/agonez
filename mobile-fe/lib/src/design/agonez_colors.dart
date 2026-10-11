import 'package:flutter/material.dart';

/// Raw Agonez colour tokens.
///
/// Widgets should normally read [AgonezThemeColors] from the active theme so
/// the same semantic roles can later be mapped to a light theme.
abstract final class AgonezColors {
  static const ground = Color(0xFF0D0F12);
  static const sunk = Color(0xFF0F1215);
  static const panel = Color(0xFF14171B);
  static const raised = Color(0xFF181C21);
  static const alternative = Color(0xFF111418);

  static const line = Color(0xFF23272D);
  static const lineSubtle = Color(0xFF1E2227);
  static const lineFaint = Color(0xFF1A1D22);
  static const control = Color(0xFF2A2E35);
  static const controlStrong = Color(0xFF3A3F47);

  static const textPrimary = Color(0xFFE9E7E2);
  static const textSecondary = Color(0xFFC9CDD3);
  static const textMuted = Color(0xFF9AA0A8);
  static const textDim = Color(0xFF7A808A);
  static const textGhost = Color(0xFF4A5059);

  static const gold = Color(0xFFC2A36B);
  static const goldText = Color(0xFFE2C690);
  static const goldInk = Color(0xFF17140D);
  static const goldSoft = Color(0x14C2A36B);
  static const goldLine = Color(0xFF4A3F28);

  static const prescription = Color(0xFF8FA9C4);
  static const prescriptionText = Color(0xFFAFC2D6);
  static const prescriptionBackground = Color(0x128FA9C4);
  static const prescriptionLine = Color(0xFF2C3A4A);

  static const caution = Color(0xFFE8B06A);
  static const success = Color(0xFF4E9C79);
  static const successText = Color(0xFF7FC4A0);
  static const error = Color(0xFFE5735C);
  static const muscleHeat = Color(0xFF2E9E78);
}

/// Semantic colours not represented by Material's [ColorScheme].
@immutable
class AgonezThemeColors extends ThemeExtension<AgonezThemeColors> {
  const AgonezThemeColors({
    required this.ground,
    required this.sunk,
    required this.panel,
    required this.raised,
    required this.alternative,
    required this.line,
    required this.lineSubtle,
    required this.control,
    required this.controlStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textDim,
    required this.gold,
    required this.goldText,
    required this.goldInk,
    required this.goldSoft,
    required this.prescription,
    required this.prescriptionText,
    required this.prescriptionBackground,
    required this.caution,
    required this.success,
    required this.successText,
    required this.error,
    required this.muscleHeat,
  });

  static const dark = AgonezThemeColors(
    ground: AgonezColors.ground,
    sunk: AgonezColors.sunk,
    panel: AgonezColors.panel,
    raised: AgonezColors.raised,
    alternative: AgonezColors.alternative,
    line: AgonezColors.line,
    lineSubtle: AgonezColors.lineSubtle,
    control: AgonezColors.control,
    controlStrong: AgonezColors.controlStrong,
    textPrimary: AgonezColors.textPrimary,
    textSecondary: AgonezColors.textSecondary,
    textMuted: AgonezColors.textMuted,
    textDim: AgonezColors.textDim,
    gold: AgonezColors.gold,
    goldText: AgonezColors.goldText,
    goldInk: AgonezColors.goldInk,
    goldSoft: AgonezColors.goldSoft,
    prescription: AgonezColors.prescription,
    prescriptionText: AgonezColors.prescriptionText,
    prescriptionBackground: AgonezColors.prescriptionBackground,
    caution: AgonezColors.caution,
    success: AgonezColors.success,
    successText: AgonezColors.successText,
    error: AgonezColors.error,
    muscleHeat: AgonezColors.muscleHeat,
  );

  final Color ground;
  final Color sunk;
  final Color panel;
  final Color raised;
  final Color alternative;
  final Color line;
  final Color lineSubtle;
  final Color control;
  final Color controlStrong;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textDim;
  final Color gold;
  final Color goldText;
  final Color goldInk;
  final Color goldSoft;
  final Color prescription;
  final Color prescriptionText;
  final Color prescriptionBackground;
  final Color caution;
  final Color success;
  final Color successText;
  final Color error;
  final Color muscleHeat;

  @override
  AgonezThemeColors copyWith({
    Color? ground,
    Color? sunk,
    Color? panel,
    Color? raised,
    Color? alternative,
    Color? line,
    Color? lineSubtle,
    Color? control,
    Color? controlStrong,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? textDim,
    Color? gold,
    Color? goldText,
    Color? goldInk,
    Color? goldSoft,
    Color? prescription,
    Color? prescriptionText,
    Color? prescriptionBackground,
    Color? caution,
    Color? success,
    Color? successText,
    Color? error,
    Color? muscleHeat,
  }) {
    return AgonezThemeColors(
      ground: ground ?? this.ground,
      sunk: sunk ?? this.sunk,
      panel: panel ?? this.panel,
      raised: raised ?? this.raised,
      alternative: alternative ?? this.alternative,
      line: line ?? this.line,
      lineSubtle: lineSubtle ?? this.lineSubtle,
      control: control ?? this.control,
      controlStrong: controlStrong ?? this.controlStrong,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      textDim: textDim ?? this.textDim,
      gold: gold ?? this.gold,
      goldText: goldText ?? this.goldText,
      goldInk: goldInk ?? this.goldInk,
      goldSoft: goldSoft ?? this.goldSoft,
      prescription: prescription ?? this.prescription,
      prescriptionText: prescriptionText ?? this.prescriptionText,
      prescriptionBackground:
          prescriptionBackground ?? this.prescriptionBackground,
      caution: caution ?? this.caution,
      success: success ?? this.success,
      successText: successText ?? this.successText,
      error: error ?? this.error,
      muscleHeat: muscleHeat ?? this.muscleHeat,
    );
  }

  @override
  AgonezThemeColors lerp(covariant AgonezThemeColors? other, double t) {
    if (other == null) return this;
    return AgonezThemeColors(
      ground: Color.lerp(ground, other.ground, t)!,
      sunk: Color.lerp(sunk, other.sunk, t)!,
      panel: Color.lerp(panel, other.panel, t)!,
      raised: Color.lerp(raised, other.raised, t)!,
      alternative: Color.lerp(alternative, other.alternative, t)!,
      line: Color.lerp(line, other.line, t)!,
      lineSubtle: Color.lerp(lineSubtle, other.lineSubtle, t)!,
      control: Color.lerp(control, other.control, t)!,
      controlStrong: Color.lerp(controlStrong, other.controlStrong, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textDim: Color.lerp(textDim, other.textDim, t)!,
      gold: Color.lerp(gold, other.gold, t)!,
      goldText: Color.lerp(goldText, other.goldText, t)!,
      goldInk: Color.lerp(goldInk, other.goldInk, t)!,
      goldSoft: Color.lerp(goldSoft, other.goldSoft, t)!,
      prescription: Color.lerp(prescription, other.prescription, t)!,
      prescriptionText: Color.lerp(
        prescriptionText,
        other.prescriptionText,
        t,
      )!,
      prescriptionBackground: Color.lerp(
        prescriptionBackground,
        other.prescriptionBackground,
        t,
      )!,
      caution: Color.lerp(caution, other.caution, t)!,
      success: Color.lerp(success, other.success, t)!,
      successText: Color.lerp(successText, other.successText, t)!,
      error: Color.lerp(error, other.error, t)!,
      muscleHeat: Color.lerp(muscleHeat, other.muscleHeat, t)!,
    );
  }
}

extension AgonezThemeAccess on BuildContext {
  AgonezThemeColors get agonezColors =>
      Theme.of(this).extension<AgonezThemeColors>() ?? AgonezThemeColors.dark;
}
