import 'dart:async';

import 'package:agonez/src/app/agonez_boot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _app = Directionality(
  textDirection: TextDirection.ltr,
  child: Text('App'),
);

void main() {
  testWidgets('holds the first frame until the emblem is decoded', (
    tester,
  ) async {
    var released = 0;
    await tester.pumpWidget(
      AgonezBoot(
        start: () => Completer<Widget>().future,
        onFirstFrameReady: () => released++,
      ),
    );
    expect(released, 0);

    await _decodeArtwork(tester, () => released > 0);

    expect(released, 1);
    // Same 288 dp canvas and centre as the Android 12+ splash icon.
    final emblem = find.image(const AssetImage(AgonezBootAssets.emblemInk));
    expect(tester.getSize(emblem), const Size.square(288));
    expect(tester.getCenter(emblem), const Offset(400, 300));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('uses the relief emblem in the dark theme', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    var released = false;
    await tester.pumpWidget(
      AgonezBoot(
        start: () => Completer<Widget>().future,
        onFirstFrameReady: () => released = true,
      ),
    );
    await _decodeArtwork(tester, () => released);

    expect(
      find.image(const AssetImage(AgonezBootAssets.emblemRelief)),
      findsOneWidget,
    );
    expect(
      find.image(const AssetImage(AgonezBootAssets.emblemInk)),
      findsNothing,
    );
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a quick start skips the intro and crossfades into the app', (
    tester,
  ) async {
    final start = Completer<Widget>();
    var released = false;
    await tester.pumpWidget(
      AgonezBoot(
        start: () => start.future,
        onFirstFrameReady: () => released = true,
      ),
    );
    await _decodeArtwork(tester, () => released);

    start.complete(_app);
    final elapsed = await _pumpUntilBrandGone(tester);

    expect(find.text('App'), findsOneWidget);
    // A 200 ms crossfade plus a few frames; the 620 ms intro never ran.
    expect(elapsed, lessThan(const Duration(milliseconds: 300)));
  });

  testWidgets('a slow start plays the intro, shows progress, then the app', (
    tester,
  ) async {
    final start = Completer<Widget>();
    var released = false;
    await tester.pumpWidget(
      AgonezBoot(
        start: () => start.future,
        onFirstFrameReady: () => released = true,
      ),
    );
    await _decodeArtwork(tester, () => released);
    final emblem = find.image(const AssetImage(AgonezBootAssets.emblemInk));

    // 600 ms in: the intro is running, the progress line not yet shown.
    await tester.pump(AgonezBoot.skipIntroWithin);
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.getCenter(emblem).dy, lessThan(300));
    expect(find.byKey(const ValueKey('boot-progress')), findsNothing);

    // 1000 ms in: still loading, so the progress line is shown.
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('boot-progress')), findsOneWidget);

    start.complete(_app);
    final elapsed = await _pumpUntilBrandGone(tester);

    expect(find.text('App'), findsOneWidget);
    // The intro has finished, so only the 280 ms crossfade remains.
    expect(elapsed, lessThan(const Duration(milliseconds: 380)));
  });
  testWidgets('becoming ready mid-intro does not wait for the intro', (
    tester,
  ) async {
    final start = Completer<Widget>();
    var released = false;
    await tester.pumpWidget(
      AgonezBoot(
        start: () => start.future,
        onFirstFrameReady: () => released = true,
      ),
    );
    await _decodeArtwork(tester, () => released);
    await tester.pump(AgonezBoot.skipIntroWithin);
    await tester.pump(const Duration(milliseconds: 60));

    start.complete(_app);
    final elapsed = await _pumpUntilBrandGone(tester);

    // Far less than the 560 ms of intro that remained, plus the crossfade.
    expect(elapsed, lessThan(const Duration(milliseconds: 380)));
  });
}

/// Pumps frames until the boot brand is gone and returns the elapsed time.
Future<Duration> _pumpUntilBrandGone(WidgetTester tester) async {
  const frame = Duration(milliseconds: 16);
  var elapsed = Duration.zero;
  while (find.byType(Image).evaluate().isNotEmpty &&
      elapsed < const Duration(seconds: 2)) {
    await tester.pump(frame);
    elapsed += frame;
  }
  expect(find.byType(Image), findsNothing);
  return elapsed;
}

/// Asset reads and image decoding are real I/O, outside the fake clock.
Future<void> _decodeArtwork(WidgetTester tester, bool Function() done) async {
  for (var i = 0; i < 100 && !done(); i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
  }
}
