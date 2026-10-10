import 'dart:async';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../data/database.dart';
import '../../domain/models.dart';
import '../../providers.dart';

class WorkoutTab extends ConsumerWidget {
  const WorkoutTab({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(activeWorkoutProvider).value;
    return Center(
      child: active == null
          ? const Text('Start today’s workout from Home')
          : FilledButton(
              onPressed: () => context.push('/focus'),
              child: const Text('Resume workout'),
            ),
    );
  }
}

class FocusScreen extends ConsumerStatefulWidget {
  const FocusScreen({super.key});
  @override
  ConsumerState<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends ConsumerState<FocusScreen> {
  int? reps, rir;
  double? load;
  Timer? timer;
  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final workout = ref.watch(activeWorkoutProvider).value;
    if (workout == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final p = Prescription.decode(workout.prescriptionJson);
    var executableIndex = workout.exerciseIndex;
    while (executableIndex < p.exercises.length &&
        (p.exercises[executableIndex]['sets'] as List).isEmpty) {
      executableIndex++;
    }
    if (executableIndex != workout.exerciseIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await (ref
                .read(databaseProvider)
                .update(ref.read(databaseProvider).localWorkouts)
              ..where((t) => t.id.equals(workout.id)))
            .write(
              LocalWorkoutsCompanion(
                exerciseIndex: Value(executableIndex),
                setIndex: const Value(0),
              ),
            );
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (executableIndex >= p.exercises.length) {
      return _Finish(workout: workout);
    }
    final ex = p.exercises[executableIndex];
    final sets = (ex['sets'] as List).cast<Json>();
    final set = sets[workout.setIndex.clamp(0, sets.length - 1)];
    load ??= (set['prescribed_load_kg'] as num?)?.toDouble();
    final left = workout.restEndsAt == null
        ? 0
        : DateTime.parse(
            workout.restEndsAt!,
          ).difference(DateTime.now().toUtc()).inSeconds;
    return PopScope(
      canPop: true,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.keyboard_arrow_down),
          ),
          title: Column(
            children: [
              Text(workout.name, style: const TextStyle(fontSize: 14)),
              Text(
                _elapsed(workout.startedAt),
                style: const TextStyle(fontSize: 11, color: AgonezColors.muted),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: _sync,
              child: Text(
                workout.status == 'active' ? '● Saved' : '○ Offline',
                style: TextStyle(
                  color: workout.status == 'active'
                      ? AgonezColors.success
                      : AgonezColors.warning,
                ),
              ),
            ),
            IconButton(
              onPressed: () => _outline(p),
              icon: const Icon(Icons.list),
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              LinearProgressIndicator(
                value:
                    (workout.exerciseIndex + (workout.setIndex / sets.length)) /
                    p.exercises.length,
                minHeight: 3,
                color: AgonezColors.gold,
                backgroundColor: AgonezColors.line,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'EXERCISE ${workout.exerciseIndex + 1} / ${p.exercises.length}  ·  SET ${workout.setIndex + 1} / ${sets.length}',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      const SizedBox(height: 10),
                      InkWell(
                        onTap: () => _peek(ex),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${(ex['exercise'] as Map)['name']}',
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineMedium,
                              ),
                            ),
                            const Icon(
                              Icons.info_outline,
                              color: AgonezColors.prescription,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        children: List.generate(
                          sets.length,
                          (i) => CircleAvatar(
                            radius: 18,
                            backgroundColor: i < workout.setIndex
                                ? const Color(0xFF27523F)
                                : i == workout.setIndex
                                ? AgonezColors.gold
                                : AgonezColors.raised,
                            foregroundColor: i == workout.setIndex
                                ? Colors.black
                                : AgonezColors.text,
                            child: Text('${i + 1}'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      if (left > 0)
                        _Rest(seconds: left)
                      else
                        _Prescription(set: set, exercise: ex),
                      const SizedBox(height: 18),
                      _Stepper(
                        label: 'LOAD · KG',
                        value:
                            load?.toStringAsFixed(load! % 1 == 0 ? 0 : 1) ??
                            '—',
                        onMinus: () => setState(
                          () => load =
                              (load ?? 0) -
                              ((ex['load_step_kg'] as num?)?.toDouble() ?? 2.5),
                        ),
                        onPlus: () => setState(
                          () => load =
                              (load ?? 0) +
                              ((ex['load_step_kg'] as num?)?.toDouble() ?? 2.5),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _Selector(
                        label: 'REPS',
                        values: List.generate(11, (i) => i + 1),
                        selected: reps,
                        target: (
                          (set['rep_min'] as int),
                          (set['rep_max'] as int),
                        ),
                        onTap: (v) => setState(() => reps = v),
                      ),
                      const SizedBox(height: 16),
                      _Selector(
                        label: 'RIR',
                        values: List.generate(6, (i) => i),
                        selected: rir,
                        target: (
                          (set['target_rir'] as int?) ?? -1,
                          (set['target_rir'] as int?) ?? -1,
                        ),
                        onTap: (v) => setState(() => rir = v),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
                decoration: const BoxDecoration(
                  color: AgonezColors.ground,
                  border: Border(top: BorderSide(color: AgonezColors.line)),
                ),
                child: FilledButton(
                  onPressed: load == null || reps == null || rir == null
                      ? null
                      : () => _confirm(workout, ex, set),
                  child: const Text('Confirm set'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirm(LocalWorkout workout, Json ex, Json set) async {
    await (await ref.read(repositoryProvider.future)).confirmSet(
      workout: workout,
      exercise: ex,
      set: set,
      load: load!,
      repetitions: reps!,
      rir: rir!,
    );
    HapticFeedback.lightImpact();
    reps = null;
    rir = null;
    load = null;
    await (await ref.read(syncProvider.future)).synchronize();
  }

  Future<void> _sync() async =>
      (await ref.read(syncProvider.future)).synchronize();
  void _peek(Json ex) => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) {
      final peek = ex['atlas_peek'] as Map? ?? {};
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${(ex['exercise'] as Map)['name']}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              if (peek['technique_tldr'] is Map) ...[
                for (final entry
                    in (peek['technique_tldr'] as Map).entries) ...[
                  Text(
                    '${entry.key}'.toUpperCase(),
                    style: const TextStyle(
                      color: AgonezColors.prescription,
                      fontSize: 10,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('${entry.value}'),
                  const SizedBox(height: 12),
                ],
              ] else
                Text(
                  '${peek['technique_tldr'] ?? ex['plan_comment'] ?? 'Technique details are available in Atlas.'}',
                ),
              const SizedBox(height: 18),
              OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.go('/atlas');
                },
                child: const Text('Open full Atlas article'),
              ),
            ],
          ),
        ),
      );
    },
  );
  void _outline(Prescription p) => showModalBottomSheet(
    context: context,
    builder: (_) => ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Workout outline', style: Theme.of(context).textTheme.titleLarge),
        ...p.exercises.map(
          (e) => ListTile(
            leading: CircleAvatar(child: Text('${e['ordinal']}')),
            title: Text('${(e['exercise'] as Map)['name']}'),
            subtitle: Text('${(e['sets'] as List).length} sets'),
          ),
        ),
      ],
    ),
  );
  static String _elapsed(String started) {
    final d = DateTime.now().toUtc().difference(DateTime.parse(started));
    return '${d.inHours.toString().padLeft(2, '0')}:${(d.inMinutes % 60).toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
  }
}

class _Prescription extends StatelessWidget {
  const _Prescription({required this.set, required this.exercise});
  final Json set, exercise;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0x0FAFC2D6),
      border: Border.all(color: const Color(0x448FA9C4)),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PRESCRIBED',
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 1.4,
            color: AgonezColors.prescription,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${set['prescribed_load_kg'] ?? '—'} kg  ·  ${set['rep_min']}–${set['rep_max']} reps  ·  RIR ${set['target_rir'] ?? '—'}',
          style: const TextStyle(
            fontSize: 19,
            color: AgonezColors.prescription,
          ),
        ),
        if (set['comment'] != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('${set['comment']}'),
          ),
      ],
    ),
  );
}

class _Rest extends StatelessWidget {
  const _Rest({required this.seconds});
  final int seconds;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AgonezColors.panel,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      children: [
        const Text(
          'REST',
          style: TextStyle(letterSpacing: 1.4, color: AgonezColors.muted),
        ),
        Text(
          '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}',
          style: const TextStyle(fontSize: 44, fontFamily: 'GeistMono'),
        ),
      ],
    ),
  );
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.label,
    required this.value,
    required this.onMinus,
    required this.onPlus,
  });
  final String label, value;
  final VoidCallback onMinus, onPlus;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.labelSmall),
      const SizedBox(height: 8),
      Row(
        children: [
          IconButton.filledTonal(
            onPressed: onMinus,
            icon: const Icon(Icons.remove),
            iconSize: 28,
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 30, fontFamily: 'GeistMono'),
            ),
          ),
          IconButton.filledTonal(
            onPressed: onPlus,
            icon: const Icon(Icons.add),
            iconSize: 28,
          ),
        ],
      ),
    ],
  );
}

class _Selector extends StatelessWidget {
  const _Selector({
    required this.label,
    required this.values,
    required this.selected,
    required this.target,
    required this.onTap,
  });
  final String label;
  final List<int> values;
  final int? selected;
  final (int, int) target;
  final ValueChanged<int> onTap;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.labelSmall),
      const SizedBox(height: 8),
      GridView.count(
        crossAxisCount: 6,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        childAspectRatio: 1.15,
        children: values.take(12).map((v) {
          final chosen = v == selected;
          final aimed = v >= target.$1 && v <= target.$2;
          return InkWell(
            onTap: () => onTap(v),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: chosen ? AgonezColors.gold : AgonezColors.raised,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: aimed ? AgonezColors.prescription : AgonezColors.line,
                  width: aimed ? 2 : 1,
                ),
              ),
              child: Text(
                '$v',
                style: TextStyle(
                  color: chosen ? Colors.black : AgonezColors.text,
                  fontSize: 18,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    ],
  );
}

class _Finish extends ConsumerWidget {
  const _Finish({required this.workout});
  final dynamic workout;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: AgonezColors.success,
              size: 64,
            ),
            const SizedBox(height: 20),
            Text(
              'Ready to finish?',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            const Text(
              'Your recorded sets will sync in order before this workout is finalised.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () async {
                await (await ref.read(
                  repositoryProvider.future,
                )).queueFinalize(workout, true);
                if (context.mounted) {
                  context.go(
                    '/recorded',
                    extra: {'id': workout.id, 'name': workout.name},
                  );
                }
                unawaited(_syncInBackground(ref));
              },
              child: const Text('Finish workout'),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> _syncInBackground(WidgetRef ref) async {
  try {
    await (await ref.read(syncProvider.future)).synchronize();
  } catch (_) {
    // SyncEngine schedules retries. Finishing remains a local-first action.
  }
}
