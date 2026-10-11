import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../design/design.dart';
import '../l10n/generated/app_localizations.dart';
import '../widgets/rest_countdown_text.dart';
import 'app_providers.dart';

class AgonezNavigationShell extends ConsumerWidget {
  const AgonezNavigationShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  void _select(BuildContext context, WidgetRef ref, int index) {
    final active = ref.read(activeWorkoutProvider).value;
    if (index == 1 && active != null) {
      _openWorkout(context, active.workoutId, active.lifecycle);
      return;
    }
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  void _openWorkout(BuildContext context, String workoutId, String lifecycle) {
    context.go(
      lifecycle == 'pending_finalize' ? '/recorded/$workoutId' : '/focus',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
    final active = ref.watch(activeWorkoutProvider).value;
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (active != null)
            _MiniWorkoutBar(
              name: active.workoutUnitName,
              syncState: active.syncState,
              restEndsAt: active.restEndsAt,
              onTap: () =>
                  _openWorkout(context, active.workoutId, active.lifecycle),
            ),
          NavigationBar(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: (index) => _select(context, ref, index),
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(Icons.home_rounded),
                label: strings.navHome,
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: active != null,
                  smallSize: 6,
                  child: const Icon(Icons.fitness_center_outlined),
                ),
                selectedIcon: const Icon(Icons.fitness_center_rounded),
                label: strings.navWorkout,
              ),
              NavigationDestination(
                icon: const Icon(Icons.menu_book_outlined),
                selectedIcon: const Icon(Icons.menu_book_rounded),
                label: strings.navAtlas,
              ),
              NavigationDestination(
                icon: const Icon(Icons.person_outline_rounded),
                selectedIcon: const Icon(Icons.person_rounded),
                label: strings.navYou,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniWorkoutBar extends StatelessWidget {
  const _MiniWorkoutBar({
    required this.name,
    required this.syncState,
    required this.restEndsAt,
    required this.onTap,
  });

  final String name;
  final String syncState;
  final DateTime? restEndsAt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final (label, color) = switch (syncState) {
      'offline' => (strings.syncOfflineTitle, context.agonezColors.caution),
      'failed' ||
      'conflict' ||
      'recovery_required' => (strings.syncFailed, context.agonezColors.error),
      'saving' => (strings.syncSaving, context.agonezColors.textMuted),
      _ => (strings.syncSaved, context.agonezColors.success),
    };
    return Material(
      color: context.agonezColors.raised,
      child: InkWell(
        onTap: onTap,
        child: Semantics(
          button: true,
          label: '${strings.homeResumeWorkout}, $name',
          child: SizedBox(
            height: AgonezSizes.miniWorkoutBarHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(
                    Icons.fitness_center_rounded,
                    color: context.agonezColors.gold,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (restEndsAt != null)
                          RestCountdownText(endsAt: restEndsAt, compact: true),
                      ],
                    ),
                  ),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: AgonezTypography.monoSmall.copyWith(color: color),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.expand_less_rounded),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
