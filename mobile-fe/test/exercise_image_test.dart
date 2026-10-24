import 'package:agonez/src/atlas/widgets/exercise_image.dart';
import 'package:agonez/src/design/design.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('bundles exercise previews under slug-shaped asset keys', () async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final exercises = manifest
        .listAssets()
        .where((asset) => asset.startsWith('assets/exercises/'))
        .toList();

    expect(exercises, contains(exerciseImageAsset('barbell_bench_press')));
    expect(
      exercises.where(
        (asset) =>
            !RegExp(r'^assets/exercises/[a-z0-9_]+\.webp$').hasMatch(asset),
      ),
      isEmpty,
    );
  });

  testWidgets('shows the bundled photo for a catalog slug', (tester) async {
    await tester.pumpWidget(
      _host(
        const ExerciseImage(
          slug: 'barbell_bench_press',
          semanticLabel: 'Barbell Bench Press',
          height: 240,
        ),
      ),
    );
    await _settleImage(tester, 'barbell_bench_press');

    expect(find.bySemanticsLabel('Barbell Bench Press'), findsOneWidget);
    expect(tester.getSize(find.byType(ExerciseImage)).height, 240);
  });

  testWidgets('collapses with its margin when no photo is bundled', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const ExerciseImage(
          slug: 'not_installed',
          semanticLabel: 'Missing',
          margin: EdgeInsets.only(top: 16),
        ),
      ),
    );
    await _settleImage(tester, 'not_installed');

    expect(tester.getSize(find.byType(ExerciseImage)), Size.zero);
    expect(find.bySemanticsLabel('Missing'), findsNothing);
  });
}

Widget _host(Widget child) => MaterialApp(
  theme: AgonezTheme.dark,
  home: Scaffold(body: Center(child: child)),
);

/// Asset reads and image decoding are real I/O, so they must run outside the
/// widget tester's fake clock before the frame or error can be pumped.
Future<void> _settleImage(WidgetTester tester, String slug) async {
  await tester.runAsync(
    () => precacheImage(
      AssetImage(exerciseImageAsset(slug)),
      tester.element(find.byType(ExerciseImage)),
      onError: (_, _) {},
    ),
  );
  await tester.pumpAndSettle();
}
