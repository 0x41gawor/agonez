import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_providers.dart';
import '../../design/design.dart';
import '../../l10n/generated/app_localizations.dart';

class YouScreen extends ConsumerWidget {
  const YouScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final runtime = ref.watch(appRuntimeProvider);
    return ListenableBuilder(
      listenable: runtime.settings,
      builder: (context, _) {
        final settings = runtime.settings;
        final strings = AppLocalizations.of(context);
        return Scaffold(
          appBar: AppBar(title: Text(strings.youTitle)),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
            children: [
              AgonezEyebrow(strings.youActivePlanRun),
              const SizedBox(height: 8),
              _PlanRunTile(ref: ref),
              const SizedBox(height: 24),
              AgonezEyebrow(strings.youWorkoutSettings),
              const SizedBox(height: 8),
              AgonezPanel(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _DurationTile(
                      title: strings.youDefaultRestCompounds,
                      seconds: settings.compoundRestSeconds,
                      onChanged: settings.setCompoundRestSeconds,
                    ),
                    const Divider(),
                    _DurationTile(
                      title: strings.youDefaultRestIsolation,
                      seconds: settings.accessoryRestSeconds,
                      onChanged: settings.setAccessoryRestSeconds,
                    ),
                    const Divider(),
                    SwitchListTile.adaptive(
                      title: Text(strings.youRestNotification),
                      value: settings.restNotificationsEnabled,
                      onChanged: (value) async {
                        final granted = value
                            ? await runtime.notifications.requestPermission()
                            : null;
                        await settings.setRestNotifications(
                          value && granted != false,
                        );
                      },
                    ),
                    const Divider(),
                    SwitchListTile.adaptive(
                      title: Text(strings.youSound),
                      value: settings.restSoundEnabled,
                      onChanged: settings.restNotificationsEnabled
                          ? settings.setRestSound
                          : null,
                    ),
                    const Divider(),
                    SwitchListTile.adaptive(
                      title: Text(strings.youHaptics),
                      value: settings.hapticsEnabled,
                      onChanged: settings.setHaptics,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              AgonezEyebrow(strings.youAppSettings),
              const SizedBox(height: 8),
              AgonezPanel(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    ListTile(
                      title: Text(strings.youTheme),
                      trailing: Text(strings.youThemeDark),
                    ),
                    const Divider(),
                    ListTile(
                      title: Text(strings.youUnits),
                      trailing: const Text('kg'),
                    ),
                    const Divider(),
                    ListTile(
                      title: Text(strings.youLanguage),
                      trailing: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'en', label: Text('EN')),
                          ButtonSegment(value: 'pl', label: Text('PL')),
                        ],
                        selected: {settings.locale.languageCode},
                        onSelectionChanged: (selection) {
                          settings.setLocale(Locale(selection.single));
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              AgonezEyebrow(strings.youSyncStatus),
              const SizedBox(height: 8),
              _SyncSummary(ref: ref),
            ],
          ),
        );
      },
    );
  }
}

class _DurationTile extends StatelessWidget {
  const _DurationTile({
    required this.title,
    required this.seconds,
    required this.onChanged,
  });

  final String title;
  final int seconds;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      subtitle: Slider(
        value: seconds.toDouble(),
        min: 30,
        max: 300,
        divisions: 18,
        label: _duration(seconds),
        onChanged: (value) => onChanged(value.round()),
      ),
      trailing: SizedBox(
        width: 48,
        child: Text(
          _duration(seconds),
          textAlign: TextAlign.end,
          style: AgonezTypography.monoSmall,
        ),
      ),
    );
  }

  static String _duration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainder = seconds % 60;
    return remainder == 0 ? '${minutes}m' : '${minutes}m ${remainder}s';
  }
}

class _PlanRunTile extends StatelessWidget {
  const _PlanRunTile({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return AgonezPanel(
      child: ref
          .watch(planRunsProvider)
          .when(
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => Text(strings.errorNetworkUnavailable),
            data: (runs) {
              final active = runs
                  .where((run) => run.status == 'active')
                  .firstOrNull;
              if (active == null) return Text(strings.homeNoRunExplanation);
              return Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          active.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          strings.homeMicrocycle(
                            active.currentMicrocycleOrdinal ?? 0,
                            active.microcycleCount,
                          ),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  AgonezTag(
                    label: strings.runActive,
                    color: context.agonezColors.success,
                  ),
                ],
              );
            },
          ),
    );
  }
}

class _SyncSummary extends StatelessWidget {
  const _SyncSummary({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return AgonezPanel(
      child: ref
          .watch(activeWorkoutProvider)
          .when(
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => Text(strings.syncFailed),
            data: (workout) {
              final label = switch (workout?.syncState) {
                'saving' => strings.syncSaving,
                'offline' => strings.syncOfflineTitle,
                'failed' || 'recovery_required' => strings.syncFailed,
                'conflict' => strings.syncConflict,
                'superseded' => strings.syncSuperseded,
                _ => strings.youSyncUpToDate,
              };
              final color = switch (workout?.syncState) {
                'offline' || 'superseded' => context.agonezColors.caution,
                'failed' ||
                'recovery_required' ||
                'conflict' => context.agonezColors.error,
                _ => context.agonezColors.success,
              };
              return Row(
                children: [
                  Icon(Icons.cloud_done_outlined, color: color),
                  const SizedBox(width: 12),
                  Expanded(child: Text(label)),
                ],
              );
            },
          ),
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
