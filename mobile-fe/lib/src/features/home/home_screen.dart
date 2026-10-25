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
  /// The run just chosen in the sheet, named in the header while its
  /// context loads.
  PlanRunCompact? _switchingTo;

  Future<void> _selectRun(int? currentRunId) async {
    final runtime = ref.read(appRuntimeProvider);
    if (await runtime.database.activeWorkout() != null || !mounted) return;
    // Runs come and go on desktop; the sheet keeps the last list on screen
    // while the current one loads.
    ref.invalidate(planRunsProvider);
    final selected = await showModalBottomSheet<PlanRunCompact>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _PlanRunSheet(selectedId: currentRunId),
    );
    if (selected == null || selected.id == currentRunId || !mounted) return;
    setState(() => _switchingTo = selected);
    await runtime.mobileRepository.selectPlanRun(selected.id);
    ref.invalidate(planRunsProvider);
    ref.invalidate(mobileContextProvider, asReload: true);
  }

  @override
  Widget build(BuildContext context) {
    final active = ref.watch(activeWorkoutProvider);
    // A launch leaves Home as it was when the workout was started.
    final workout = ref.watch(workoutLaunchProvider) ? null : active.value;
    final shown = ref
        .watch(
          mobileContextProvider(Localizations.localeOf(context).languageCode),
        )
        .value
        ?.value;
    final switchingTo = _switchingTo;
    final switching =
        switchingTo != null && shown?.planRun?.id != switchingTo.id;
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => refreshTodayOverview(ref, context),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _Header(
                  runName: switching ? switchingTo.name : shown?.planRun?.name,
                  contextValue: switching ? null : shown,
                  onPlanRunPressed: workout == null
                      ? () => _selectRun(shown?.planRun?.id)
                      : null,
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                sliver: SliverToBoxAdapter(
                  child: active.when(
                    loading: () => const TodaySkeleton(),
                    error: (_, _) => const TodayOverview(),
                    data: (_) => workout == null
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
  const _Header({
    required this.runName,
    required this.contextValue,
    required this.onPlanRunPressed,
  });

  final String? runName;

  /// Where the run stands; null while it is unknown or loading.
  final MobileContext? contextValue;
  final VoidCallback? onPlanRunPressed;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 16, 8),
      child: Row(
        children: [
          const AgonezEmblem(),
          const SizedBox(width: 10),
          Text(strings.appName, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(width: 16),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: _RunChip(
                name: runName,
                contextValue: contextValue,
                onPressed: onPlanRunPressed,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The selected plan run and its microcycle, opening the run sheet. During a
/// workout the run cannot change, so the chip is locked.
class _RunChip extends StatelessWidget {
  const _RunChip({
    required this.name,
    required this.contextValue,
    required this.onPressed,
  });

  final String? name;
  final MobileContext? contextValue;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final colors = context.agonezColors;
    final run = contextValue?.planRun;
    final current =
        contextValue?.today?.microcycle?.ordinal ??
        run?.currentMicrocycleOrdinal;
    final total = run?.microcycleCount;
    final hasPosition = current != null && total != null && total > 0;
    final locked = onPressed == null;
    return Tooltip(
      message: locked ? strings.runLockedDuringWorkout : strings.runSheetTitle,
      child: Semantics(
        button: true,
        enabled: !locked,
        label: [
          strings.runSheetTitle,
          ?name,
          if (hasPosition) strings.homeMicrocycle(current, total),
        ].join(', '),
        excludeSemantics: true,
        child: OutlinedButton(
          key: const Key('home-plan-run'),
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 36),
            padding: const EdgeInsets.fromLTRB(12, 0, 8, 0),
            tapTargetSize: MaterialTapTargetSize.padded,
            foregroundColor: colors.textSecondary,
            side: BorderSide(color: colors.line),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  name ?? strings.runSheetTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    color: locked ? colors.textMuted : colors.textSecondary,
                  ),
                ),
              ),
              if (hasPosition) ...[
                const SizedBox(width: 6),
                Text(
                  strings.runChipMicrocycle(current, total),
                  style: AgonezTypography.monoSmall.copyWith(
                    fontSize: 11,
                    color: colors.textMuted,
                  ),
                ),
              ],
              const SizedBox(width: 2),
              Icon(
                locked ? Icons.lock_outline_rounded : Icons.expand_more_rounded,
                size: 18,
                color: colors.textMuted,
              ),
            ],
          ),
        ),
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
  const _PlanRunSheet({required this.selectedId});

  /// The run Home currently shows; picking it again just closes the sheet.
  final int? selectedId;

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
                          _PlanRunRow(
                            run: run,
                            selected: run.id == selectedId,
                            onTap: () => Navigator.pop(
                              context,
                              run.id == selectedId ? null : run,
                            ),
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

/// One run in the sheet. The selected run is tinted gold and checked, as in
/// the design, so the current choice is clear before changing it.
class _PlanRunRow extends StatelessWidget {
  const _PlanRunRow({
    required this.run,
    required this.selected,
    required this.onTap,
  });

  final PlanRunCompact run;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final colors = context.agonezColors;
    return ListTile(
      selected: selected,
      selectedTileColor: colors.goldSoft,
      selectedColor: colors.goldText,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      shape: const RoundedRectangleBorder(
        borderRadius: AgonezRadii.controlBorder,
      ),
      title: Text(run.name),
      subtitle: Text(
        '${run.startsOn} — ${run.endsOn}',
        style: TextStyle(color: colors.textMuted),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (selected) ...[
            Icon(Icons.check_rounded, size: 20, color: colors.goldText),
            const SizedBox(width: 8),
          ],
          AgonezTag(
            label: run.status == 'active'
                ? strings.runActive
                : strings.runCompleted,
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}
