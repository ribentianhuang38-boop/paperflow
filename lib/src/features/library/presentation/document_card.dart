import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:paperflow/src/features/library/domain/document.dart';
import 'package:paperflow/src/common/providers.dart';
import '../../../common/theme/colors.dart';
import '../../../common/theme/typography.dart';
import 'library_screen.dart';

class DocumentCard extends ConsumerWidget {
  final Document document;
  final bool compact;

  const DocumentCard({
    super.key,
    required this.document,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (compact) return _buildCompact(context, ref, isDark);
    return _buildFull(context, ref, isDark);
  }

  Widget _buildCompact(BuildContext context, WidgetRef ref, bool isDark) {
    return GestureDetector(
      onTap: () => context.push('/reader/${document.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.accentLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.description_outlined, size: 18, color: AppColors.accent),
                ),
                const Spacer(),
                if (document.isFavorite)
                  const Icon(Icons.favorite, size: 14, color: AppColors.error),
              ],
            ),
            const Spacer(),
            Text(
              document.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.subheadline.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            if (document.progress > 0)
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: document.progress,
                  backgroundColor: isDark ? AppColors.darkDivider : AppColors.divider,
                  valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                  minHeight: 3,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFull(BuildContext context, WidgetRef ref, bool isDark) {
    return GestureDetector(
      onTap: () => context.push('/reader/${document.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.accentLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.description_outlined, color: AppColors.accent, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          document.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.headline.copyWith(
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (document.isFavorite)
                        const Icon(Icons.favorite, size: 16, color: AppColors.error),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (document.authors != null)
                    Text(
                      document.authors!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption1.copyWith(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(document.lastReadTime ?? document.importDate),
                    style: AppTypography.caption1.copyWith(
                      color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                    ),
                  ),
                  if (document.progress > 0) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: document.progress,
                              backgroundColor: isDark ? AppColors.darkDivider : AppColors.divider,
                              valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                              minHeight: 3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${(document.progress * 100).round()}%',
                          style: AppTypography.caption1.copyWith(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _showMenu(context, ref),
              child: Icon(
                Icons.more_horiz,
                size: 20,
                color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final diff = DateTime.now().difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return DateFormat.E().format(date);
    return DateFormat.yMMMd().format(date);
  }

  void _showMenu(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _MenuItem(
              icon: document.isFavorite ? Icons.favorite_border : Icons.favorite,
              label: document.isFavorite ? 'Unfavorite' : 'Favorite',
              isDark: isDark,
              onTap: () async {
                Navigator.pop(ctx);
                final repo = await ref.read(documentRepositoryProvider.future);
                await repo.toggleFavorite(document.id);
                ref.invalidate(documentsProvider);
                ref.invalidate(filteredDocumentsProvider);
              },
            ),
            _MenuItem(
              icon: Icons.quiz_outlined,
              label: 'Start Review',
              isDark: isDark,
              onTap: () {
                Navigator.pop(ctx);
                context.push('/recall/${document.id}');
              },
            ),
            _MenuItem(
              icon: Icons.trending_up,
              label: 'Reading Mastery',
              isDark: isDark,
              onTap: () {
                Navigator.pop(ctx);
                context.push('/mastery/${document.id}');
              },
            ),
            _MenuItem(
              icon: Icons.delete_outline,
              label: 'Delete',
              isDestructive: true,
              isDark: isDark,
              onTap: () {
                Navigator.pop(ctx);
                _confirmDelete(context, ref);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Document'),
        content: Text('Delete "${document.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final repo = await ref.read(documentRepositoryProvider.future);
              await repo.deleteDocument(document.id);
              ref.invalidate(documentsProvider);
              ref.invalidate(filteredDocumentsProvider);
              ref.invalidate(continueReadingProvider);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDestructive;
  final bool isDark;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    this.isDestructive = false,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive
            ? AppColors.error
            : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
      ),
      title: Text(
        label,
        style: AppTypography.bodySans.copyWith(
          color: isDestructive
              ? AppColors.error
              : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
    );
  }
}
