import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_providers.dart';
import '../../design/design.dart';
import '../../l10n/generated/app_localizations.dart';

class WorkoutTabScreen extends ConsumerWidget {
  const WorkoutTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.navWorkout)),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
        child: ref
            .watch(activeWorkoutProvider)
            .when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Center(child: Text(strings.errorGenericBody)),
              data: (workout) {
                if (workout != null) {
                  return AgonezPanel(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AgonezEyebrow(
                          workout.lifecycle == 'pending_finalize'
                              ? strings.recordedTitle(workout.workoutUnitName)
                              : strings.homeResumeTitle,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          workout.workoutUnitName,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 18),
                        AgonezPrimaryButton(
                          label: workout.lifecycle == 'pending_finalize'
                              ? strings.commonDone
                              : strings.homeResumeWorkout,
                          onPressed: () => context.go(
                            workout.lifecycle == 'pending_finalize'
                                ? '/recorded/${workout.workoutId}'
                                : '/focus',
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return AgonezPanel(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.fitness_center_outlined, size: 40),
                      const SizedBox(height: 14),
                      Text(
                        strings.homeNoRunTitle,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        strings.homeRestDayExplanation,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 18),
                      OutlinedButton(
                        onPressed: () => context.go('/home'),
                        child: Text(strings.navHome),
                      ),
                    ],
                  ),
                );
              },
            ),
      ),
    );
  }
}
