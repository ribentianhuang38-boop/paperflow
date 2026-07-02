import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/app/providers.dart';
import '../../../core/design_system/color_tokens.dart';
import '../../../core/design_system/typography.dart';
import '../../../models/article/article.dart';
import 'library_screen.dart';

class DocumentCard extends ConsumerWidget {
  final Article document;

  const DocumentCard({
    super.key,
    required this.document,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => context.push('/reader/${document.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: ColorTokens.getBackground(isDark),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: ColorTokens.getDivider(isDark), width: 1.0),
          boxShadow: ColorTokens.getShadow(isDark),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: ColorTokens.getSurfaceSecondary(isDark),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: ColorTokens.getDivider(isDark), width: 0.5),
                  ),
                  child: Text(
                    document.fileType.toUpperCase(),
                    style: AppTypography.caption2.copyWith(
                      color: ColorTokens.accent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Row(
                  children: [
                    if (document.isFavorite) ...[
                      const Icon(LucideIcons.heart, size: 16, color: ColorTokens.error),
                      const SizedBox(width: 12),
                    ],
                    GestureDetector(
                      onTap: () => _showMenu(context, ref),
                      child: Icon(
                        LucideIcons.moreHorizontal,
                        size: 20,
                        color: ColorTokens.getTextTertiary(isDark),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              document.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.headline.copyWith(
                color: ColorTokens.getTextPrimary(isDark),
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
            if (document.author != null && document.author!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                document.author!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.subheadline.copyWith(
                  color: ColorTokens.getTextSecondary(isDark),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDate(document.lastReadTime ?? document.importDate),
                  style: AppTypography.caption1.copyWith(
                    color: ColorTokens.getTextTertiary(isDark),
                  ),
                ),
                if (document.progress > 0)
                  Text(
                    '${(document.progress * 100).round()}% read',
                    style: AppTypography.caption1.copyWith(
                      color: ColorTokens.getTextSecondary(isDark),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            if (document.progress > 0) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: document.progress,
                  backgroundColor: ColorTokens.getDivider(isDark),
                  valueColor: const AlwaysStoppedAnimation(ColorTokens.accent),
                  minHeight: 4,
                ),
              ),
            ],
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
    return DateFormat.yMMMd().format(date);
  }

  void _showMenu(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: ColorTokens.getBackground(isDark),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => ProviderScope(
        parent: ProviderScope.containerOf(context),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                decoration: BoxDecoration(
                  color: ColorTokens.getDivider(isDark),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Icon(
                  document.isFavorite ? LucideIcons.heartOff : LucideIcons.heart,
                  color: ColorTokens.getTextPrimary(isDark),
                ),
                title: Text(
                  document.isFavorite ? 'Unfavorite' : 'Favorite',
                  style: AppTypography.bodySans.copyWith(color: ColorTokens.getTextPrimary(isDark)),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  final repo = ref.read(articleRepositoryProvider);
                  await repo.updateFavorite(document.id!, !document.isFavorite);
                  ref.invalidate(filteredDocumentsProvider);
                  ref.invalidate(continueReadingProvider);
                },
              ),
              ListTile(
                leading: Icon(LucideIcons.fileSpreadsheet, color: ColorTokens.getTextPrimary(isDark)),
                title: Text(
                  'Start Review',
                  style: AppTypography.bodySans.copyWith(color: ColorTokens.getTextPrimary(isDark)),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/recall/${document.id}');
                },
              ),
              ListTile(
                leading: const Icon(LucideIcons.trash2, color: ColorTokens.error),
                title: Text(
                  'Delete',
                  style: AppTypography.bodySans.copyWith(color: ColorTokens.error),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDelete(context, ref);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => ProviderScope(
        parent: ProviderScope.containerOf(context),
        child: AlertDialog(
          backgroundColor: ColorTokens.getBackground(isDark),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text('Delete Document', style: AppTypography.title3.copyWith(color: ColorTokens.getTextPrimary(isDark))),
          content: Text('Delete "${document.title}"? This cannot be undone.', style: AppTypography.bodySans.copyWith(color: ColorTokens.getTextSecondary(isDark))),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final repo = ref.read(articleRepositoryProvider);
                await repo.deleteArticle(document.id!);
                ref.invalidate(filteredDocumentsProvider);
                ref.invalidate(continueReadingProvider);
                Navigator.pop(ctx);
              },
              child: const Text('Delete', style: TextStyle(color: ColorTokens.error)),
            ),
          ],
        ),
      ),
    );
  }
}
