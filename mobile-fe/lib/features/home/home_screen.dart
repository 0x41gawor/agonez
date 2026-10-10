import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../domain/models.dart';
import '../../providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final local = ref.watch(activeWorkoutProvider).value;
    final state = ref.watch(contextProvider);
    return RefreshIndicator(
      onRefresh: () => ref.refresh(contextProvider.future),
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
            sliver: SliverList.list(
              children: [
                Row(
                  children: [
                    Image.asset('assets/logo-mark.png', width: 30),
                    const SizedBox(width: 10),
                    const Text(
                      'AGONEZ',
                      style: TextStyle(
                        letterSpacing: 3,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.expand_more),
                  ],
                ),
                const SizedBox(height: 28),
                if (local != null)
                  _Resume(local.name, () async {
                    final server = state.value?.activeWorkout;
                    final pending = await ref
                        .read(databaseProvider)
                        .pending(local.id);
                    if (server != null &&
                        server['workout_id'] == local.id &&
                        pending.isEmpty) {
                      final lease = server['lease'] as Map;
                      await (await ref.read(
                        repositoryProvider.future,
                      )).resumeServer(
                        server,
                        claimLease: lease['is_this_device'] != true,
                      );
                    }
                    if (context.mounted) context.push('/focus');
                  })
                else
                  state.when(
                    data: (data) => data.activeWorkout != null
                        ? _ServerResume(
                            summary: data.activeWorkout!,
                            onResume: () async {
                              final lease = data.activeWorkout!['lease'] as Map;
                              await (await ref.read(
                                repositoryProvider.future,
                              )).resumeServer(
                                data.activeWorkout!,
                                claimLease: lease['is_this_device'] != true,
                              );
                              ref.invalidate(activeWorkoutProvider);
                              if (context.mounted) context.push('/focus');
                            },
                          )
                        : _Today(
                            data,
                            onStart: (s) async {
                              final p = await (await ref.read(
                                apiProvider.future,
                              )).prescription(s);
                              await (await ref.read(
                                repositoryProvider.future,
                              )).start(p);
                              ref.invalidate(activeWorkoutProvider);
                              if (context.mounted) context.push('/focus');
                            },
                          ),
                    loading: () => const _Skeleton(),
                    error: (error, stack) => const _Offline(),
                  ),
                const SizedBox(height: 26),
                Text(
                  'MICROCYCLE',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: 12),
                if (state.value?.days case final days?)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: days.take(7).map((d) => _Day(d)).toList(),
                  ),
                const SizedBox(height: 30),
                Text('RECENT', style: Theme.of(context).textTheme.labelSmall),
                const SizedBox(height: 10),
                ...?state.value?.recent.map(
                  (r) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('${r['workout_unit_name']}'),
                    subtitle: Text(
                      '${r['performed_sets']} / ${r['prescribed_sets']} sets',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Today extends StatelessWidget {
  const _Today(this.data, {required this.onStart});
  final MobileContext data;
  final ValueChanged<int> onStart;
  @override
  Widget build(BuildContext context) {
    final s = data.expectedSession;
    if (s == null) return const _Offline();
    final p = s['prescription'] as Map? ?? {};
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AgonezColors.panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AgonezColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TODAY · MC${data.today?['microcycle']?['ordinal'] ?? '—'}',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 14),
          Text(
            '${s['workout_unit_name']}',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 12),
          Text(
            '● PRESCRIPTION ${p['readiness'] == 'ready' ? 'READY' : 'NOT READY'}',
            style: const TextStyle(
              color: AgonezColors.success,
              fontSize: 11,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Text('${p['exercise_count'] ?? '—'} exercises'),
              const Text('  ·  '),
              Text('${p['set_count'] ?? '—'} sets'),
              const Text('  ·  '),
              Text('${p['estimated_duration_min'] ?? '—'} min'),
            ],
          ),
          const SizedBox(height: 22),
          FilledButton(
            onPressed: p['prescription_version'] == null
                ? null
                : () => onStart(s['session_id'] as int),
            child: const Text('Start workout'),
          ),
        ],
      ),
    );
  }
}

class _Resume extends StatelessWidget {
  const _Resume(this.name, this.tap);
  final String name;
  final VoidCallback tap;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AgonezColors.panel,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AgonezColors.gold),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'WORKOUT IN PROGRESS',
          style: TextStyle(
            color: AgonezColors.gold,
            fontSize: 11,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        Text(name, style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 22),
        FilledButton(onPressed: tap, child: const Text('Resume workout')),
      ],
    ),
  );
}

class _ServerResume extends StatelessWidget {
  const _ServerResume({required this.summary, required this.onResume});
  final Json summary;
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    final lease = summary['lease'] as Map;
    final elsewhere = lease['is_this_device'] != true;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AgonezColors.panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AgonezColors.warning),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            elsewhere ? 'ACTIVE ON ANOTHER DEVICE' : 'WORKOUT IN PROGRESS',
            style: const TextStyle(
              color: AgonezColors.warning,
              fontSize: 11,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${summary['workout_unit_name']}',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 8),
          Text(
            '${(summary['counts'] as Map)['performed_sets']} sets recorded · server sequence ${summary['applied_seq']}',
            style: const TextStyle(color: AgonezColors.muted),
          ),
          const SizedBox(height: 22),
          FilledButton(
            onPressed: onResume,
            child: Text(elsewhere ? 'Resume it here' : 'Resume workout'),
          ),
          if (elsewhere)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Text(
                'This explicitly moves the write lease to this phone.',
                style: TextStyle(color: AgonezColors.muted, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();
  @override
  Widget build(BuildContext context) => Container(
    height: 230,
    decoration: BoxDecoration(
      color: AgonezColors.panel,
      borderRadius: BorderRadius.circular(18),
    ),
  );
}

class _Offline extends StatelessWidget {
  const _Offline();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      border: Border.all(color: AgonezColors.line, style: BorderStyle.solid),
      borderRadius: BorderRadius.circular(18),
    ),
    child: const Column(
      children: [
        Icon(Icons.cloud_off, color: AgonezColors.muted),
        SizedBox(height: 10),
        Text('Nothing to execute yet'),
      ],
    ),
  );
}

class _Day extends StatelessWidget {
  const _Day(this.d);
  final Json d;
  @override
  Widget build(BuildContext context) {
    final done = d['status'] == 'completed';
    return Column(
      children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done ? const Color(0x334E9C79) : AgonezColors.panel,
            border: Border.all(
              color: done ? AgonezColors.success : AgonezColors.line,
            ),
          ),
          child: done
              ? const Icon(Icons.check, size: 17)
              : Text('${d['day_ordinal']}'),
        ),
        const SizedBox(height: 6),
        Text(
          (d['date'] as String?)?.substring(8) ?? '',
          style: const TextStyle(fontSize: 11, color: AgonezColors.muted),
        ),
      ],
    );
  }
}
