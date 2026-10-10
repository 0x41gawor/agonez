import 'package:flutter/material.dart';

import 'agonez_colors.dart';
import 'agonez_tokens.dart';
import 'agonez_typography.dart';

abstract final class AgonezTheme {
  static ThemeData get dark {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: AgonezColors.gold,
          brightness: Brightness.dark,
        ).copyWith(
          primary: AgonezColors.gold,
          onPrimary: AgonezColors.goldInk,
          primaryContainer: AgonezColors.goldSoft,
          onPrimaryContainer: AgonezColors.goldText,
          secondary: AgonezColors.prescription,
          onSecondary: AgonezColors.ground,
          secondaryContainer: AgonezColors.prescriptionBackground,
          onSecondaryContainer: AgonezColors.prescriptionText,
          error: AgonezColors.error,
          onError: AgonezColors.ground,
          surface: AgonezColors.panel,
          onSurface: AgonezColors.textPrimary,
          onSurfaceVariant: AgonezColors.textMuted,
          outline: AgonezColors.control,
          outlineVariant: AgonezColors.line,
          shadow: Colors.black,
          scrim: Colors.black,
        );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AgonezColors.ground,
      canvasColor: AgonezColors.ground,
      textTheme: AgonezTypography.textTheme,
      extensions: const <ThemeExtension<dynamic>>[AgonezThemeColors.dark],
    );

    return base.copyWith(
      dividerColor: AgonezColors.lineSubtle,
      disabledColor: AgonezColors.textDim,
      focusColor: AgonezColors.gold,
      highlightColor: Colors.transparent,
      splashColor: AgonezColors.goldSoft,
      cardTheme: const CardThemeData(
        color: AgonezColors.panel,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AgonezRadii.cardBorder,
          side: BorderSide(color: AgonezColors.line),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AgonezColors.lineSubtle,
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
              return const Color(0xFF2E2A20);
            }
            return AgonezColors.gold;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return const Color(0xFF8C8370);
            }
            return AgonezColors.goldInk;
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
          foregroundColor: const WidgetStatePropertyAll(
            AgonezColors.textSecondary,
          ),
          side: const WidgetStatePropertyAll(
            BorderSide(color: AgonezColors.control),
          ),
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
          foregroundColor: const WidgetStatePropertyAll(
            AgonezColors.textSecondary,
          ),
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
          foregroundColor: const WidgetStatePropertyAll(
            AgonezColors.textSecondary,
          ),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: AgonezRadii.buttonBorder),
          ),
        ),
      ),
      chipTheme: const ChipThemeData(
        backgroundColor: Colors.transparent,
        selectedColor: AgonezColors.goldSoft,
        disabledColor: Colors.transparent,
        side: BorderSide(color: AgonezColors.control),
        shape: StadiumBorder(),
        labelStyle: AgonezTypography.label,
        secondaryLabelStyle: AgonezTypography.label,
        padding: EdgeInsets.symmetric(horizontal: AgonezSpacing.sm),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF15181C),
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: Color(0xFF15181C),
        modalBarrierColor: Color(0xA0040506),
        elevation: 16,
        shape: RoundedRectangleBorder(
          borderRadius: AgonezRadii.sheetTopBorder,
          side: BorderSide(color: AgonezColors.control),
        ),
        showDragHandle: false,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AgonezColors.raised,
        surfaceTintColor: Colors.transparent,
        elevation: 16,
        shape: RoundedRectangleBorder(borderRadius: AgonezRadii.cardBorder),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AgonezColors.textPrimary,
        contentTextStyle: TextStyle(
          color: AgonezColors.ground,
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
        ),
        actionTextColor: Color(0xFF6B5320),
        behavior: SnackBarBehavior.floating,
        elevation: 12,
        shape: RoundedRectangleBorder(borderRadius: AgonezRadii.cardBorder),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: AgonezColors.sunk,
        contentPadding: EdgeInsets.symmetric(
          horizontal: AgonezSpacing.lg,
          vertical: AgonezSpacing.md,
        ),
        hintStyle: AgonezTypography.body,
        border: OutlineInputBorder(
          borderRadius: AgonezRadii.buttonBorder,
          borderSide: BorderSide(color: AgonezColors.control),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AgonezRadii.buttonBorder,
          borderSide: BorderSide(color: AgonezColors.control),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AgonezRadii.buttonBorder,
          borderSide: BorderSide(color: AgonezColors.gold, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AgonezRadii.buttonBorder,
          borderSide: BorderSide(color: AgonezColors.error),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        backgroundColor: AgonezColors.ground,
        surfaceTintColor: Colors.transparent,
        indicatorColor: Colors.transparent,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AgonezColors.gold
                : AgonezColors.textDim,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return AgonezTypography.caption.copyWith(
            color: states.contains(WidgetState.selected)
                ? AgonezColors.textPrimary
                : AgonezColors.textDim,
          );
        }),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AgonezColors.gold,
        linearTrackColor: AgonezColors.line,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AgonezColors.gold,
        selectionColor: AgonezColors.goldSoft,
        selectionHandleColor: AgonezColors.gold,
      ),
    );
  }
}
