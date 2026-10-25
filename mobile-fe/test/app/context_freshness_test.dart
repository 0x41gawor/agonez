import 'dart:async';

import 'package:agonez/src/app/context_freshness.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late StreamController<List<ConnectivityResult>> connectivity;
  late int refreshes;
  late ContextFreshness freshness;

  void startAt(DateTime now) {
    freshness = ContextFreshness(
      refresh: () => refreshes++,
      connectivity: connectivity.stream,
      now: () => now,
    )..start();
  }

  setUp(() {
    connectivity = StreamController<List<ConnectivityResult>>();
    refreshes = 0;
  });
  tearDown(() => connectivity.close());

  testWidgets('coming back to the app reloads today', (tester) async {
    startAt(DateTime(2026, 10, 25, 9));

    for (final state in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    expect(refreshes, 0);

    for (final state in [
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    expect(refreshes, 1);
    freshness.dispose();
  });

  testWidgets('a returning connection reloads today', (tester) async {
    startAt(DateTime(2026, 10, 25, 9));

    connectivity.add([ConnectivityResult.none]);
    await tester.pump();
    expect(refreshes, 0);

    connectivity.add([ConnectivityResult.wifi]);
    await tester.pump();
    expect(refreshes, 1);
    freshness.dispose();
  });

  testWidgets('midnight reloads today while the app is open', (tester) async {
    startAt(DateTime(2026, 10, 25, 23, 58));

    await tester.pump(const Duration(minutes: 2));
    expect(refreshes, 0);
    // A minute past midnight, once the server has turned the day too.
    await tester.pump(const Duration(minutes: 1));
    expect(refreshes, 1);
    freshness.dispose();
  });

  testWidgets('nothing reloads once disposed', (tester) async {
    startAt(DateTime(2026, 10, 25, 23, 58));
    freshness.dispose();

    connectivity.add([ConnectivityResult.mobile]);
    await tester.pump(const Duration(minutes: 5));

    expect(refreshes, 0);
  });
}
