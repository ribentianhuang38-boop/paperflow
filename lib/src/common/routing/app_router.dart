import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../theme/colors.dart';
import '../../features/library/presentation/library_screen.dart';
import '../../features/reader/presentation/reader_screen.dart';
import '../../features/dictionary/presentation/vocabulary_list_screen.dart';
import '../../features/active_recall/presentation/recall_screen.dart';
import '../../features/active_recall/presentation/review_result_screen.dart';
import '../../features/reading_mastery/presentation/mastery_detail_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/explore/presentation/explore_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (context, state, child) => _MainShell(child: child),
        routes: [
          GoRoute(path: '/', name: 'library', builder: (_, __) => const LibraryScreen()),
          GoRoute(path: '/explore', name: 'explore', builder: (_, __) => const ExploreScreen()),
        ],
      ),
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
        height: 82,
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1C1C1E).withOpacity(0.98)
              : const Color(0xFFFFFFFF).withOpacity(0.98),
          border: Border(
            top: BorderSide(
              color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA),
              width: 0.5,
            ),
          ),
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: _NavItem(
                  icon: Icons.menu_book_outlined,
                  activeIcon: Icons.menu_book,
                  label: 'Library',
                  isActive: location == '/',
                  isDark: isDark,
                  onTap: () => context.go('/'),
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.explore_outlined,
                  activeIcon: Icons.explore,
                  label: 'Explore',
                  isActive: location == '/explore',
                  isDark: isDark,
                  onTap: () => context.go('/explore'),
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
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final bool isDark;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isActive ? activeIcon : icon,
            size: 26,
            color: isActive
                ? AppColors.accent
                : (isDark ? AppColors.darkTextTertiary : AppColors.textTertiary),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: isActive
                  ? AppColors.accent
                  : (isDark ? AppColors.darkTextTertiary : AppColors.textTertiary),
            ),
          ),
        ],
      ),
    );
  }
}
