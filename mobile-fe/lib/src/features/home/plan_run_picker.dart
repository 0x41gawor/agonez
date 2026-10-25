import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/context_models.dart';
import '../../app/app_providers.dart';
import '../../design/design.dart';
import '../../l10n/generated/app_localizations.dart';

/// The run just chosen in the plan-run sheet. Home names it in its header
/// while that run's context loads, rather than the run it is leaving.
final switchingPlanRunProvider =
    NotifierProvider<SwitchingPlanRun, PlanRunCompact?>(SwitchingPlanRun.new);

class SwitchingPlanRun extends Notifier<PlanRunCompact?> {
  @override
  PlanRunCompact? build() => null;

  void set(PlanRunCompact? run) => state = run;
}

/// Lets the athlete pick the plan run to follow, from Home's header or from
/// the card shown when no run is selected. Locked during a workout.
Future<void> choosePlanRun(
  BuildContext context,
  WidgetRef ref, {
  required int? currentRunId,
}) async {
  final container = ProviderScope.containerOf(context, listen: false);
  final runtime = container.read(appRuntimeProvider);
  if (await runtime.database.activeWorkout() != null || !context.mounted) {
    return;
  }
  // Runs come and go on desktop; the sheet keeps the last list on screen
  // while the current one loads.
  container.invalidate(planRunsProvider);
  final selected = await showModalBottomSheet<PlanRunCompact>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _PlanRunSheet(selectedId: currentRunId),
  );
  if (selected == null || selected.id == currentRunId) return;
  container.read(switchingPlanRunProvider.notifier).set(selected);
  await runtime.mobileRepository.selectPlanRun(selected.id);
  container
    ..invalidate(planRunsProvider)
    ..invalidate(mobileContextProvider, asReload: true);
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
