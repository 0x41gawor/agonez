import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../api/context_models.dart';
import '../../api/prescription_models.dart';
import '../../api/wire_enums.dart';
import '../../api/workout_models.dart';
import '../../app/app_providers.dart';
import '../../data/mobile_repository.dart';
import '../../design/design.dart';
import '../../errors/user_error_mapper.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/hold_to_confirm.dart';
import 'exercise_summary.dart';
import 'microcycle_strip.dart';
import 'workout_unit_picker.dart';

/// What can be trained today: the active or expected session with its start
/// button and the picker for other workout-units.
///
/// Home and the Workout tab both embed it and share [mobileContextProvider],
/// so they always offer the same session.
class TodayOverview extends ConsumerStatefulWidget {
  const TodayOverview({this.showRunOverview = true, super.key});

  /// Whether to follow the session with where the plan run stands: the
  /// microcycle strip, recent workouts and the desktop hint. The Workout tab
  /// leaves them to Home.
  final bool showRunOverview;

  @override
  ConsumerState<TodayOverview> createState() => _TodayOverviewState();
}

/// Reloads the context behind [TodayOverview], for pull-to-refresh. It never
/// throws: a failed load shows in the overview with its own retry.
Future<void> refreshTodayOverview(WidgetRef ref, BuildContext context) async {
  final provider = mobileContextProvider(
    Localizations.localeOf(context).languageCode,
  );
  ref.invalidate(provider);
  try {
    await ref.read(provider.future);
  } on Object {
    // Shown by the overview's error state.
  }
}

class _TodayOverviewState extends ConsumerState<TodayOverview> {
  int? _startingSession;
  bool _claiming = false;

  /// The launch this overview began; see [workoutLaunchProvider].
  WorkoutLaunch? _launch;

  void _beginLaunch() {
    final launch = ref.read(workoutLaunchProvider.notifier)..begin();
    _launch = launch;
  }

  void _endLaunch() {
    _launch?.end();
    _launch = null;
  }

  @override
  void dispose() {
    // Opening the workout replaces the screens around this overview. They
    // keep their pre-start look through their exit transition, and the
    // launch ends only now that they are gone.
    final launch = _launch;
    if (launch != null) scheduleMicrotask(launch.end);
    super.dispose();
  }

  /// Waits until the workout screen can draw [workoutId] on its first frame,
  /// as it does on resume: the active-workout stream reports the workout and
  /// its exercises and sets are loaded. Opened earlier, the screen shows a
  /// loading spinner for a few frames. After two seconds, or on a failure the
  /// screen reports itself, the workout opens anyway.
  ///
  /// The providers are listened to rather than read: Riverpod pauses a
  /// provider nobody listens to, and a paused stream never delivers.
  Future<void> _untilShowable(
    ProviderContainer container,
    String workoutId,
  ) async {
    final subscriptions = <ProviderSubscription<Object?>>[];
    Future<void> until<T>(
      ProviderListenable<AsyncValue<T>> provider,
      bool Function(AsyncValue<T> value) ready,
    ) {
      final done = Completer<void>();
      subscriptions.add(
        container.listen<AsyncValue<T>>(provider, (_, next) {
          if (ready(next) && !done.isCompleted) done.complete();
        }, fireImmediately: true),
      );
      return done.future;
    }

    try {
      await Future.wait([
        until(
          activeWorkoutProvider,
          (value) => value.value?.workoutId == workoutId,
        ),
        until(
          workoutExercisesProvider(workoutId),
          (value) => value.hasValue || value.hasError,
        ),
        until(
          workoutSetsProvider(workoutId),
          (value) => value.hasValue || value.hasError,
        ),
      ]).timeout(const Duration(seconds: 2));
    } on TimeoutException {
      // Open it anyway.
    } finally {
      for (final subscription in subscriptions) {
        subscription.close();
      }
    }
  }

  Future<void> _startWorkout(SessionSummary session) async {
    if (_startingSession != null) return;
    setState(() => _startingSession = session.sessionId);
    final strings = AppLocalizations.of(context);
    final router = GoRouter.of(context);
    final container = ProviderScope.containerOf(context, listen: false);
    _beginLaunch();
    try {
      final runtime = ref.read(appRuntimeProvider);
      final start = await _prescriptionToStart(session);
      final selected = await runtime.mobileRepository.selectedPlanRunId();
      final workoutId = await runtime.workoutRepository.start(
        prescription: start.prescription,
        planRunId: selected,
        allowMissingLoads: start.allowMissingLoads,
      );
      await _untilShowable(container, workoutId);
      // The button keeps its progress while this screen leaves.
      router.go('/focus');
    } on Object catch (error) {
      _endLaunch();
      if (!mounted) return;
      setState(() => _startingSession = null);
      _showError(userFacingError(error, strings));
    }
  }

  Future<void> _openPicker(MobileContext value) async {
    final runtime = ref.read(appRuntimeProvider);
    final router = GoRouter.of(context);
    final expected = value.expectedSession;
    final started = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => WorkoutUnitPickerSheet(
        units: pickerUnits(value),
        enableHaptics: runtime.settings.hapticsEnabled,
        onStartToday: () {
          Navigator.pop(sheetContext);
          if (expected != null) unawaited(_startWorkout(expected));
        },
        startOffSchedule: (session) =>
            _startOffSchedule(session, expected: expected),
      ),
    );
    if (started == true) router.go('/focus');
  }

  /// Starts a unit other than today's. The server decides how the plan run
  /// records it and may refuse; errors propagate to the picker, which shows
  /// them and stays open.
  Future<void> _startOffSchedule(
    SessionSummary session, {
    required SessionSummary? expected,
  }) async {
    final runtime = ref.read(appRuntimeProvider);
    final container = ProviderScope.containerOf(context, listen: false);
    _beginLaunch();
    try {
      final start = await _prescriptionToStart(session);
      final workoutId = await runtime.workoutRepository.startAfterServerAccepts(
        prescription: start.prescription,
        send: runtime.api.startWorkout,
        planRunId: await runtime.mobileRepository.selectedPlanRunId(),
        allowMissingLoads: start.allowMissingLoads,
        offSchedule: OffSchedule(
          acknowledged: true,
          selectedFrom: 'picker',
          expectedSessionId: expected?.sessionId,
        ),
      );
      await _untilShowable(container, workoutId);
    } on Object {
      _endLaunch();
      rethrow;
    }
  }

  /// The prescription a start sends, and whether the server must accept it
  /// without resolved loads. A session whose prescription is not ready is
  /// first completed from plan targets on the server; the athlete then
  /// enters the loads during the workout.
  Future<({WorkoutPrescription prescription, bool allowMissingLoads})>
  _prescriptionToStart(SessionSummary session) async {
    final repository = ref.read(appRuntimeProvider).mobileRepository;
    final ready =
        session.prescription.readiness == PrescriptionReadinessStatus.ready;
    final loaded = ready
        ? await repository.loadPrescription(session.sessionId)
        : await repository.prepareFallbackPrescription(session.sessionId);
    final missingLoads = loaded.value.exercises.any(
      (exercise) => exercise.sets.any((set) => set.prescribedLoadKg == null),
    );
    return (
      prescription: loaded.value,
      allowMissingLoads: missingLoads || !ready,
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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
    final router = GoRouter.of(context);
    final container = ProviderScope.containerOf(context, listen: false);
    _beginLaunch();
    try {
      await ref
          .read(appRuntimeProvider)
          .workoutRecoveryRepository
          .claim(workoutId);
      await _untilShowable(container, workoutId);
      router.go('/focus');
    } on Object catch (error) {
      _endLaunch();
      if (!mounted) return;
      setState(() => _claiming = false);
      _showError(userFacingError(error, strings));
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = Localizations.localeOf(context).languageCode;
    final state = ref.watch(mobileContextProvider(language));
    // A reload means another plan run was selected: its session must not
    // stay startable while the new one loads. Background refreshes keep the
    // current card on screen.
    if (state.isReloading || (state.isLoading && !state.hasValue)) {
      return const TodaySkeleton();
    }
    final loaded = state.value;
    if (loaded == null) {
      return _ErrorState(
        onRetry: () => ref.invalidate(mobileContextProvider(language)),
      );
    }
    return _ContextBody(
      loaded: loaded,
      showRunOverview: widget.showRunOverview,
      startingSession: _startingSession,
      claiming: _claiming,
      onStart: _startWorkout,
      onClaim: _confirmClaim,
      onOpenPicker: _openPicker,
    );
  }
}

class _ContextBody extends StatelessWidget {
  const _ContextBody({
    required this.loaded,
    required this.showRunOverview,
    required this.startingSession,
    required this.claiming,
    required this.onStart,
    required this.onClaim,
    required this.onOpenPicker,
  });

  final LoadedValue<MobileContext> loaded;
  final bool showRunOverview;
  final int? startingSession;
  final bool claiming;
  final ValueChanged<SessionSummary> onStart;
  final ValueChanged<ActiveWorkoutSummary> onClaim;
  final ValueChanged<MobileContext> onOpenPicker;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
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
        if (value.activeWorkout == null && hasOtherWorkoutUnits(value))
          _TrainAnotherLink(onPressed: () => onOpenPicker(value)),
        if (showRunOverview) ...[
          if (value.microcycleDays.isNotEmpty) ...[
            const SizedBox(height: 24),
            MicrocycleStrip(contextValue: value),
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
      ],
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
          _ExerciseList(session: session),
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

class _TrainAnotherLink extends StatelessWidget {
  const _TrainAnotherLink({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Center(
      child: TextButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.format_list_bulleted, size: 18),
        label: Text(AppLocalizations.of(context).homeOtherWorkoutUnit),
        style: TextButton.styleFrom(
          foregroundColor: context.agonezColors.textMuted,
          minimumSize: const Size(0, AgonezSizes.minimumTouchTarget),
        ),
      ),
    ),
  );
}

/// The Today card's exercise list, read from the session's prescription.
///
/// The cached copy is used while it matches the context's prescription
/// version. Rows need only sets and reps, so they show whether or not loads
/// are resolved yet; the list is left out when the server refuses to return
/// the prescription (`prescription_missing`).
class _ExerciseList extends ConsumerStatefulWidget {
  const _ExerciseList({required this.session});

  final SessionSummary session;

  @override
  ConsumerState<_ExerciseList> createState() => _ExerciseListState();
}

class _ExerciseListState extends ConsumerState<_ExerciseList> {
  late Future<List<ExerciseSummary>?> _summaries = _load();

  @override
  void didUpdateWidget(covariant _ExerciseList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session.sessionId != widget.session.sessionId ||
        oldWidget.session.prescription.prescriptionVersion !=
            widget.session.prescription.prescriptionVersion) {
      _summaries = _load();
    }
  }

  Future<List<ExerciseSummary>?> _load() async {
    final repository = ref.read(appRuntimeProvider).mobileRepository;
    final session = widget.session;
    final version = session.prescription.prescriptionVersion;
    try {
      var loaded = await repository.loadPrescription(
        session.sessionId,
        preferCache: version != null,
      );
      if (version != null && loaded.value.prescriptionVersion != version) {
        loaded = await repository.loadPrescription(session.sessionId);
      }
      return [
        for (final exercise in loaded.value.exercises)
          ExerciseSummary.of(exercise),
      ];
    } on Object {
      // Not prescribed yet, or offline without a copy: the card's counts and
      // explanation stand on their own.
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.agonezColors;
    final textTheme = Theme.of(context).textTheme;
    return FutureBuilder<List<ExerciseSummary>?>(
      future: _summaries,
      builder: (context, snapshot) {
        final rows = snapshot.data ?? const <ExerciseSummary>[];
        return AnimatedSize(
          duration: AgonezDurations.standard,
          alignment: Alignment.topCenter,
          child: rows.isEmpty
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Column(
                    children: [
                      for (final (index, row) in rows.indexed)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          decoration: index == rows.length - 1
                              ? null
                              : BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: colors.lineSubtle,
                                    ),
                                  ),
                                ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              SizedBox(
                                width: 20,
                                child: Text(
                                  '${index + 1}',
                                  style: AgonezTypography.eyebrow.copyWith(
                                    fontSize: 11,
                                    color: colors.textDim,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  row.name,
                                  style: textTheme.bodyMedium,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                row.prescriptionLabel ??
                                    AppLocalizations.of(
                                      context,
                                    ).homeExerciseNoSets,
                                style: AgonezTypography.eyebrow.copyWith(
                                  fontSize: 12,
                                  letterSpacing: .3,
                                  color: row.prescriptionLabel == null
                                      ? colors.textDim
                                      : colors.prescriptionText,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
        );
      },
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
        style: AgonezTypography.of(context).labelSmall,
      ),
    );
  }
}

/// Placeholder in the shape of the Today card.
class TodaySkeleton extends StatelessWidget {
  const TodaySkeleton({super.key});

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
