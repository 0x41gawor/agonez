import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/context_models.dart';
import '../data/mobile_repository.dart';
import '../storage/app_database.dart';
import 'app_runtime.dart';

final appRuntimeProvider = Provider<AppRuntime>((ref) {
  throw StateError('AppRuntime must be supplied at the application root.');
});

final activeWorkoutProvider = StreamProvider<LocalWorkout?>((ref) {
  return ref.watch(appRuntimeProvider).database.watchActiveWorkout();
});

final workoutProvider = StreamProvider.family<LocalWorkout?, String>((
  ref,
  workoutId,
) {
  return ref.watch(appRuntimeProvider).database.watchWorkout(workoutId);
});

final workoutSetsProvider = StreamProvider.family<List<LocalSet>, String>((
  ref,
  workoutId,
) {
  return ref.watch(appRuntimeProvider).database.watchWorkoutSets(workoutId);
});

final workoutExercisesProvider =
    FutureProvider.family<List<LocalExercise>, String>((ref, workoutId) {
      return ref.watch(appRuntimeProvider).database.workoutExercises(workoutId);
    });

/// Brings a workout's exercise names into [language] when they were frozen
/// in another. The workout screen watches it, so a failure is retried the
/// next time the screen opens.
final workoutNamesProvider = FutureProvider.autoDispose
    .family<void, ({String workoutId, String language})>((ref, key) async {
      final changed = await ref
          .read(appRuntimeProvider)
          .workoutNames
          .localize(key.workoutId, key.language);
      if (changed) ref.invalidate(workoutExercisesProvider(key.workoutId));
    }, retry: (_, _) => null);

final planRunsProvider = FutureProvider<List<PlanRunCompact>>((ref) {
  return ref.watch(appRuntimeProvider).mobileRepository.listPlanRuns();
});

/// Today's position in the selected plan run, in one language.
///
/// Home and the Workout tab share it, so both show the same session and one
/// request serves both. It reloads whenever the runtime announces a context
/// change (sync, reconnect) or a screen invalidates it, for example after the
/// plan run selection changes. A failed load is not retried automatically:
/// the error state offers a retry, and the repository already falls back to
/// the cached context offline.
final mobileContextProvider =
    FutureProvider.family<LoadedValue<MobileContext>, String>((
      ref,
      languageCode,
    ) async {
      final runtime = ref.watch(appRuntimeProvider);
      final refreshes = runtime.contextRefreshes.stream.listen(
        (_) => ref.invalidateSelf(),
      );
      ref.onDispose(refreshes.cancel);
      return runtime.mobileRepository.loadSelectedContext(locale: languageCode);
    }, retry: (_, _) => null);

/// Whether a workout just started on this device is still on its way into
/// the workout screen.
///
/// Home and the Workout tab swap their start card for a resume card as soon
/// as the new workout reaches the database, which happens before the
/// workout screen has covered them. While a launch is in progress they keep
/// the start card, so the swap happens out of sight. The workout screen ends
/// the launch once its entrance is complete.
final workoutLaunchProvider = NotifierProvider<WorkoutLaunch, bool>(
  WorkoutLaunch.new,
);

class WorkoutLaunch extends Notifier<bool> {
  @override
  bool build() => false;

  void begin() => state = true;

  void end() {
    // The workout screen may end a launch from a microtask after the whole
    // provider scope has gone, as when the app or a test shuts down.
    if (ref.mounted) state = false;
  }
}
