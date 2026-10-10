import 'dart:convert';

import 'package:agonez/src/atlas/widgets/anatomy_heatmap.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _fixture = '''
<svg width="1500" height="1020" viewBox="0 0 1500 1020">
  <g id="anterior_deltoid" data-type="muscle" class="muscle superficial">
    <path id="front-muscle" class="region" data-view="front"
      fill="inherit" stroke="#555C60" opacity="0.91"
      style="fill:#AAAAAA;stroke:#555C60;opacity:0.91" />
    <path id="rear-muscle" class="region" data-view="rear"
      fill="inherit" stroke="#555C60" opacity="0.91" />
  </g>
  <g id="rectus_abdominis" data-type="muscle" class="muscle deep">
    <g class="nested">
      <path id="nested-front" class="region" data-view="front"
        fill="inherit" stroke="#555C60" opacity="0.34" />
    </g>
  </g>
  <g id="elbow_joint" data-type="joint" class="joint">
    <circle id="joint-front" class="joint-region" data-view="front" />
  </g>
  <path id="front-base" class="body-base" data-view="front" />
  <path id="rear-base" class="body-base" data-view="rear" />
</svg>
''';

void main() {
  group('AnatomySvgTransformer', () {
    test('crops front view, applies aliases, and removes joint overlays', () {
      final transformed = AnatomySvgTransformer.transform(
        _fixture,
        view: AnatomyBodyView.front,
        regionIntensities: const {'deltoid_anterior': 1, 'rectus_abdominis': 0},
        heatColor: const Color(0xFF2E9E78),
        baseMuscleColor: const Color(0xFF2B333C),
        outlineColor: const Color(0xFF505B66),
      );

      expect(transformed, contains('viewBox="20 15 495 990"'));
      expect(transformed, isNot(contains('width="1500"')));
      expect(transformed, isNot(contains('height="1020"')));
      expect(transformed, contains('id="front-muscle"'));
      expect(transformed, isNot(contains('id="rear-muscle"')));
      expect(transformed, contains('id="front-base"'));
      expect(transformed, isNot(contains('id="rear-base"')));
      expect(transformed, isNot(contains('id="joint-front"')));
      expect(transformed, contains('fill:#2E9E78'));
      expect(transformed, contains('fill:#2B333C'));
      expect(transformed, contains('id="nested-front"'));
      expect(transformed, contains('opacity:0.20'));
    });

    test('crops rear view and clamps invalid values', () {
      final transformed = AnatomySvgTransformer.transform(
        _fixture,
        view: AnatomyBodyView.rear,
        regionIntensities: const {'anterior_deltoid': double.infinity},
        heatColor: const Color(0xFF2E9E78),
        baseMuscleColor: const Color(0xFF2B333C),
        outlineColor: const Color(0xFF505B66),
      );

      expect(transformed, contains('viewBox="505 15 530 990"'));
      expect(transformed, contains('id="rear-muscle"'));
      expect(transformed, isNot(contains('id="front-muscle"')));
      expect(transformed, isNot(contains('id="nested-front"')));
      expect(transformed, contains('fill:#2B333C'));
    });
  });

  testWidgets('renders both canonical offline views from the bundled asset', (
    tester,
  ) async {
    final canonicalSource = await tester.runAsync(
      () => rootBundle.loadString('assets/anatomy.svg'),
    );
    expect(canonicalSource, isNotNull);
    expect(canonicalSource, contains('id="pectoralis_major_sternal"'));

    final boundaryKey = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFF0D1013),
          body: RepaintBoundary(
            key: boundaryKey,
            child: DefaultAssetBundle(
              bundle: _FixtureAssetBundle(canonicalSource!),
              child: const AnatomyHeatmap(
                height: 240,
                regionIntensities: {
                  'anterior_deltoid': 0.9,
                  'vastus_lateralis': 1,
                },
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle(const Duration(milliseconds: 50));

    expect(find.text('FRONT'), findsOneWidget);
    expect(find.text('REAR'), findsOneWidget);
    expect(find.byIcon(Icons.accessibility_new_outlined), findsNothing);
    expect(tester.takeException(), isNull);

    final boundary =
        boundaryKey.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
    final image = await tester.runAsync(boundary.toImage);
    expect(image, isNotNull);
    final pixels = await tester.runAsync(image!.toByteData);
    expect(pixels, isNotNull);
    var heatPixels = 0;
    final bytes = pixels!.buffer.asUint8List();
    for (var index = 0; index < bytes.length; index += 4) {
      final red = bytes[index];
      final green = bytes[index + 1];
      final blue = bytes[index + 2];
      if (green > red + 18 && green > blue + 8 && green > 70) {
        heatPixels++;
      }
    }
    expect(heatPixels, greaterThan(40));
  });
}

class _FixtureAssetBundle extends CachingAssetBundle {
  _FixtureAssetBundle(this.source);

  final String source;

  @override
  Future<ByteData> load(String key) {
    final bytes = Uint8List.fromList(utf8.encode(source));
    return SynchronousFuture(ByteData.sublistView(bytes));
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) {
    return SynchronousFuture(source);
  }
}
