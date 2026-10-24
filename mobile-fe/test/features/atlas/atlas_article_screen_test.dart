import 'package:agonez/src/api/atlas_models.dart';
import 'package:agonez/src/data/mobile_repository.dart';
import 'package:agonez/src/design/design.dart';
import 'package:agonez/src/features/atlas/atlas_article_screen.dart';
import 'package:agonez/src/features/atlas/atlas_data_source.dart';
import 'package:agonez/src/features/atlas/atlas_workspace_controller.dart';
import 'package:agonez/src/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _width = 412.0;

void main() {
  testWidgets('section bar shows four equal tabs in article order', (
    tester,
  ) async {
    await _pumpArticle(tester);

    expect(find.text('MUSCLES'), findsNothing);
    final labels = ['TECHNIQUE', 'VIDEO', 'ANATOMY', 'DATA'];
    for (final (index, label) in labels.indexed) {
      expect(
        tester.getCenter(find.text(label)).dx,
        closeTo(_width * (index + .5) / labels.length, 1),
      );
    }
    expect(
      tester.getSemantics(find.text('TECHNIQUE')),
      containsSemantics(isSelected: true, isButton: true),
    );
  });

  testWidgets('article runs TL;DR, videos, anatomy, data, full guide', (
    tester,
  ) async {
    await _pumpArticle(tester);

    final headings = [
      'TL;DR',
      'Demonstration videos',
      'Anatomy',
      'Data',
      'Movement overview',
    ];
    final tops = [
      for (final text in headings)
        tester.getTopLeft(find.text(text, skipOffstage: false)).dy,
    ];
    expect(tops, orderedEquals([...tops]..sort()));
  });

  testWidgets('tabs jump to their section and stay visible', (tester) async {
    await _pumpArticle(tester);
    final barBottom = tester.getBottomLeft(find.text('VIDEO')).dy;

    for (final (tab, heading) in [
      ('VIDEO', 'Demonstration videos'),
      ('DATA', 'Data'),
      ('ANATOMY', 'Anatomy'),
      ('TECHNIQUE', 'Technique'),
    ]) {
      await _tapTab(tester, tab);
      expect(_isSelected(tester, tab), isTrue, reason: tab);
      // The heading lands just under the bar, not hidden behind it.
      final top = tester.getTopLeft(find.text(heading)).dy;
      expect(top, greaterThan(barBottom), reason: heading);
      expect(top, lessThan(barBottom + 60), reason: heading);
    }
    expect(tester.getTopLeft(find.text('VIDEO')).dy, lessThan(barBottom));
    expect(find.text('Muscle ETU exposure', skipOffstage: false), findsOne);
  });

  testWidgets('TL;DR links to the full guide, which belongs to Technique', (
    tester,
  ) async {
    await _pumpArticle(tester);
    await _tapTab(tester, 'DATA');
    await _tapTab(tester, 'TECHNIQUE');

    // The link under the TL;DR precedes the guide's own heading.
    final link = find.text('Full technique guide').first;
    await tester.ensureVisible(link);
    await tester.pump();
    await tester.tap(link);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(_isSelected(tester, 'TECHNIQUE'), isTrue);
    expect(find.text('Movement overview').hitTestable(), findsOneWidget);
  });

  testWidgets('scrolling moves the highlight', (tester) async {
    await _pumpArticle(tester);

    await _tapTab(tester, 'DATA');
    // Pull the Data heading below the upper quarter of the viewport.
    await tester.drag(
      find.byType(CustomScrollView),
      const Offset(0, 300),
      warnIfMissed: false,
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(_isSelected(tester, 'ANATOMY'), isTrue);

    await tester.drag(
      find.byType(CustomScrollView),
      const Offset(0, -20000),
      warnIfMissed: false,
    );
    await tester.pump(const Duration(milliseconds: 500));
    // The full guide closes the article and belongs to Technique.
    expect(_isSelected(tester, 'TECHNIQUE'), isTrue);
  });
}

bool _isSelected(WidgetTester tester, String label) =>
    tester.widget<Text>(find.text(label)).style?.fontWeight == FontWeight.w700;

Future<void> _tapTab(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _pumpArticle(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(_width, 820));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final now = DateTime.utc(2026, 10, 24);
  await tester.pumpWidget(
    MaterialApp(
      theme: AgonezTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: AtlasArticleScreen(
          dataSource: _FakeAtlasDataSource(),
          workspace: AtlasWorkspaceEntry(
            id: 'workspace',
            pages: const [
              AtlasWorkspacePage(
                exerciseId: 0,
                slug: 'barbell_bench_press',
                title: 'Bench press',
              ),
            ],
            scrollOffset: 0,
            openedAt: now,
            updatedAt: now,
          ),
          workspaceCount: 1,
          hasActiveWorkout: false,
          onBack: () {},
          onOpenWorkspaces: () {},
          onSaveScroll: (_) {},
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

class _FakeAtlasDataSource implements AtlasDataSource {
  @override
  Future<LoadedValue<ExerciseDetail>> loadArticle(
    String slug, {
    bool preferCache = false,
  }) async => LoadedValue(value: _detail(), fromCache: false);

  @override
  Future<LoadedValue<AtlasPeek>> loadPeek(
    int exerciseId, {
    AtlasPeek? embedded,
  }) => throw UnimplementedError();

  @override
  Future<AtlasSearchResponse> search({String? query, int? planRunId}) =>
      throw UnimplementedError();
}

ExerciseDetail _detail() {
  const paragraph =
      'Keep the shoulder blades pinned and press along a steady path while '
      'the elbows stay slightly tucked under the bar.';
  return ExerciseDetail(
    slug: 'barbell_bench_press',
    name: 'Bench press',
    nameFull: 'Barbell Flat Bench Press',
    bodyPart: 'upper',
    targetCategory: 'chest',
    mechanicsTier: 'heavy_compound',
    resistanceSource: 'barbell',
    executionPattern: 'bilateral',
    loadCapacity: 100,
    systemicPropulsiveFcsaDemand: null,
    recommendedRepProfile: RecommendedRepProfile(
      highLoad: RecommendedRepRange(min: 4, max: 6),
      moderateLoad: RecommendedRepRange(min: 6, max: 10),
      lowLoad: null,
    ),
    propulsiveFcsaContributionVector: null,
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
    technique: const {
      'tldr': {
        'setup': paragraph,
        'execution': paragraph,
        'focus': paragraph,
        'stop_when': paragraph,
      },
      'overview': paragraph,
      'starting_position': paragraph,
      'concentric': paragraph,
      'eccentric': paragraph,
      'internal_cues': paragraph,
      'technical_failure': paragraph,
      'common_mistakes': [paragraph, paragraph],
    },
    comments: const {},
    videoLinks: const [
      'https://www.youtube.com/watch?v=VesHgJR14E8',
      'https://www.youtube.com/watch?v=whaV86_J6HY',
    ],
    imageUrl: null,
    engine: const ExerciseEngine(
      propulsiveFcsaContributionVector: null,
      activeTensionExposureVector: null,
      etuVector: {'pectoralis_major_sternal': 30, 'triceps_lateral_head': 20},
      muscleRecoveryCostModifierVector: null,
      jointLoadExposureVector: {'glenohumeral_joint': 1},
    ),
  );
}
