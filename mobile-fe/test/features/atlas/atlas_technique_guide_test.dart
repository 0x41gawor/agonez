import 'package:agonez/src/api/json_support.dart';
import 'package:agonez/src/design/design.dart';
import 'package:agonez/src/features/atlas/atlas_technique_guide.dart';
import 'package:agonez/src/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Keys in the order the API returns them: Postgres jsonb sorts object keys
/// by length, then bytewise, which scrambles the authoring order.
final JsonMap _technique = {
  'grip': '',
  'tldr': {
    'focus': 'Shoulders pinned.',
    'setup': 'Seat at chest height.',
    'execution': 'Press up and in.',
    'stop_when': 'Shoulders roll forward.',
    'breathing': 'Exhale on the press.',
  },
  'stance': 'Feet flat.',
  'bracing': 'Back on the pad.',
  'overview': 'A converging machine press.',
  'eccentric': 'Return under control.',
  'concentric': 'Press forward and up.',
  'tempo_notes': 'No bouncing.',
  'end_position': 'Arms extended.',
  'safety_notes': ['Set the seat first.', 'Keep wrists stacked.'],
  'external_cues': 'Push the handles together.',
  'internal_cues': 'Squeeze the chest.',
  'hand_position': 'Thumbs wrapped.',
  'common_mistakes': ['Shrugging.', 'Bouncing.'],
  'equipment_setup': 'Incline pad.',
  'range_of_motion': 'Chest to lockout.',
  'rir_0_definition': 'Cannot reach lockout.',
  'rir_1_indicators': 'Slower mid-range.',
  'tempo_notes_note': '',
  'individualization': 'Seat height varies.',
  'plane_of_movement': 'Sagittal and transverse.',
  'starting_position': 'Handles at the chest.',
  'technical_failure': 'Path breaks down.',
  'primary_joint_actions': 'Shoulder flexion.',
};

void main() {
  test('orders sections and fields canonically, skipping empty values', () {
    final sections = orderTechnique(_technique);

    expect(sections.map((section) => section.key), [
      'tldr',
      'overview',
      'preparation',
      'execution',
      'cues',
      'effort',
      'troubleshooting',
      'additional',
    ]);
    List<String> keys(String section) => sections
        .singleWhere((item) => item.key == section)
        .entries
        .map((entry) => entry.key)
        .toList();

    expect(keys('tldr'), [
      'setup',
      'execution',
      'focus',
      'stop_when',
      'breathing',
    ]);
    expect(keys('overview'), [
      'overview',
      'plane_of_movement',
      'primary_joint_actions',
    ]);
    // The empty grip is dropped.
    expect(keys('preparation'), [
      'equipment_setup',
      'starting_position',
      'stance',
      'bracing',
    ]);
    expect(keys('execution'), [
      'concentric',
      'eccentric',
      'end_position',
      'range_of_motion',
      'tempo_notes',
    ]);
    expect(keys('cues'), ['internal_cues', 'external_cues']);
    expect(keys('effort'), [
      'technical_failure',
      'rir_1_indicators',
      'rir_0_definition',
    ]);
    expect(keys('troubleshooting'), [
      'common_mistakes',
      'safety_notes',
      'individualization',
    ]);
    // Unknown but filled keys survive; the empty stray key does not.
    expect(keys('additional'), ['hand_position']);
  });

  test('drops sections without content', () {
    expect(orderTechnique(const {}), isEmpty);
    expect(
      orderTechnique(const {
        'grip': ' ',
        'common_mistakes': <Object?>[],
        'tldr': <String, Object?>{},
      }),
      isEmpty,
    );
  });

  testWidgets('renders the guide top to bottom in canonical order', (
    tester,
  ) async {
    await _pump(tester, const Locale('en'));

    final headings = [
      'TL;DR',
      'Movement overview',
      'Preparation',
      'The repetition',
      'Coaching cues',
      'Effort and failure',
      'Troubleshooting',
      'Additional notes',
    ];
    final tops = [for (final text in headings) _top(tester, text)];
    expect(tops, orderedEquals([...tops]..sort()));
    expect(_top(tester, 'CONCENTRIC'), lessThan(_top(tester, 'ECCENTRIC')));
    expect(find.text('Shrugging.'), findsOneWidget);
    expect(find.text('Keep wrists stacked.'), findsOneWidget);
    expect(find.text('HAND POSITION'), findsOneWidget);
  });

  testWidgets('uses Polish labels', (tester) async {
    await _pump(tester, const Locale('pl'));

    expect(find.text('Opis ruchu'), findsOneWidget);
    expect(find.text('Wysiłek i upadek'), findsOneWidget);
    expect(find.text('FAZA KONCENTRYCZNA'), findsOneWidget);
  });

  testWidgets('explains an exercise without technique', (tester) async {
    await tester.pumpWidget(_host(const Locale('en'), const {}));

    expect(
      find.textContaining('have not been authored for this exercise yet'),
      findsOneWidget,
    );
  });
}

double _top(WidgetTester tester, String text) =>
    tester.getTopLeft(find.text(text)).dy;

Future<void> _pump(WidgetTester tester, Locale locale) async {
  await tester.binding.setSurfaceSize(const Size(430, 6000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(_host(locale, _technique));
}

Widget _host(Locale locale, JsonMap technique) => MaterialApp(
  theme: AgonezTheme.light,
  locale: locale,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: SingleChildScrollView(
      child: AtlasTechniqueGuide(technique: technique),
    ),
  ),
);
