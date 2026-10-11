import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../api/context_models.dart';
import '../../api/json_support.dart';
import '../../api/prescription_models.dart';
import '../../api/wire_enums.dart';
import '../../app/app_providers.dart';
import '../../data/mobile_repository.dart';
import '../../design/design.dart';
import '../../errors/user_error_mapper.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../storage/app_database.dart';
import '../../widgets/hold_to_confirm.dart';
import '../../widgets/rest_countdown_text.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late Future<LoadedValue<MobileContext>> _context;
  StreamSubscription<int>? _contextRefreshSubscription;
  int? _startingSession;
  bool _claiming = false;
  String? _loadedLanguage;

  @override
  void initState() {
    super.initState();
    _context = _loadContext();
    _contextRefreshSubscription = ref
        .read(appRuntimeProvider)
        .contextRefreshes
        .stream
        .listen((_) {
          if (mounted) unawaited(_refresh());
        });
  }

  @override
  void dispose() {
    unawaited(_contextRefreshSubscription?.cancel());
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final language = Localizations.localeOf(context).languageCode;
    if (_loadedLanguage != null && _loadedLanguage != language) {
      scheduleMicrotask(_refresh);
    }
    _loadedLanguage = language;
  }

  Future<LoadedValue<MobileContext>> _loadContext() async {
    final runtime = ref.read(appRuntimeProvider);
    final selected = await runtime.mobileRepository.selectedPlanRunId();
    return runtime.mobileRepository.loadContext(
      planRunId: selected,
      locale: runtime.settings.locale.languageCode,
    );
  }

  Future<void> _refresh() async {
    final next = _loadContext();
    setState(() => _context = next);
    await next;
  }

  Future<void> _startWorkout(SessionSummary session) async {
    if (_startingSession != null) return;
    setState(() => _startingSession = session.sessionId);
    final strings = AppLocalizations.of(context);
    try {
      final runtime = ref.read(appRuntimeProvider);
      final loaded = await runtime.mobileRepository.loadPrescription(
        session.sessionId,
      );
      final selected = await runtime.mobileRepository.selectedPlanRunId();
      final missingLoads = loaded.value.exercises.any(
        (exercise) => exercise.sets.any((set) => set.prescribedLoadKg == null),
      );
      await runtime.workoutRepository.start(
        prescription: loaded.value,
        planRunId: selected,
        allowMissingLoads:
            missingLoads ||
            session.prescription.readiness ==
                PrescriptionReadinessStatus.missing,
      );
      if (!mounted) return;
      context.go('/focus');
    } on Object catch (error) {
      if (!mounted) return;
      _showError(userFacingError(error, strings));
    } finally {
      if (mounted) setState(() => _startingSession = null);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

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
    await _refresh();
  }

  Future<void> _confirmClaim(ActiveWorkoutSummary active) async {
    final strings = AppLocalizations.of(context);
    await showModalBottomSheet<void>(
      context: context,
      isDismissible: !_claiming,
      enableDrag: !_claiming,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: AgonezInsets.sheetBody,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AgonezSheetHandle(),
              Text(
                strings.homeActiveElsewhereTitle,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(strings.syncSupersededExplanation),
              const SizedBox(height: 20),
              HoldToConfirm(
                label: strings.syncResumeHere,
                duration: const Duration(milliseconds: 1200),
                durationLabel: strings.deviationHoldDuration('1.2'),
                onConfirmed: () {
                  Navigator.pop(sheetContext);
                  unawaited(_claim(active.workoutId));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _claim(String workoutId) async {
    if (_claiming) return;
    setState(() => _claiming = true);
    final strings = AppLocalizations.of(context);
    try {
      await ref
          .read(appRuntimeProvider)
          .workoutRecoveryRepository
          .claim(workoutId);
      if (mounted) context.go('/focus');
    } on Object catch (error) {
      if (mounted) _showError(userFacingError(error, strings));
    } finally {
      if (mounted) setState(() => _claiming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = ref.watch(activeWorkoutProvider);
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
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
                    loading: () => const _LoadingHome(),
                    error: (_, _) => _ContextBody(
                      future: _context,
                      startingSession: _startingSession,
                      claiming: _claiming,
                      onStart: _startWorkout,
                      onClaim: _confirmClaim,
                      onRetry: _refresh,
                    ),
                    data: (workout) {
                      if (workout != null) {
                        return _LocalActiveCard(workout: workout);
                      }
                      return _ContextBody(
                        future: _context,
                        startingSession: _startingSession,
                        claiming: _claiming,
                        onStart: _startWorkout,
                        onClaim: _confirmClaim,
                        onRetry: _refresh,
                      );
                    },
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
          Image.asset('assets/brand/agonez-mark.png', width: 34, height: 34),
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

class _ContextBody extends StatelessWidget {
  const _ContextBody({
    required this.future,
    required this.startingSession,
    required this.claiming,
    required this.onStart,
    required this.onClaim,
    required this.onRetry,
  });

  final Future<LoadedValue<MobileContext>> future;
  final int? startingSession;
  final bool claiming;
  final ValueChanged<SessionSummary> onStart;
  final ValueChanged<ActiveWorkoutSummary> onClaim;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return FutureBuilder<LoadedValue<MobileContext>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _LoadingHome();
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return _ErrorState(onRetry: onRetry);
        }
        final loaded = snapshot.data!;
        final value = loaded.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (loaded.offline)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AgonezTag(
                  label: strings.syncOfflineTitle,
                  color: context.agonezColors.caution,
                  icon: const Icon(Icons.cloud_off_outlined, size: 13),
                ),
              ),
            if (value.activeWorkout != null)
              _ServerActiveCard(
                active: value.activeWorkout!,
                busy: claiming,
                onClaim: () => onClaim(value.activeWorkout!),
              )
            else if (value.expectedSession != null)
              _TodayCard(
                session: value.expectedSession!,
                busy: startingSession == value.expectedSession!.sessionId,
                onStart: () => onStart(value.expectedSession!),
              )
            else
              _EmptyToday(contextValue: value),
            if (value.alternatives.isNotEmpty) ...[
              const SizedBox(height: 22),
              AgonezEyebrow(strings.homeOtherWorkoutUnit),
              const SizedBox(height: 8),
              for (final item in value.alternatives)
                _AlternativeRow(session: item),
            ],
            if (value.microcycleDays.isNotEmpty) ...[
              const SizedBox(height: 24),
              _MicrocycleStrip(contextValue: value),
            ],
            if (value.recent.isNotEmpty) ...[
              const SizedBox(height: 24),
              AgonezEyebrow(strings.homeRecent),
              const SizedBox(height: 8),
              for (final item in value.recent) _RecentRow(item: item),
            ],
            const SizedBox(height: 22),
            Text(
              strings.homeDesktopHint,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        );
      },
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({
    required this.session,
    required this.busy,
    required this.onStart,
  });

  final SessionSummary session;
  final bool busy;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final ready =
        session.prescription.readiness == PrescriptionReadinessStatus.ready;
    final canStart =
        session.prescription.readiness !=
        PrescriptionReadinessStatus.notApplicable;
    return AgonezPanel(
      borderColor: ready
          ? context.agonezColors.gold.withValues(alpha: .62)
          : context.agonezColors.line,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              AgonezEyebrow(
                strings.homeToday,
                color: context.agonezColors.gold,
              ),
              const Spacer(),
              AgonezTag(
                label: ready
                    ? strings.homePrescriptionReady
                    : strings.homePrescriptionNotReady,
                color: ready
                    ? context.agonezColors.success
                    : context.agonezColors.caution,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            session.workoutUnitName,
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 12),
          if (ready)
            Wrap(
              spacing: 14,
              children: [
                _Metric(
                  '${session.prescription.exerciseCount ?? '—'}',
                  strings.homeExercisesLabel,
                ),
                _Metric(
                  '${session.prescription.setCount ?? '—'}',
                  strings.homeSetsLabel,
                ),
                _Metric(
                  '${session.prescription.estimatedDurationMin ?? '—'}',
                  strings.homeMinutesLabel,
                ),
              ],
            )
          else
            Text(strings.homePrescriptionNotReadyExplanation),
          const SizedBox(height: 20),
          AgonezPrimaryButton(
            label: ready
                ? strings.homeStartWorkout
                : strings.homeStartWithPlanTargets,
            onPressed: canStart && !busy ? onStart : null,
            icon: busy
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.play_arrow_rounded),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.value, this.label);

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.baseline,
    textBaseline: TextBaseline.alphabetic,
    children: [
      Text(value, style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(width: 4),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
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

class _ServerActiveCard extends StatelessWidget {
  const _ServerActiveCard({
    required this.active,
    required this.busy,
    required this.onClaim,
  });

  final ActiveWorkoutSummary active;
  final bool busy;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final time = DateFormat.Hm(
      Localizations.localeOf(context).languageCode,
    ).format(active.startedAt.toLocal());
    return AgonezPanel(
      borderColor: context.agonezColors.caution,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AgonezEyebrow(
            strings.homeActiveElsewhereTitle,
            color: context.agonezColors.caution,
          ),
          const SizedBox(height: 12),
          Text(
            active.workoutUnitName,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(strings.homeActiveElsewhereBody(active.workoutUnitName, time)),
          const SizedBox(height: 18),
          AgonezPrimaryButton(
            label: strings.homeResumeHere,
            onPressed: busy ? null : onClaim,
          ),
        ],
      ),
    );
  }
}

class _EmptyToday extends StatelessWidget {
  const _EmptyToday({required this.contextValue});

  final MobileContext contextValue;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final noRun =
        contextValue.planRun == null || contextValue.selectionRequired;
    return AgonezPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AgonezEyebrow(noRun ? strings.homeNoRunTitle : strings.homeRestDay),
          const SizedBox(height: 10),
          Text(
            noRun
                ? strings.homeNoRunExplanation
                : strings.homeRestDayExplanation,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

class _AlternativeRow extends StatelessWidget {
  const _AlternativeRow({required this.session});

  final SessionSummary session;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AgonezPanel(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.workoutUnitName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    strings.pickerScheduledOn(session.scheduledOn),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Tooltip(
              message: strings.pickerOffScheduleUnsupported,
              child: const Icon(Icons.lock_clock_outlined, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

class _MicrocycleStrip extends StatelessWidget {
  const _MicrocycleStrip({required this.contextValue});

  final MobileContext contextValue;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final current =
        contextValue.today?.microcycle?.ordinal ??
        contextValue.planRun?.currentMicrocycleOrdinal ??
        0;
    final total = contextValue.planRun?.microcycleCount ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AgonezEyebrow(strings.homeMicrocycle(current, total)),
        const SizedBox(height: 8),
        SizedBox(
          height: 72,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: contextValue.microcycleDays.length,
            separatorBuilder: (_, _) => const SizedBox(width: 7),
            itemBuilder: (context, index) {
              final day = contextValue.microcycleDays[index];
              final today = day.date == contextValue.today?.date;
              return Container(
                width: 62,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: today
                      ? context.agonezColors.goldSoft
                      : context.agonezColors.panel,
                  border: Border.all(
                    color: today
                        ? context.agonezColors.gold
                        : context.agonezColors.line,
                  ),
                  borderRadius: AgonezRadii.buttonBorder,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${day.dayOrdinal}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      day.workoutUnitName ?? '—',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RecentRow extends StatelessWidget {
  const _RecentRow({required this.item});

  final RecentWorkout item;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(item.workoutUnitName),
      subtitle: Text(
        strings.homeCompletedAt(
          DateFormat.MMMd(
            Localizations.localeOf(context).languageCode,
          ).add_Hm().format(item.completedAt.toLocal()),
        ),
      ),
      trailing: Text(
        '${item.performedSets}/${item.prescribedSets}',
        style: AgonezTypography.monoSmall,
      ),
    );
  }
}

class _LoadingHome extends StatelessWidget {
  const _LoadingHome();

  @override
  Widget build(BuildContext context) => AgonezPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Skeleton(width: 82, height: 11),
        const SizedBox(height: 20),
        _Skeleton(width: 190, height: 32),
        const SizedBox(height: 18),
        Row(
          children: const [
            _Skeleton(width: 72, height: 20),
            SizedBox(width: 14),
            _Skeleton(width: 72, height: 20),
          ],
        ),
        const SizedBox(height: 26),
        const _Skeleton(width: double.infinity, height: 60),
      ],
    ),
  );
}

class _Skeleton extends StatelessWidget {
  const _Skeleton({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: context.agonezColors.control.withValues(alpha: .72),
      borderRadius: AgonezRadii.controlBorder,
    ),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return AgonezPanel(
      child: Column(
        children: [
          const Icon(Icons.cloud_off_outlined, size: 34),
          const SizedBox(height: 12),
          Text(
            strings.errorGenericTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(strings.errorNetworkUnavailable, textAlign: TextAlign.center),
          const SizedBox(height: 14),
          OutlinedButton(onPressed: onRetry, child: Text(strings.commonRetry)),
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
