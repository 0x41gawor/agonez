import 'package:agonez/src/design/design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('light and dark themes expose their semantic reference palettes', () {
    final lightTheme = AgonezTheme.light;
    final light = lightTheme.extension<AgonezThemeColors>()!;
    expect(lightTheme.brightness, Brightness.light);
    expect(lightTheme.scaffoldBackgroundColor, const Color(0xFFF4F2EE));
    expect(light.ground, const Color(0xFFF4F2EE));
    expect(light.panel, const Color(0xFFFFFFFF));
    expect(light.textPrimary, const Color(0xFF1B1C1E));
    expect(light.gold, const Color(0xFF8A7041));
    expect(light.prescription, const Color(0xFF3D6890));
    expect(light.selectedControlBackground, const Color(0xFFE4E0D8));
    expect(light.selectedControlForeground, const Color(0xFF1B1C1E));

    final darkTheme = AgonezTheme.dark;
    final dark = darkTheme.extension<AgonezThemeColors>()!;
    expect(darkTheme.brightness, Brightness.dark);
    expect(darkTheme.scaffoldBackgroundColor, const Color(0xFF0D0F12));
    expect(dark.ground, const Color(0xFF0D0F12));
    expect(dark.panel, const Color(0xFF14171B));
    expect(dark.textPrimary, const Color(0xFFE9E7E2));
    expect(dark.gold, const Color(0xFFC2A36B));
    expect(dark.prescription, const Color(0xFF8FA9C4));
    expect(dark.selectedControlBackground, const Color(0xFF22262C));
    expect(dark.selectedControlForeground, const Color(0xFFF2F0EB));
  });

  for (final themeCase in <(String, ThemeData, AgonezThemeColors)>[
    ('light', AgonezTheme.light, AgonezThemeColors.light),
    ('dark', AgonezTheme.dark, AgonezThemeColors.dark),
  ]) {
    test('${themeCase.$1} theme maps every shared typography role', () {
      final textTheme = themeCase.$2.textTheme;
      final colors = themeCase.$3;

      for (final style in [
        textTheme.displayLarge,
        textTheme.headlineLarge,
        textTheme.headlineMedium,
        textTheme.titleLarge,
        textTheme.bodyLarge,
        textTheme.labelLarge,
      ]) {
        expect(style?.color, colors.textPrimary);
      }
      for (final style in [textTheme.bodyMedium, textTheme.labelMedium]) {
        expect(style?.color, colors.textSecondary);
      }
      for (final style in [textTheme.bodySmall, textTheme.labelSmall]) {
        expect(style?.color, colors.textMuted);
      }
    });

    test(
      '${themeCase.$1} segmented controls use reference selection colors',
      () {
        final style = themeCase.$2.segmentedButtonTheme.style!;
        const selected = <WidgetState>{WidgetState.selected};
        expect(
          style.backgroundColor?.resolve(selected),
          themeCase.$3.selectedControlBackground,
        );
        expect(
          style.foregroundColor?.resolve(selected),
          themeCase.$3.selectedControlForeground,
        );
        expect(style.backgroundColor?.resolve({}), Colors.transparent);
        expect(style.foregroundColor?.resolve({}), themeCase.$3.textMuted);
      },
    );

    testWidgets('${themeCase.$1} custom typography resolves semantic colors', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: themeCase.$2,
          home: Scaffold(
            body: Builder(
              builder: (context) => Column(
                children: [
                  Text(
                    'Input',
                    key: const Key('input'),
                    style: AgonezTypography.inputNumberOf(context),
                  ),
                  Text(
                    'Clock',
                    key: const Key('clock'),
                    style: AgonezTypography.clockOf(context),
                  ),
                  Text(
                    'Eyebrow',
                    key: const Key('eyebrow'),
                    style: AgonezTypography.eyebrowOf(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(
        tester.widget<Text>(find.byKey(const Key('input'))).style?.color,
        themeCase.$3.textPrimary,
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('clock'))).style?.color,
        themeCase.$3.goldText,
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('eyebrow'))).style?.color,
        themeCase.$3.textMuted,
      );
    });
  }
}
