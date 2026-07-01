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
      GoRoute(
        path: '/',
        name: 'library',
        builder: (context, state) => const LibraryScreen(),
      ),
      GoRoute(
        path: '/reader/:documentId',
        name: 'reader',
        builder: (context, state) {
          final documentId = int.parse(state.pathParameters['documentId']!);
          return ReaderScreen(documentId: documentId);
        },
      ),
      GoRoute(
        path: '/vocabulary',
        name: 'vocabulary',
        builder: (context, state) => const VocabularyListScreen(),
      ),
      GoRoute(
        path: '/recall/:documentId',
        name: 'recall',
        builder: (context, state) {
          final documentId = int.parse(state.pathParameters['documentId']!);
          return RecallScreen(documentId: documentId);
        },
      ),
      GoRoute(
        path: '/review/:sessionId',
        name: 'review',
        builder: (context, state) {
          final sessionId = int.parse(state.pathParameters['sessionId']!);
          return ReviewResultScreen(sessionId: sessionId);
        },
      ),
      GoRoute(
        path: '/mastery/:documentId',
        name: 'mastery',
        builder: (context, state) {
          final documentId = int.parse(state.pathParameters['documentId']!);
          return MasteryDetailScreen(documentId: documentId);
        },
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});
