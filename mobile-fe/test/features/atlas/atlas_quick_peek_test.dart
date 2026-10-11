import 'package:agonez/src/api/atlas_models.dart';
import 'package:agonez/src/data/mobile_repository.dart';
import 'package:agonez/src/design/design.dart';
import 'package:agonez/src/features/atlas/atlas_data_source.dart';
import 'package:agonez/src/features/atlas/atlas_quick_peek.dart';
import 'package:agonez/src/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders an offline embedded peek and opens the full article', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final peek = _peek();
    AtlasPeek? opened;

    await tester.pumpWidget(
      MaterialApp(
        theme: AgonezTheme.dark,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: AtlasQuickPeekSheet(
            dataSource: _FakeAtlasDataSource(peek),
            exerciseId: peek.exercise.id,
            embedded: peek,
            planNote: 'Pause on the chest.',
            onOpenFull: (value) => opened = value,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Barbell Bench Press'), findsOneWidget);
    expect(find.text('Pause on the chest.'), findsOneWidget);
    expect(find.text('Setup'), findsOneWidget);
    expect(find.textContaining('Offline'), findsOneWidget);

    await tester.tap(find.text('Open full Atlas article'));
    await tester.pump();
    expect(opened, same(peek));
  });
}

class _FakeAtlasDataSource implements AtlasDataSource {
  const _FakeAtlasDataSource(this.peek);

  final AtlasPeek peek;

  @override
  Future<LoadedValue<ExerciseDetail>> loadArticle(
    String slug, {
    bool preferCache = false,
  }) => throw UnimplementedError();

  @override
  Future<LoadedValue<AtlasPeek>> loadPeek(
    int exerciseId, {
    AtlasPeek? embedded,
  }) async =>
      LoadedValue(value: embedded ?? peek, fromCache: true, offline: true);

  @override
  Future<AtlasSearchResponse> search({String? query, int? planRunId}) =>
      throw UnimplementedError();
}

AtlasPeek _peek() => AtlasPeek(
  exercise: const ExerciseIdentity(
    id: 41,
    slug: 'barbell_bench_press',
    name: 'Barbell Bench Press',
    fullName: 'Barbell Flat Bench Press',
  ),
  tags: const ['Chest', 'Compound'],
  techniqueTldr: const TechniqueTldr(
    setup: 'Eyes under the bar and feet planted.',
    execution: 'Lower under control and press up.',
    focus: 'Keep the upper back tight.',
    stopWhen: 'Stop if shoulder position is lost.',
  ),
  musclesTop: const [
    AtlasMuscle(
      muscleId: 1,
      slug: 'pectoralis_major_sternal',
      name: 'Pectoralis major',
      etuCm2: 210,
      capacityShare: .86,
    ),
  ],
  bodyMap: BodyMap(
    asset: 'anatomy.svg',
    assetVersion: '1',
    regions: [
      BodyMapRegion(regionId: 'pectoralis_major_sternal', intensity: .9),
    ],
  ),
  contentLocale: 'en',
  atlasVersion: '1',
);
