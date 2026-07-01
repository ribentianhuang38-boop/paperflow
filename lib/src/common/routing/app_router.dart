import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/library/presentation/library_screen.dart';
import '../../features/reader/presentation/reader_screen.dart';
import '../../features/dictionary/presentation/vocabulary_list_screen.dart';
import '../../features/active_recall/presentation/recall_screen.dart';
import '../../features/active_recall/presentation/review_result_screen.dart';
import '../../features/reading_mastery/presentation/mastery_detail_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', name: 'library', builder: (_, __) => const LibraryScreen()),
      GoRoute(
        path: '/reader/:documentId', name: 'reader',
        builder: (_, state) => ReaderScreen(documentId: int.parse(state.pathParameters['documentId']!)),
      ),
      GoRoute(path: '/vocabulary', name: 'vocabulary', builder: (_, __) => const VocabularyListScreen()),
      GoRoute(
        path: '/recall/:documentId', name: 'recall',
        builder: (_, state) => RecallScreen(documentId: int.parse(state.pathParameters['documentId']!)),
      ),
      GoRoute(
        path: '/review/:sessionId', name: 'review',
        builder: (_, state) => ReviewResultScreen(sessionId: int.parse(state.pathParameters['sessionId']!)),
      ),
      GoRoute(
        path: '/mastery/:documentId', name: 'mastery',
        builder: (_, state) => MasteryDetailScreen(documentId: int.parse(state.pathParameters['documentId']!)),
      ),
      GoRoute(path: '/settings', name: 'settings', builder: (_, __) => const SettingsScreen()),
    ],
  );
});
