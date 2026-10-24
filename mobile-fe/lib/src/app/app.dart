import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../design/design.dart';
import '../l10n/generated/app_localizations.dart';
import 'app_runtime.dart';

class AgonezApp extends StatefulWidget {
  const AgonezApp({required this.runtime, required this.router, super.key});

  final AppRuntime runtime;
  final GoRouter router;

  @override
  State<AgonezApp> createState() => _AgonezAppState();
}

class _AgonezAppState extends State<AgonezApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.runtime.syncEngine.start();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      widget.runtime.syncEngine.kick();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.runtime.settings,
      builder: (context, _) => MaterialApp.router(
        title: 'Agonez',
        debugShowCheckedModeBanner: false,
        theme: AgonezTheme.light,
        darkTheme: AgonezTheme.dark,
        themeMode: widget.runtime.settings.themeMode,
        locale: widget.runtime.settings.locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: widget.router,
        builder: _withSystemUiStyle,
      ),
    );
  }
}

Widget _withSystemUiStyle(BuildContext context, Widget? child) {
  final light = Theme.of(context).brightness == Brightness.light;
  final colors = context.agonezColors;
  return AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: light ? Brightness.dark : Brightness.light,
      statusBarBrightness: light ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: colors.ground,
      systemNavigationBarDividerColor: colors.lineSubtle,
      systemNavigationBarIconBrightness: light
          ? Brightness.dark
          : Brightness.light,
    ),
    child: child ?? const SizedBox.shrink(),
  );
}

class AppStartupError extends StatelessWidget {
  const AppStartupError({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AgonezTheme.light,
    darkTheme: AgonezTheme.dark,
    themeMode: ThemeMode.system,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: _withSystemUiStyle,
    home: Builder(
      builder: (context) {
        final strings = AppLocalizations.of(context);
        final configurationError = message.contains('API_BASE_URL');
        return Scaffold(
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.settings_ethernet_rounded, size: 42),
                    const SizedBox(height: 16),
                    Text(
                      configurationError
                          ? strings.appName
                          : strings.errorGenericTitle,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      configurationError
                          ? strings.errorApiBaseUrlMissing
                          : strings.errorGenericBody,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}
