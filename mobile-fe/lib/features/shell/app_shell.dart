import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../providers.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.shell});
  final StatefulNavigationShell shell;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(syncProvider).whenData((engine) => engine.synchronize());
    final active = ref.watch(activeWorkoutProvider).value;
    return Scaffold(
      body: Column(
        children: [
          Expanded(child: shell),
          if (active != null && shell.currentIndex != 1)
            InkWell(
              onTap: () => context.push('/focus'),
              child: Container(
                height: 54,
                color: AgonezColors.raised,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Icon(Icons.fitness_center, color: AgonezColors.gold),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        active.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      active.status == 'active' ? '● SAVED' : '○ OFFLINE',
                      style: TextStyle(
                        fontSize: 11,
                        color: active.status == 'active'
                            ? AgonezColors.success
                            : AgonezColors.warning,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) {
          if (i == 1 && active != null) {
            context.push('/focus');
            return;
          }
          shell.goBranch(i, initialLocation: i == shell.currentIndex);
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: active != null,
              child: const Icon(Icons.fitness_center_outlined),
            ),
            label: 'Workout',
          ),
          const NavigationDestination(
            icon: Icon(Icons.auto_stories_outlined),
            selectedIcon: Icon(Icons.auto_stories),
            label: 'Atlas',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'You',
          ),
        ],
      ),
    );
  }
}
