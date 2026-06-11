import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class HarfiDarApp extends ConsumerWidget {
  const HarfiDarApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      // ── Identity ──────────────────────────────────────────────────────────
      title: 'حرفي دار',
      debugShowCheckedModeBanner: false,

      // ── Router ────────────────────────────────────────────────────────────
      routerConfig: router,

      // ── Theme ─────────────────────────────────────────────────────────────
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,

      // ── Localization ──────────────────────────────────────────────────────
      supportedLocales: const [
        Locale('ar', 'DZ'), // Arabic – Algeria (primary)
        Locale('fr', 'DZ'), // French  – Algeria
        Locale('en', 'US'), // English – fallback
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Default to Arabic so the app opens RTL
      locale: const Locale('ar', 'DZ'),

      // ── RTL ───────────────────────────────────────────────────────────────
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Theme mode provider – allows toggling light / dark at runtime
// ---------------------------------------------------------------------------

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);
