import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_providers.dart';
import '../../design/design.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../storage/app_database.dart';
import '../home/today_overview.dart';

/// Resumes the active workout or, when none is running, offers today's
/// session and the other workout-units exactly as Home does, without Home's
/// plan run overview.
class WorkoutTabScreen extends ConsumerWidget {
  const WorkoutTabScreen({super.key});

  static const _padding = EdgeInsets.fromLTRB(20, 12, 20, 120);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
    final launching = ref.watch(workoutLaunchProvider);
    return Scaffold(
      appBar: AppBar(title: Text(strings.navWorkout)),
      body: ref
          .watch(activeWorkoutProvider)
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => const _Today(padding: _padding),
            data: (workout) => workout == null || launching
                ? const _Today(padding: _padding)
                : Padding(
                    padding: _padding,
                    child: _ResumeCard(workout: workout),
                  ),
          ),
    );
  }
}

class _Today extends ConsumerWidget {
  const _Today({required this.padding});

  final EdgeInsets padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) => RefreshIndicator(
    onRefresh: () => refreshTodayOverview(ref, context),
    child: ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: padding,
      children: const [TodayOverview(showRunOverview: false)],
    ),
  );
}

class _ResumeCard extends StatelessWidget {
  const _ResumeCard({required this.workout});

  final LocalWorkout workout;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final recorded = workout.lifecycle == 'pending_finalize';
    return AgonezPanel(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AgonezEyebrow(
            recorded
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
            label: recorded ? strings.commonDone : strings.homeResumeWorkout,
            onPressed: () => context.go(
              recorded ? '/recorded/${workout.workoutId}' : '/focus',
            ),
          ),
        ],
      ),
    );
  }
}
