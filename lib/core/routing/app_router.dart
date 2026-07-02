import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../design_system/color_tokens.dart';
import '../../features/library/presentation/library_screen.dart';
import '../../features/explore/presentation/explore_screen.dart';
import '../../features/reading_history/presentation/history_screen.dart';
import '../../features/reader/presentation/reader_screen.dart';
import '../../features/reader/presentation/terminology_screen.dart';
import '../../features/review/recall/recall_screen.dart';
import '../../features/review/report/review_result_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (context, state, child) => _MainShell(child: child),
        routes: [
          GoRoute(path: '/', name: 'library', builder: (_, __) => const LibraryScreen()),
          GoRoute(path: '/explore', name: 'explore', builder: (_, __) => const ExploreScreen()),
          GoRoute(path: '/history', name: 'history_global', builder: (_, __) => const ReadingHistoryScreen()),
        ],
      ),
      GoRoute(
        path: '/reader/:documentId',
        name: 'reader',
        builder: (_, state) {
          final documentId = int.parse(state.pathParameters['documentId']!);
          final paragraphStr = state.uri.queryParameters['paragraph'];
          final paragraphIdx = paragraphStr != null ? int.tryParse(paragraphStr) : null;
          return ReaderScreen(documentId: documentId, initialParagraphIdx: paragraphIdx);
        },
      ),
      GoRoute(
        path: '/vocabulary',
        name: 'vocabulary',
        builder: (_, __) => const TerminologyScreen(),
      ),
      GoRoute(
        path: '/recall/:documentId',
        name: 'recall',
        builder: (_, state) => RecallScreen(documentId: int.parse(state.pathParameters['documentId']!)),
      ),
      GoRoute(
        path: '/review/:sessionId',
        name: 'review',
        builder: (_, state) => ReviewResultScreen(sessionId: int.parse(state.pathParameters['sessionId']!)),
      ),
      GoRoute(path: '/settings', name: 'settings', builder: (_, __) => const SettingsScreen()),
    ],
  );
});

class _MainShell extends StatelessWidget {
  final Widget child;
  const _MainShell({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final location = GoRouterState.of(context).matchedLocation;

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        height: 72,
        decoration: BoxDecoration(
          color: ColorTokens.getBackground(isDark),
          border: Border(
            top: BorderSide(
              color: ColorTokens.getDivider(isDark),
              width: 1.0,
            ),
          ),
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: _NavItem(
                  icon: LucideIcons.bookOpen,
                  label: 'Library',
                  isActive: location == '/',
                  isDark: isDark,
                  onTap: () => context.go('/'),
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: LucideIcons.compass,
                  label: 'Explore',
                  isActive: location == '/explore',
                  isDark: isDark,
                  onTap: () => context.go('/explore'),
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: LucideIcons.activity,
                  label: 'Progress',
                  isActive: location == '/history',
                  isDark: isDark,
                  onTap: () => context.go('/history'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool isDark;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = ColorTokens.accent;
    final inactiveColor = ColorTokens.getTextTertiary(isDark);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 22,
            color: isActive ? activeColor : inactiveColor,
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: isActive ? activeColor : inactiveColor,
            ),
          ),
        ],
      ),
    );
  }
}
