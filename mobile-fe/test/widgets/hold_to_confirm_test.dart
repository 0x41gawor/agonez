import 'package:agonez/src/design/design.dart';
import 'package:agonez/src/widgets/hold_to_confirm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const holdDuration = Duration(milliseconds: 600);

  Widget subject({
    required VoidCallback onConfirmed,
    bool enabled = true,
    Key? key,
  }) {
    return MaterialApp(
      theme: AgonezTheme.dark,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: HoldToConfirm(
              key: key,
              label: 'Finish anyway',
              durationLabel: 'hold 0.6 s',
              accessibilityActionLabel: 'Confirm finish',
              duration: holdDuration,
              enabled: enabled,
              enableHaptics: false,
              onConfirmed: onConfirmed,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('release before duration does not confirm', (tester) async {
    var confirmations = 0;
    await tester.pumpWidget(subject(onConfirmed: () => confirmations++));

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(HoldToConfirm)),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await gesture.up();
    await tester.pump(AgonezDurations.holdReset);

    expect(confirmations, 0);
  });

  testWidgets('continuous hold confirms exactly once', (tester) async {
    var confirmations = 0;
    await tester.pumpWidget(subject(onConfirmed: () => confirmations++));

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(HoldToConfirm)),
    );
    await tester.pump(const Duration(milliseconds: 599));
    expect(confirmations, 0);

    await tester.pump(const Duration(milliseconds: 2));
    expect(confirmations, 1);

    await tester.pump(const Duration(milliseconds: 200));
    expect(confirmations, 1);
    await gesture.up();
  });

  testWidgets('unrelated parent rebuild does not cancel active hold', (
    tester,
  ) async {
    var confirmations = 0;
    var unrelatedValue = 0;
    late StateSetter rebuildParent;

    await tester.pumpWidget(
      MaterialApp(
        theme: AgonezTheme.dark,
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              rebuildParent = setState;
              return Column(
                children: [
                  Text('$unrelatedValue'),
                  HoldToConfirm(
                    label: 'Skip exercise',
                    duration: holdDuration,
                    enableHaptics: false,
                    onConfirmed: () => confirmations++,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(HoldToConfirm)),
    );
    await tester.pump(const Duration(milliseconds: 300));
    rebuildParent(() => unrelatedValue++);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 301));

    expect(find.text('1'), findsOneWidget);
    expect(confirmations, 1);
    await gesture.up();
  });

  testWidgets('disabled control cannot begin a hold', (tester) async {
    var confirmations = 0;
    await tester.pumpWidget(
      subject(enabled: false, onConfirmed: () => confirmations++),
    );

    await tester.longPress(find.byType(HoldToConfirm));
    await tester.pump(holdDuration);

    expect(confirmations, 0);
  });
}
