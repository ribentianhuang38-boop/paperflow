import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:paperflow/src/common/providers.dart';
import '../../../common/theme/colors.dart';
import '../../../common/theme/typography.dart';

class VocabularyListScreen extends ConsumerWidget {
  const VocabularyListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: Text('Vocabulary', style: AppTypography.title2.copyWith(
          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
        )),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_outlined),
            onPressed: () => _export(context, ref),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _load(ref),
        builder: (ctx, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final items = snap.data!;
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bookmark_outline, size: 64,
                        color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary),
                    const SizedBox(height: 20),
                    Text('No words yet', style: AppTypography.title2.copyWith(
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    )),
                    const SizedBox(height: 8),
                    Text('Long press on words while reading to collect them.',
                      textAlign: TextAlign.center,
                      style: AppTypography.subheadline.copyWith(
                        color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            itemCount: items.length,
            itemBuilder: (ctx, i) => _WordTile(item: items[i], isDark: isDark),
          );
        },
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _load(WidgetRef ref) async {
    final dao = await ref.read(vocabularyDaoProvider.future);
    return dao.getAllVocabulary();
  }

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final dao = await ref.read(vocabularyDaoProvider.future);
    final words = await dao.exportVocabulary();
    if (words.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No vocabulary')));
      }
      return;
    }
    await Clipboard.setData(ClipboardData(text: words.join('\n')));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${words.length} words copied')));
    }
  }
}

class _WordTile extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isDark;

  const _WordTile({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final mastered = (item['globalMastered'] as int?) == 1;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: mastered
                  ? AppColors.success.withOpacity(0.12)
                  : (isDark ? AppColors.darkSurfaceSecondary : AppColors.surfaceSecondary),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              mastered ? Icons.check : Icons.bookmark_outline,
              size: 20,
              color: mastered ? AppColors.success : (isDark ? AppColors.darkTextTertiary : AppColors.textTertiary),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['word'] as String,
                    style: AppTypography.headline.copyWith(
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    )),
                if (item['pos'] != null)
                  Text(item['pos'] as String,
                      style: AppTypography.caption1.copyWith(
                        color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                        fontStyle: FontStyle.italic,
                      )),
                if (item['definition'] != null)
                  Text(item['definition'] as String,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: AppTypography.subheadline.copyWith(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      )),
              ],
            ),
          ),
          Text('x${item['queryCount']}', style: AppTypography.caption1.copyWith(
            color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
          )),
        ],
      ),
    );
  }
}
