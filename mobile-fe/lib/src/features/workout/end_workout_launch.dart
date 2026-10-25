import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_providers.dart';

/// Wraps the workout screen: ends the [workoutLaunchProvider] launch once
/// the screen has animated in over the screen that started it, or when its
/// route goes away before that.
///
/// When the workout screen instead replaces the starting screen, as
/// `go('/focus')` does, it appears without an entrance of its own while the
/// starting screen animates out. The starting screen then ends the launch
/// itself once it is gone.
class EndWorkoutLaunchWhenShown extends ConsumerStatefulWidget {
  const EndWorkoutLaunchWhenShown({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<EndWorkoutLaunchWhenShown> createState() =>
      _EndWorkoutLaunchWhenShownState();
}

class _EndWorkoutLaunchWhenShownState
    extends ConsumerState<EndWorkoutLaunchWhenShown> {
  late final WorkoutLaunch _launch;
  Animation<double>? _entrance;

  @override
  void initState() {
    super.initState();
    _launch = ref.read(workoutLaunchProvider.notifier);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final entrance = ModalRoute.of(context)?.animation;
    if (entrance == _entrance) return;
    _entrance?.removeStatusListener(_onEntranceStatus);
    _entrance = entrance;
    if (entrance != null && !entrance.isCompleted) {
      entrance.addStatusListener(_onEntranceStatus);
    }
  }

  void _onEntranceStatus(AnimationStatus status) {
    if (status.isCompleted) _launch.end();
  }

  @override
  void dispose() {
    _entrance?.removeStatusListener(_onEntranceStatus);
    scheduleMicrotask(_launch.end);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
