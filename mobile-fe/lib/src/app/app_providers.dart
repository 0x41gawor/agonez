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
      final selected = await runtime.mobileRepository.selectedPlanRunId();
      return runtime.mobileRepository.loadContext(
        planRunId: selected,
        locale: languageCode,
      );
    }, retry: (_, _) => null);
