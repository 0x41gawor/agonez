import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';

/// Keeps Home's context current while the app stays in memory.
///
/// Home loads "today" once and otherwise reloads only after a workout is
/// finalized or on pull-to-refresh. A phone left on Home overnight would
/// show yesterday and offer yesterday's session; a prescription analyzed on
/// desktop would not appear; an offline copy would stay after the network
/// returns. This asks for a reload when the app comes back to the
/// foreground, when the local day changes while it is open, and when a
/// connection appears. Reloads are cheap: the context is fetched with its
/// ETag, and a Home that is not on screen defers the reload until it is.
class ContextFreshness with WidgetsBindingObserver {
  ContextFreshness({
    required this.refresh,
    Stream<List<ConnectivityResult>>? connectivity,
    DateTime Function()? now,
  }) : _connectivity = connectivity,
       _now = now ?? DateTime.now;

  final VoidCallback refresh;
  final Stream<List<ConnectivityResult>>? _connectivity;
  final DateTime Function() _now;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _dayChange;

  void start() {
    WidgetsBinding.instance.addObserver(this);
    _connectivitySubscription = _connectivity?.listen((results) {
      if (results.any((result) => result != ConnectivityResult.none)) {
        refresh();
      }
    });
    _armDayChange();
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_connectivitySubscription?.cancel());
    _dayChange?.cancel();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    refresh();
    // Timers do not run while the app is suspended; aim at the next
    // midnight from now.
    _armDayChange();
  }

  void _armDayChange() {
    _dayChange?.cancel();
    final now = _now();
    // A minute past midnight, so the server has turned the day as well.
    final next = DateTime(now.year, now.month, now.day + 1, 0, 1);
    _dayChange = Timer(next.difference(now), () {
      refresh();
      _armDayChange();
    });
  }
}
