import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/context_models.dart';
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
