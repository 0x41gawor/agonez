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

  static const sheet = Color(0xFF15181C);
  static const scrim = Color(0x9E040506);
  static const disabledButtonBackground = Color(0xFF2E2A20);
  static const disabledButtonForeground = Color(0xFF8C8370);
  static const snackBarBackground = Color(0xFFE9E7E2);
  static const snackBarForeground = Color(0xFF0D0F12);
  static const snackBarAction = Color(0xFF6B5320);
  static const anatomyBase = Color(0xFF2B333C);
  static const anatomyOutline = Color(0xFF505B66);
  static const selectedControlBackground = Color(0xFF22262C);
  static const selectedControlForeground = Color(0xFFF2F0EB);
}

/// Light equivalents of the raw Agonez colour tokens.
///
/// [AgonezColors] remains the dark palette for backwards compatibility. New
/// UI should consume semantic colours from [AgonezThemeColors] instead.
abstract final class AgonezLightColors {
  static const ground = Color(0xFFF4F2EE);
  static const sunk = Color(0xFFECE9E3);
  static const panel = Color(0xFFFFFFFF);
  static const raised = Color(0xFFFAF9F6);
  static const alternative = Color(0xFFFAF9F6);

  static const line = Color(0xFFE0DCD4);
  static const lineSubtle = Color(0xFFE6E2DB);
  static const lineFaint = Color(0xFFECE9E3);
  static const control = Color(0xFFD3CEC5);
  static const controlStrong = Color(0xFFB7B1A6);

  static const textPrimary = Color(0xFF1B1C1E);
  static const textSecondary = Color(0xFF33363B);
  static const textMuted = Color(0xFF585D65);
  static const textDim = Color(0xFF62676F);
  static const textGhost = Color(0xFFBDB8AE);

  static const gold = Color(0xFF8A7041);
  static const goldText = Color(0xFF6E5830);
  static const goldInk = Color(0xFFFFFFFF);
  static const goldSoft = Color(0x148A7041);
  static const goldLine = Color(0xFFD7C7A4);

  static const prescription = Color(0xFF3D6890);
  static const prescriptionText = Color(0xFF2C5479);
  static const prescriptionBackground = Color(0x0F3D6890);
  static const prescriptionLine = Color(0xFFCAD7E4);

  static const caution = Color(0xFF955609);
  static const success = Color(0xFF2E8A62);
  static const successText = Color(0xFF22704E);
  static const error = Color(0xFFB4402B);
  static const muscleHeat = Color(0xFF1F9A6E);

  static const sheet = Color(0xFFFFFFFF);
  static const scrim = Color(0x571B1C1E);
  static const disabledButtonBackground = Color(0xFFE9E3D6);
  static const disabledButtonForeground = Color(0xFF857A64);
  static const snackBarBackground = Color(0xFF1B1C1E);
  static const snackBarForeground = Color(0xFFF4F2EE);
  static const snackBarAction = Color(0xFFE2C690);
  static const anatomyBase = Color(0xFFD3CEC5);
  static const anatomyOutline = Color(0xFF80858C);
  static const selectedControlBackground = Color(0xFFE4E0D8);
  static const selectedControlForeground = Color(0xFF1B1C1E);
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
    required this.lineFaint,
    required this.control,
    required this.controlStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textDim,
    required this.textGhost,
    required this.gold,
    required this.goldText,
    required this.goldInk,
    required this.goldSoft,
    required this.goldLine,
    required this.prescription,
    required this.prescriptionText,
    required this.prescriptionBackground,
    required this.prescriptionLine,
    required this.caution,
    required this.success,
    required this.successText,
    required this.error,
    required this.muscleHeat,
    required this.sheet,
    required this.scrim,
    required this.disabledButtonBackground,
    required this.disabledButtonForeground,
    required this.snackBarBackground,
    required this.snackBarForeground,
    required this.snackBarAction,
    required this.anatomyBase,
    required this.anatomyOutline,
    required this.selectedControlBackground,
    required this.selectedControlForeground,
  });

  static const dark = AgonezThemeColors(
    ground: AgonezColors.ground,
    sunk: AgonezColors.sunk,
    panel: AgonezColors.panel,
    raised: AgonezColors.raised,
    alternative: AgonezColors.alternative,
    line: AgonezColors.line,
    lineSubtle: AgonezColors.lineSubtle,
    lineFaint: AgonezColors.lineFaint,
    control: AgonezColors.control,
    controlStrong: AgonezColors.controlStrong,
    textPrimary: AgonezColors.textPrimary,
    textSecondary: AgonezColors.textSecondary,
    textMuted: AgonezColors.textMuted,
    textDim: AgonezColors.textDim,
    textGhost: AgonezColors.textGhost,
    gold: AgonezColors.gold,
    goldText: AgonezColors.goldText,
    goldInk: AgonezColors.goldInk,
    goldSoft: AgonezColors.goldSoft,
    goldLine: AgonezColors.goldLine,
    prescription: AgonezColors.prescription,
    prescriptionText: AgonezColors.prescriptionText,
    prescriptionBackground: AgonezColors.prescriptionBackground,
    prescriptionLine: AgonezColors.prescriptionLine,
    caution: AgonezColors.caution,
    success: AgonezColors.success,
    successText: AgonezColors.successText,
    error: AgonezColors.error,
    muscleHeat: AgonezColors.muscleHeat,
    sheet: AgonezColors.sheet,
    scrim: AgonezColors.scrim,
    disabledButtonBackground: AgonezColors.disabledButtonBackground,
    disabledButtonForeground: AgonezColors.disabledButtonForeground,
    snackBarBackground: AgonezColors.snackBarBackground,
    snackBarForeground: AgonezColors.snackBarForeground,
    snackBarAction: AgonezColors.snackBarAction,
    anatomyBase: AgonezColors.anatomyBase,
    anatomyOutline: AgonezColors.anatomyOutline,
    selectedControlBackground: AgonezColors.selectedControlBackground,
    selectedControlForeground: AgonezColors.selectedControlForeground,
  );

  static const light = AgonezThemeColors(
    ground: AgonezLightColors.ground,
    sunk: AgonezLightColors.sunk,
    panel: AgonezLightColors.panel,
    raised: AgonezLightColors.raised,
    alternative: AgonezLightColors.alternative,
    line: AgonezLightColors.line,
    lineSubtle: AgonezLightColors.lineSubtle,
    lineFaint: AgonezLightColors.lineFaint,
    control: AgonezLightColors.control,
    controlStrong: AgonezLightColors.controlStrong,
    textPrimary: AgonezLightColors.textPrimary,
    textSecondary: AgonezLightColors.textSecondary,
    textMuted: AgonezLightColors.textMuted,
    textDim: AgonezLightColors.textDim,
    textGhost: AgonezLightColors.textGhost,
    gold: AgonezLightColors.gold,
    goldText: AgonezLightColors.goldText,
    goldInk: AgonezLightColors.goldInk,
    goldSoft: AgonezLightColors.goldSoft,
    goldLine: AgonezLightColors.goldLine,
    prescription: AgonezLightColors.prescription,
    prescriptionText: AgonezLightColors.prescriptionText,
    prescriptionBackground: AgonezLightColors.prescriptionBackground,
    prescriptionLine: AgonezLightColors.prescriptionLine,
    caution: AgonezLightColors.caution,
    success: AgonezLightColors.success,
    successText: AgonezLightColors.successText,
    error: AgonezLightColors.error,
    muscleHeat: AgonezLightColors.muscleHeat,
    sheet: AgonezLightColors.sheet,
    scrim: AgonezLightColors.scrim,
    disabledButtonBackground: AgonezLightColors.disabledButtonBackground,
    disabledButtonForeground: AgonezLightColors.disabledButtonForeground,
    snackBarBackground: AgonezLightColors.snackBarBackground,
    snackBarForeground: AgonezLightColors.snackBarForeground,
    snackBarAction: AgonezLightColors.snackBarAction,
    anatomyBase: AgonezLightColors.anatomyBase,
    anatomyOutline: AgonezLightColors.anatomyOutline,
    selectedControlBackground: AgonezLightColors.selectedControlBackground,
    selectedControlForeground: AgonezLightColors.selectedControlForeground,
  );

  final Color ground;
  final Color sunk;
  final Color panel;
  final Color raised;
  final Color alternative;
  final Color line;
  final Color lineSubtle;
  final Color lineFaint;
  final Color control;
  final Color controlStrong;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textDim;
  final Color textGhost;
  final Color gold;
  final Color goldText;
  final Color goldInk;
  final Color goldSoft;
  final Color goldLine;
  final Color prescription;
  final Color prescriptionText;
  final Color prescriptionBackground;
  final Color prescriptionLine;
  final Color caution;
  final Color success;
  final Color successText;
  final Color error;
  final Color muscleHeat;
  final Color sheet;
  final Color scrim;
  final Color disabledButtonBackground;
  final Color disabledButtonForeground;
  final Color snackBarBackground;
  final Color snackBarForeground;
  final Color snackBarAction;
  final Color anatomyBase;
  final Color anatomyOutline;
  final Color selectedControlBackground;
  final Color selectedControlForeground;

  @override
  AgonezThemeColors copyWith({
    Color? ground,
    Color? sunk,
    Color? panel,
    Color? raised,
    Color? alternative,
    Color? line,
    Color? lineSubtle,
    Color? lineFaint,
    Color? control,
    Color? controlStrong,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? textDim,
    Color? textGhost,
    Color? gold,
    Color? goldText,
    Color? goldInk,
    Color? goldSoft,
    Color? goldLine,
    Color? prescription,
    Color? prescriptionText,
    Color? prescriptionBackground,
    Color? prescriptionLine,
    Color? caution,
    Color? success,
    Color? successText,
    Color? error,
    Color? muscleHeat,
    Color? sheet,
    Color? scrim,
    Color? disabledButtonBackground,
    Color? disabledButtonForeground,
    Color? snackBarBackground,
    Color? snackBarForeground,
    Color? snackBarAction,
    Color? anatomyBase,
    Color? anatomyOutline,
    Color? selectedControlBackground,
    Color? selectedControlForeground,
  }) {
    return AgonezThemeColors(
      ground: ground ?? this.ground,
      sunk: sunk ?? this.sunk,
      panel: panel ?? this.panel,
      raised: raised ?? this.raised,
      alternative: alternative ?? this.alternative,
      line: line ?? this.line,
      lineSubtle: lineSubtle ?? this.lineSubtle,
      lineFaint: lineFaint ?? this.lineFaint,
      control: control ?? this.control,
      controlStrong: controlStrong ?? this.controlStrong,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      textDim: textDim ?? this.textDim,
      textGhost: textGhost ?? this.textGhost,
      gold: gold ?? this.gold,
      goldText: goldText ?? this.goldText,
      goldInk: goldInk ?? this.goldInk,
      goldSoft: goldSoft ?? this.goldSoft,
      goldLine: goldLine ?? this.goldLine,
      prescription: prescription ?? this.prescription,
      prescriptionText: prescriptionText ?? this.prescriptionText,
      prescriptionBackground:
          prescriptionBackground ?? this.prescriptionBackground,
      prescriptionLine: prescriptionLine ?? this.prescriptionLine,
      caution: caution ?? this.caution,
      success: success ?? this.success,
      successText: successText ?? this.successText,
      error: error ?? this.error,
      muscleHeat: muscleHeat ?? this.muscleHeat,
      sheet: sheet ?? this.sheet,
      scrim: scrim ?? this.scrim,
      disabledButtonBackground:
          disabledButtonBackground ?? this.disabledButtonBackground,
      disabledButtonForeground:
          disabledButtonForeground ?? this.disabledButtonForeground,
      snackBarBackground: snackBarBackground ?? this.snackBarBackground,
      snackBarForeground: snackBarForeground ?? this.snackBarForeground,
      snackBarAction: snackBarAction ?? this.snackBarAction,
      anatomyBase: anatomyBase ?? this.anatomyBase,
      anatomyOutline: anatomyOutline ?? this.anatomyOutline,
      selectedControlBackground:
          selectedControlBackground ?? this.selectedControlBackground,
      selectedControlForeground:
          selectedControlForeground ?? this.selectedControlForeground,
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
      lineFaint: Color.lerp(lineFaint, other.lineFaint, t)!,
      control: Color.lerp(control, other.control, t)!,
      controlStrong: Color.lerp(controlStrong, other.controlStrong, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textDim: Color.lerp(textDim, other.textDim, t)!,
      textGhost: Color.lerp(textGhost, other.textGhost, t)!,
      gold: Color.lerp(gold, other.gold, t)!,
      goldText: Color.lerp(goldText, other.goldText, t)!,
      goldInk: Color.lerp(goldInk, other.goldInk, t)!,
      goldSoft: Color.lerp(goldSoft, other.goldSoft, t)!,
      goldLine: Color.lerp(goldLine, other.goldLine, t)!,
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
      prescriptionLine: Color.lerp(
        prescriptionLine,
        other.prescriptionLine,
        t,
      )!,
      caution: Color.lerp(caution, other.caution, t)!,
      success: Color.lerp(success, other.success, t)!,
      successText: Color.lerp(successText, other.successText, t)!,
      error: Color.lerp(error, other.error, t)!,
      muscleHeat: Color.lerp(muscleHeat, other.muscleHeat, t)!,
      sheet: Color.lerp(sheet, other.sheet, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
      disabledButtonBackground: Color.lerp(
        disabledButtonBackground,
        other.disabledButtonBackground,
        t,
      )!,
      disabledButtonForeground: Color.lerp(
        disabledButtonForeground,
        other.disabledButtonForeground,
        t,
      )!,
      snackBarBackground: Color.lerp(
        snackBarBackground,
        other.snackBarBackground,
        t,
      )!,
      snackBarForeground: Color.lerp(
        snackBarForeground,
        other.snackBarForeground,
        t,
      )!,
      snackBarAction: Color.lerp(snackBarAction, other.snackBarAction, t)!,
      anatomyBase: Color.lerp(anatomyBase, other.anatomyBase, t)!,
      anatomyOutline: Color.lerp(anatomyOutline, other.anatomyOutline, t)!,
      selectedControlBackground: Color.lerp(
        selectedControlBackground,
        other.selectedControlBackground,
        t,
      )!,
      selectedControlForeground: Color.lerp(
        selectedControlForeground,
        other.selectedControlForeground,
        t,
      )!,
    );
  }
}

extension AgonezThemeAccess on BuildContext {
  AgonezThemeColors get agonezColors {
    final theme = Theme.of(this);
    return theme.extension<AgonezThemeColors>() ??
        (theme.brightness == Brightness.light
            ? AgonezThemeColors.light
            : AgonezThemeColors.dark);
  }
}
