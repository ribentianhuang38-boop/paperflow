import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/storage/storage_service.dart';
import '../../services/network/network_service.dart';
import '../../services/ai/ai_service.dart';
import '../../services/browser/browser_service.dart';
import '../../services/parser/parser_service.dart';
import '../../services/importer/importer_service.dart';
import '../../services/dictionary/dictionary_service.dart';
import '../../services/speech/speech_service.dart';

import '../../repositories/article_repository/article_repository.dart';
import '../../repositories/vocabulary_repository/vocabulary_repository.dart';
import '../../repositories/review_repository/review_repository.dart';
import '../../repositories/history_repository/history_repository.dart';
import '../../repositories/settings_repository/settings_repository.dart';
import '../../repositories/ai_repository/ai_repository.dart';

// Storage & Service Providers
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService.getInstance();
});

final networkServiceProvider = Provider<NetworkService>((ref) {
  return NetworkService();
});

final aiServiceProvider = Provider<AiService>((ref) {
  final settings = ref.watch(settingsRepositoryProvider);
  return AiService(
    dio: ref.watch(networkServiceProvider).dio,
    backendUrl: settings.backendUrl,
    accessKey: settings.accessKey,
    model: settings.modelName,
  );
});

final browserServiceProvider = Provider<BrowserService>((ref) {
  return BrowserService();
});

final parserServiceProvider = Provider<ParserService>((ref) {
  return ParserService();
});

final speechServiceProvider = Provider<SpeechService>((ref) {
  return SpeechService();
});

final dictionaryServiceProvider = Provider<DictionaryService>((ref) {
  return DictionaryService(ref.watch(networkServiceProvider).dio);
});

final importerServiceProvider = Provider<ImporterService>((ref) {
  return ImporterService(
    parserService: ref.watch(parserServiceProvider),
    articleRepository: ref.watch(articleRepositoryProvider),
  );
});

// Repositories Providers
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  throw UnimplementedError('Must be overridden in main()');
});

final articleRepositoryProvider = Provider<ArticleRepository>((ref) {
  return ArticleRepository(ref.watch(storageServiceProvider));
});

final vocabularyRepositoryProvider = Provider<VocabularyRepository>((ref) {
  return VocabularyRepository(ref.watch(storageServiceProvider));
});

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return ReviewRepository(ref.watch(storageServiceProvider));
});

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return HistoryRepository(ref.watch(storageServiceProvider));
});

final aiRepositoryProvider = Provider<AiRepository>((ref) {
  return AiRepository(ref.watch(aiServiceProvider));
});

// UI State & Localization Providers
final themeModeProvider = Provider<ThemeMode>((ref) {
  final settings = ref.watch(settingsRepositoryProvider);
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
  final settings = ref.watch(settingsRepositoryProvider);
  return Locale(settings.locale);
});

// Backward compatibility provider names
final settingsProvider = settingsRepositoryProvider;
final documentRepositoryProvider = articleRepositoryProvider;
final vocabularyDaoProvider = vocabularyRepositoryProvider;
final recallSessionDaoProvider = reviewRepositoryProvider;
final masteryDaoProvider = historyRepositoryProvider;
final readingPositionDaoProvider = articleRepositoryProvider;
final aiClientProvider = aiServiceProvider;
