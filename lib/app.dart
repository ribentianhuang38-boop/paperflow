import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/common/theme/app_theme.dart';
import 'src/common/routing/app_router.dart';
import 'src/common/database/app_database.dart';
import 'src/common/ai/ai_client.dart';
import 'src/features/settings/data/settings_repository.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

final settingsProvider = Provider<SettingsRepository>((ref) {
  throw UnimplementedError('Must be overridden in main()');
});

final aiClientProvider = Provider<AiClient>((ref) {
  final settings = ref.watch(settingsProvider);
  return AiClient(
    baseUrl: settings.apiBaseUrl,
    apiKey: settings.apiKey,
    model: settings.modelName,
  );
});

final themeModeProvider = Provider<ThemeMode>((ref) {
  final settings = ref.watch(settingsProvider);
  switch (settings.themeMode) {
    case 'dark':
      return ThemeMode.dark;
    case 'light':
      return ThemeMode.light;
    default:
      return ThemeMode.system;
  }
});

final localeProvider = Provider<Locale>((ref) {
  final settings = ref.watch(settingsProvider);
  return Locale(settings.locale);
});

class PaperFlowApp extends ConsumerWidget {
  const PaperFlowApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'PaperFlow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: themeMode,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('zh'),
      ],
      routerConfig: router,
    );
  }
}
