import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme.dart';
import 'features/atlas/atlas_screen.dart';
import 'features/home/home_screen.dart';
import 'features/shell/app_shell.dart';
import 'features/workout/focus_screen.dart';
import 'features/workout/recorded_screen.dart';
import 'features/you/you_screen.dart';
import 'l10n/app_localizations.dart';

final _root = GlobalKey<NavigatorState>();
final _router = GoRouter(
  navigatorKey: _root,
  initialLocation: '/home',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => AppShell(shell: shell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/workout',
              builder: (context, state) => const WorkoutTab(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/atlas',
              builder: (context, state) => const AtlasScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/you',
              builder: (context, state) => const YouScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      parentNavigatorKey: _root,
      path: '/focus',
      builder: (context, state) => const FocusScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _root,
      path: '/recorded',
      builder: (context, state) {
        final data = state.extra as Map<String, Object?>? ?? const {};
        return RecordedScreen(
          workoutId: data['id'] as String? ?? '',
          workoutName: data['name'] as String? ?? 'Workout',
        );
      },
    ),
  ],
);

class AgonezApp extends ConsumerWidget {
  const AgonezApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
    title: 'Agonez',
    debugShowCheckedModeBanner: false,
    theme: agonezTheme(),
    routerConfig: _router,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
  );
}
