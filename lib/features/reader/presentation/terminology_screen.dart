import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/app/providers.dart';
import '../../../core/design_system/color_tokens.dart';
import '../../../core/design_system/typography.dart';
import '../../../models/vocabulary/vocabulary.dart';

class TerminologyScreen extends ConsumerWidget {
  const TerminologyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: ColorTokens.getBackground(isDark),
      appBar: AppBar(
        title: Text('Terminology Book', style: AppTypography.title2.copyWith(
          color: ColorTokens.getTextPrimary(isDark),
          fontWeight: FontWeight.bold,
        )),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.copy),
            onPressed: () => _export(context, ref),
          ),
        ],
      ),
      body: FutureBuilder<List<Vocabulary>>(
        future: ref.read(vocabularyRepositoryProvider).getAllVocabulary(),
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
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: ColorTokens.getSurfaceSecondary(isDark),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: ColorTokens.getDivider(isDark), width: 0.5),
                      ),
                      child: Icon(
                        LucideIcons.bookmark,
                        size: 32,
                        color: ColorTokens.getTextTertiary(isDark),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('No terms collected yet', style: AppTypography.title2.copyWith(
                      color: ColorTokens.getTextPrimary(isDark),
                      fontWeight: FontWeight.bold,
                    )),
                    const SizedBox(height: 8),
                    Text('Double tap on words while reading to collect them.',
                      textAlign: TextAlign.center,
                      style: AppTypography.subheadline.copyWith(
                        color: ColorTokens.getTextSecondary(isDark),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            itemCount: items.length,
            itemBuilder: (ctx, i) => _WordTile(item: items[i], isDark: isDark),
          );
        },
      ),
    );
  }

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(vocabularyRepositoryProvider);
    final list = await repo.getAllVocabulary();
    if (list.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No terminology collected yet')));
      }
      return;
    }
    final text = list.map((v) => '${v.word}: ${v.meaning}').join('\n');
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${list.length} terms copied')));
    }
  }
}

class _WordTile extends StatelessWidget {
  final Vocabulary item;
  final bool isDark;

  const _WordTile({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorTokens.getBackground(isDark),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ColorTokens.getDivider(isDark), width: 1.0),
        boxShadow: ColorTokens.getShadow(isDark),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: item.isStarred
                  ? Colors.amber.withOpacity(0.08)
                  : ColorTokens.getSurfaceSecondary(isDark),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: item.isStarred ? Colors.amber.withOpacity(0.2) : ColorTokens.getDivider(isDark),
                width: 0.5,
              ),
            ),
            child: Icon(
              item.isStarred ? LucideIcons.star : LucideIcons.bookmark,
              size: 18,
              color: item.isStarred ? Colors.amber : ColorTokens.getTextTertiary(isDark),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.word,
                    style: AppTypography.headline.copyWith(
                      color: ColorTokens.getTextPrimary(isDark),
                      fontWeight: FontWeight.bold,
                    )),
                if (item.meaning.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(item.meaning,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: AppTypography.subheadline.copyWith(
                        color: ColorTokens.getTextSecondary(isDark),
                      )),
                ],
              ],
            ),
          ),
          Text('x${item.queryCount}', style: AppTypography.caption1.copyWith(
            color: ColorTokens.getTextTertiary(isDark),
            fontWeight: FontWeight.bold,
          )),
        ],
      ),
    );
  }
}
