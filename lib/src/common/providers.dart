import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../common/database/app_database.dart';
import '../common/ai/ai_client.dart';
import '../features/settings/data/settings_repository.dart';
import '../features/library/data/document_repository.dart';
import '../features/dictionary/data/vocabulary_dao.dart';
import '../features/active_recall/data/recall_session_dao.dart';
import '../features/reading_mastery/data/mastery_dao.dart';
import '../features/reader/data/reading_position_dao.dart';

final databaseProvider = FutureProvider<AppDatabase>((ref) async {
  return AppDatabase.getInstance();
});

final settingsProvider = Provider<SettingsRepository>((ref) {
  throw UnimplementedError('Must be overridden in main()');
});

final documentRepositoryProvider = FutureProvider<DocumentRepository>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return DocumentRepository(db);
});

final vocabularyDaoProvider = FutureProvider<VocabularyDao>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return VocabularyDao(db);
});

final recallSessionDaoProvider = FutureProvider<RecallSessionDao>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return RecallSessionDao(db);
});

final masteryDaoProvider = FutureProvider<MasteryDao>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return MasteryDao(db);
});

final readingPositionDaoProvider = FutureProvider<ReadingPositionDao>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return ReadingPositionDao(db);
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
    case 'dark': return ThemeMode.dark;
    case 'light': return ThemeMode.light;
    default: return ThemeMode.system;
  }
});

final localeProvider = Provider<Locale>((ref) {
  final settings = ref.watch(settingsProvider);
  return Locale(settings.locale);
});
