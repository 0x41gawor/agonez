import 'package:flutter/material.dart';

abstract final class AgonezSpacing {
  static const xxs = 4.0;
  static const xs = 6.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 14.0;
  static const xl = 16.0;
  static const xxl = 20.0;
  static const xxxl = 24.0;

  static const screenHorizontal = 20.0;
  static const entryHorizontal = 16.0;
}

abstract final class AgonezRadii {
  static const control = 8.0;
  static const button = 12.0;
  static const card = 14.0;
  static const hero = 18.0;
  static const sheet = 22.0;
  static const pill = 999.0;

  static const controlBorder = BorderRadius.all(Radius.circular(control));
  static const buttonBorder = BorderRadius.all(Radius.circular(button));
  static const cardBorder = BorderRadius.all(Radius.circular(card));
  static const heroBorder = BorderRadius.all(Radius.circular(hero));
  static const sheetTopBorder = BorderRadius.vertical(
    top: Radius.circular(sheet),
  );
}

abstract final class AgonezSizes {
  static const minimumTouchTarget = 44.0;
  static const compactSelector = 48.0;
  static const selector = 54.0;
  static const loadControlWidth = 64.0;
  static const loadControlHeight = 58.0;
  static const auxiliaryChipHeight = 38.0;
  static const primaryButtonHeight = 60.0;
  static const iconButton = 44.0;
  static const syncPillHeight = 28.0;
  static const miniWorkoutBarHeight = 56.0;
  static const bottomSafeGap = 8.0;
}

abstract final class AgonezDurations {
  static const quick = Duration(milliseconds: 120);
  static const holdReset = Duration(milliseconds: 200);
  static const standard = Duration(milliseconds: 220);
  static const snackbarUndo = Duration(seconds: 6);
  static const snackbarUndoAccessible = Duration(seconds: 10);
}

abstract final class AgonezInsets {
  static const screen = EdgeInsets.symmetric(
    horizontal: AgonezSpacing.screenHorizontal,
  );
  static const entry = EdgeInsets.symmetric(
    horizontal: AgonezSpacing.entryHorizontal,
  );
  static const card = EdgeInsets.all(AgonezSpacing.xl);
  static const sheetBody = EdgeInsets.fromLTRB(
    AgonezSpacing.xxl,
    0,
    AgonezSpacing.xxl,
    AgonezSpacing.xxl,
  );
}
