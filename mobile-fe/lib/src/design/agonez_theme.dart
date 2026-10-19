import 'package:flutter/material.dart';

import 'agonez_colors.dart';
import 'agonez_tokens.dart';
import 'agonez_typography.dart';

abstract final class AgonezTheme {
  static ThemeData get dark =>
      _build(colors: AgonezThemeColors.dark, brightness: Brightness.dark);

  static ThemeData get light =>
      _build(colors: AgonezThemeColors.light, brightness: Brightness.light);

  static ThemeData _build({
    required AgonezThemeColors colors,
    required Brightness brightness,
  }) {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: colors.gold,
          brightness: brightness,
        ).copyWith(
          primary: colors.gold,
          onPrimary: colors.goldInk,
          primaryContainer: colors.goldSoft,
          onPrimaryContainer: colors.goldText,
          secondary: colors.prescription,
          onSecondary: colors.goldInk,
          secondaryContainer: colors.prescriptionBackground,
          onSecondaryContainer: colors.prescriptionText,
          error: colors.error,
          onError: colors.goldInk,
          surface: colors.panel,
          onSurface: colors.textPrimary,
          onSurfaceVariant: colors.textMuted,
          outline: colors.control,
          outlineVariant: colors.line,
          inverseSurface: colors.snackBarBackground,
          onInverseSurface: colors.snackBarForeground,
          shadow: Colors.black,
          scrim: colors.scrim,
        );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colors.ground,
      canvasColor: colors.ground,
      textTheme: AgonezTypography.themedTextTheme(colors),
      extensions: <ThemeExtension<dynamic>>[colors],
    );

    return base.copyWith(
      dividerColor: colors.lineSubtle,
      disabledColor: colors.textDim,
      focusColor: colors.gold,
      highlightColor: Colors.transparent,
      splashColor: colors.goldSoft,
      iconTheme: IconThemeData(color: colors.textSecondary),
      primaryIconTheme: IconThemeData(color: colors.textPrimary),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.ground,
        foregroundColor: colors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: colors.panel,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AgonezRadii.cardBorder,
          side: BorderSide(color: colors.line),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colors.lineSubtle,
        thickness: 1,
        space: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(
            Size(0, AgonezSizes.primaryButtonHeight),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: AgonezSpacing.xl),
          ),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return colors.disabledButtonBackground;
            }
            return colors.gold;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return colors.disabledButtonForeground;
            }
            return colors.goldInk;
          }),
          textStyle: const WidgetStatePropertyAll(AgonezTypography.button),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: AgonezRadii.cardBorder),
          ),
          elevation: const WidgetStatePropertyAll(0),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(0, 48)),
          foregroundColor: WidgetStatePropertyAll(colors.textSecondary),
          side: WidgetStatePropertyAll(BorderSide(color: colors.control)),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: AgonezRadii.buttonBorder),
          ),
          textStyle: const WidgetStatePropertyAll(AgonezTypography.label),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(
            Size(
              AgonezSizes.minimumTouchTarget,
              AgonezSizes.minimumTouchTarget,
            ),
          ),
          foregroundColor: WidgetStatePropertyAll(colors.textSecondary),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: AgonezRadii.controlBorder),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(
            Size.square(AgonezSizes.iconButton),
          ),
          foregroundColor: WidgetStatePropertyAll(colors.textSecondary),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: AgonezRadii.buttonBorder),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.transparent,
        selectedColor: colors.goldSoft,
        disabledColor: Colors.transparent,
        side: BorderSide(color: colors.control),
        shape: const StadiumBorder(),
        labelStyle: AgonezTypography.label.copyWith(
          color: colors.textSecondary,
        ),
        secondaryLabelStyle: AgonezTypography.label.copyWith(
          color: colors.goldText,
        ),
        padding: const EdgeInsets.symmetric(horizontal: AgonezSpacing.sm),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.selected)
                ? colors.selectedControlBackground
                : Colors.transparent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.selected)
                ? colors.selectedControlForeground
                : colors.textMuted;
          }),
          side: WidgetStatePropertyAll(BorderSide(color: colors.control)),
          textStyle: const WidgetStatePropertyAll(AgonezTypography.label),
          shape: const WidgetStatePropertyAll(StadiumBorder()),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.sheet,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: colors.sheet,
        modalBarrierColor: colors.scrim,
        elevation: 16,
        shape: RoundedRectangleBorder(
          borderRadius: AgonezRadii.sheetTopBorder,
          side: BorderSide(color: colors.control),
        ),
        showDragHandle: false,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.raised,
        surfaceTintColor: Colors.transparent,
        elevation: 16,
        shape: const RoundedRectangleBorder(
          borderRadius: AgonezRadii.cardBorder,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.snackBarBackground,
        contentTextStyle: TextStyle(
          color: colors.snackBarForeground,
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
        ),
        actionTextColor: colors.snackBarAction,
        behavior: SnackBarBehavior.floating,
        elevation: 12,
        shape: const RoundedRectangleBorder(
          borderRadius: AgonezRadii.cardBorder,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.sunk,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AgonezSpacing.lg,
          vertical: AgonezSpacing.md,
        ),
        hintStyle: AgonezTypography.body.copyWith(color: colors.textMuted),
        border: OutlineInputBorder(
          borderRadius: AgonezRadii.buttonBorder,
          borderSide: BorderSide(color: colors.control),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AgonezRadii.buttonBorder,
          borderSide: BorderSide(color: colors.control),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AgonezRadii.buttonBorder,
          borderSide: BorderSide(color: colors.gold, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AgonezRadii.buttonBorder,
          borderSide: BorderSide(color: colors.error),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        backgroundColor: colors.ground,
        surfaceTintColor: Colors.transparent,
        indicatorColor: Colors.transparent,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            color: states.contains(WidgetState.selected)
                ? colors.gold
                : colors.textDim,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return AgonezTypography.caption.copyWith(
            color: states.contains(WidgetState.selected)
                ? colors.textPrimary
                : colors.textDim,
          );
        }),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.gold,
        linearTrackColor: colors.line,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: colors.gold,
        selectionColor: colors.goldSoft,
        selectionHandleColor: colors.gold,
      ),
    );
  }
}
