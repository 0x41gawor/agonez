import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../api/context_models.dart';
import '../../api/json_support.dart';
import '../../api/prescription_models.dart';
import '../../app/app_providers.dart';
import '../../design/design.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../storage/app_database.dart';
import '../../widgets/agonez_emblem.dart';
import '../../widgets/rest_countdown_text.dart';
import 'today_overview.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Future<void> _selectRun() async {
    final runtime = ref.read(appRuntimeProvider);
    if (await runtime.database.activeWorkout() != null || !mounted) return;
    final selected = await showModalBottomSheet<PlanRunCompact>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _PlanRunSheet(),
    );
    if (selected == null) return;
    await runtime.mobileRepository.selectPlanRun(selected.id);
    ref.invalidate(planRunsProvider);
    ref.invalidate(mobileContextProvider, asReload: true);
  }

  @override
  Widget build(BuildContext context) {
    final active = ref.watch(activeWorkoutProvider);
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => refreshTodayOverview(ref, context),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _Header(
                  onPlanRunPressed: active.value == null ? _selectRun : null,
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                sliver: SliverToBoxAdapter(
                  child: active.when(
                    loading: () => const TodaySkeleton(),
                    error: (_, _) => const TodayOverview(),
                    data: (workout) => workout == null
                        ? const TodayOverview()
                        : _LocalActiveCard(workout: workout),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onPlanRunPressed});

  final VoidCallback? onPlanRunPressed;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 12, 8),
      child: Row(
        children: [
          const AgonezEmblem(),
          const SizedBox(width: 10),
          Text(strings.appName, style: Theme.of(context).textTheme.titleLarge),
          const Spacer(),
          Semantics(
            button: true,
            label: strings.runSheetTitle,
            child: IconButton(
              onPressed: onPlanRunPressed,
              tooltip: onPlanRunPressed == null
                  ? strings.runLockedDuringWorkout
                  : strings.runSheetTitle,
              icon: const Icon(Icons.layers_outlined),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocalActiveCard extends ConsumerWidget {
  const _LocalActiveCard({required this.workout});

  final LocalWorkout workout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
    final recordedLocally = workout.lifecycle == 'pending_finalize';
    final sets =
        ref.watch(workoutSetsProvider(workout.workoutId)).value ??
        const <LocalSet>[];
    final performed = sets.where((set) => set.status == 'performed').length;
    var total = sets.length;
    try {
      final prescription = WorkoutPrescription.fromJson(
        asJsonMap(jsonDecode(workout.prescriptionJson), 'prescription'),
      );
      total = prescription.exercises.fold(
        0,
        (sum, exercise) => sum + exercise.sets.length,
      );
    } on Object {
      // The local rows remain usable even if an old cached prescription fails
      // to decode after a development schema change.
    }
    return AgonezPanel(
      borderColor: context.agonezColors.gold,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AgonezEyebrow(
            recordedLocally
                ? strings.recordedTitle(workout.workoutUnitName)
                : strings.homeResumeTitle,
            color: context.agonezColors.gold,
          ),
          const SizedBox(height: 12),
          Text(
            workout.workoutUnitName,
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 8),
          if (recordedLocally)
            Text(strings.recordedSavedLocally)
          else
            Text(
              strings.homeResumeStartedAt(
                DateFormat.Hm(
                  Localizations.localeOf(context).languageCode,
                ).format(workout.startedAt.toLocal()),
              ),
            ),
          const SizedBox(height: 6),
          Text(strings.homeResumeSetsTotal(performed, total)),
          if (workout.restEndsAt != null) ...[
            const SizedBox(height: 8),
            RestCountdownText(endsAt: workout.restEndsAt),
          ],
          const SizedBox(height: 20),
          AgonezPrimaryButton(
            label: recordedLocally
                ? strings.commonDone
                : strings.homeResumeWorkout,
            onPressed: () => recordedLocally
                ? context.go('/recorded/${workout.workoutId}')
                : context.go('/focus'),
            icon: Icon(
              recordedLocally
                  ? Icons.cloud_upload_outlined
                  : Icons.arrow_forward_rounded,
            ),
          ),
          if (!recordedLocally) ...[
            const SizedBox(height: 10),
            Text(
              strings.homeSingleActiveInfo,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _PlanRunSheet extends ConsumerWidget {
  const _PlanRunSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: AgonezInsets.sheetBody,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AgonezSheetHandle(),
            Text(
              strings.runSheetTitle,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            ref
                .watch(planRunsProvider)
                .when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(28),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, _) => Text(strings.errorNetworkUnavailable),
                  data: (runs) => Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        for (final run in runs)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(run.name),
                            subtitle: Text('${run.startsOn} — ${run.endsOn}'),
                            trailing: AgonezTag(
                              label: run.status == 'active'
                                  ? strings.runActive
                                  : strings.runCompleted,
                            ),
                            onTap: () => Navigator.pop(context, run),
                          ),
                        const SizedBox(height: 8),
                        Text(
                          strings.runRememberedHint,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
