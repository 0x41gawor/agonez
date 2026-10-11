import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/atlas/atlas_screen.dart';
import '../features/home/home_screen.dart';
import '../features/workout/workout.dart';
import '../features/workout/workout_tab_screen.dart';
import '../features/you/you_screen.dart';
import '../l10n/generated/app_localizations.dart';
import 'navigation_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'agonez-root');

GoRouter createAppRouter() => GoRouter(
  initialLocation: '/home',
  navigatorKey: _rootNavigatorKey,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AgonezNavigationShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: HomeScreen()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/workout',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: WorkoutTabScreen()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/atlas',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: AtlasScreen()),
              routes: [
                GoRoute(
                  path: 'article/:slug',
                  builder: (context, state) => AtlasScreen(
                    initialSlug: state.pathParameters['slug'],
                    initialExerciseId: int.tryParse(
                      state.uri.queryParameters['exercise_id'] ?? '',
                    ),
                    initialTitle: state.uri.queryParameters['title'],
                  ),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/you',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: YouScreen()),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/focus',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ActiveWorkoutFocusScreen(),
    ),
    GoRoute(
      path: '/recorded/:workoutId',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) =>
          WorkoutRecordedScreen(workoutId: state.pathParameters['workoutId']!),
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: SafeArea(
      child: Center(
        child: IconButton(
          tooltip: AppLocalizations.of(context).navHome,
          onPressed: () => context.go('/home'),
          icon: const Icon(Icons.home_outlined),
        ),
      ),
    ),
  ),
);
