import 'package:agonez/src/design/design.dart';
import 'package:agonez/src/features/atlas/atlas_videos.dart';
import 'package:agonez/src/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses YouTube links and drops repeats and foreign URLs', () {
    final videos = AtlasVideo.fromLinks(const [
      'https://www.youtube.com/watch?v=VesHgJR14E8',
      'https://youtu.be/whaV86_J6HY',
      'https://www.youtube.com/watch?v=VesHgJR14E8',
      'https://vimeo.com/123456',
      'https://www.youtube.com/shorts/gNBU7hmW2EU',
    ]);

    expect(videos.map((video) => video.id), [
      'VesHgJR14E8',
      'whaV86_J6HY',
      'gNBU7hmW2EU',
    ]);
    expect(
      videos.first.watchUri.toString(),
      'https://www.youtube.com/watch?v=VesHgJR14E8',
    );
  });

  testWidgets('gallery features the first video and opens the tapped one', (
    tester,
  ) async {
    final opened = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: AgonezTheme.dark,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: AtlasVideoGallery(
              videos: AtlasVideo.fromLinks(const [
                'https://www.youtube.com/watch?v=VesHgJR14E8',
                'https://www.youtube.com/watch?v=whaV86_J6HY',
                'https://www.youtube.com/watch?v=gNBU7hmW2EU',
              ]),
              onOpen: opened.add,
            ),
          ),
        ),
      ),
    );

    final cards = find.byType(AtlasVideoCard);
    expect(cards, findsNWidgets(3));
    expect(
      tester.getSize(cards.at(0)).width,
      greaterThan(tester.getSize(cards.at(1)).width * 1.8),
    );

    await tester.tap(find.bySemanticsLabel('Play video 3 of 3'));
    expect(opened, [2]);
  });

  testWidgets('gallery explains when an exercise has no videos', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AgonezTheme.dark,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: AtlasVideoGallery(videos: const [], onOpen: (_) {}),
        ),
      ),
    );

    expect(find.text('Not available yet'), findsOneWidget);
    expect(find.byType(AtlasVideoCard), findsNothing);
  });
}
