import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_selector/file_selector.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/app/providers.dart';
import '../../../core/design_system/color_tokens.dart';
import '../../../core/design_system/typography.dart';
import '../../../models/article/article.dart';
import 'document_card.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');

final statsProvider = FutureProvider<Map<String, int>>((ref) async {
  final repo = ref.watch(articleRepositoryProvider);
  return repo.getReadingStats();
});

final continueReadingProvider = FutureProvider<List<Article>>((ref) async {
  final repo = ref.watch(articleRepositoryProvider);
  final all = await repo.getArticles();
  return all.where((a) => a.progress > 0.0 && a.progress < 1.0).toList();
});

final filteredDocumentsProvider = FutureProvider<List<Article>>((ref) async {
  final query = ref.watch(searchQueryProvider).toLowerCase();
  final repo = ref.watch(articleRepositoryProvider);
  final all = await repo.getArticles();
  if (query.isEmpty) return all;
  return all.where((a) =>
      a.title.toLowerCase().contains(query) ||
      (a.author != null && a.author!.toLowerCase().contains(query))).toList();
});

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docsAsync = ref.watch(filteredDocumentsProvider);
    final continueReading = ref.watch(continueReadingProvider);
    final statsAsync = ref.watch(statsProvider);
    final settings = ref.watch(settingsRepositoryProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: ColorTokens.getBackground(isDark),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          _greeting(),
                          style: AppTypography.largeTitle.copyWith(
                            color: ColorTokens.getTextPrimary(isDark),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            _HeaderButton(
                              icon: LucideIcons.search,
                              isDark: isDark,
                              onTap: () => _showSearch(context, ref),
                            ),
                            const SizedBox(width: 12),
                            _HeaderButton(
                              icon: LucideIcons.bookOpen,
                              isDark: isDark,
                              onTap: () => context.push('/vocabulary'),
                            ),
                            const SizedBox(width: 12),
                            _HeaderButton(
                              icon: LucideIcons.settings,
                              isDark: isDark,
                              onTap: () => context.push('/settings').then((_) {
                                ref.invalidate(statsProvider);
                              }),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            if (settings.readingGoalEnabled)
              SliverToBoxAdapter(
                child: _buildDailyGoalProgress(context, settings, isDark),
              ),
            SliverToBoxAdapter(
              child: statsAsync.when(
                data: (stats) => _buildStatisticsGrid(
                  context,
                  stats['papers'] ?? 0,
                  settings.totalReadingTime,
                  stats['words'] ?? 0,
                  stats['vocab'] ?? 0,
                  stats['highlights'] ?? 0,
                  stats['notes'] ?? 0,
                  isDark,
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
            docsAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => SliverFillRemaining(
                child: Center(child: Text('Error: $e')),
              ),
              data: (docs) {
                if (docs.isEmpty) {
                  return SliverFillRemaining(
                    child: _EmptyState(isDark: isDark),
                  );
                }

                return SliverList(
                  delegate: SliverChildListDelegate([
                    continueReading.when(
                      data: (continuing) {
                        if (continuing.isEmpty) return const SizedBox.shrink();
                        return _buildContinueReading(context, continuing, isDark);
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
                      child: Text(
                        'Recent Papers',
                        style: AppTypography.title2.copyWith(
                          color: ColorTokens.getTextPrimary(isDark),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ...docs.map((doc) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          child: DocumentCard(document: doc),
                        )),
                    const SizedBox(height: 100),
                  ]),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _importDocument(context, ref),
        backgroundColor: ColorTokens.accent,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        elevation: 2,
        child: const Icon(LucideIcons.plus, size: 24),
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning.';
    if (hour < 17) return 'Good afternoon.';
    return 'Good evening.';
  }

  Widget _buildDailyGoalProgress(BuildContext context, dynamic settings, bool isDark) {
    final goalType = settings.readingGoalType;
    final goalValue = settings.readingGoalValue;
    
    double progress = 0.0;
    String progressText = '';
    String label = '';
    
    if (goalType == 'time') {
      final minutes = (settings.todayReadingTime / 60).round();
      progress = (minutes / goalValue).clamp(0.0, 1.0);
      progressText = '$minutes / $goalValue mins';
      label = 'Daily Focus Duration';
    } else {
      final papers = settings.todayPapersRead;
      progress = (papers / goalValue).clamp(0.0, 1.0);
      progressText = '$papers / $goalValue papers';
      label = 'Daily Reading Papers';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ColorTokens.getBackground(isDark),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ColorTokens.getDivider(isDark), width: 1.0),
        boxShadow: ColorTokens.getShadow(isDark),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Today's Progress",
                  style: AppTypography.caption2.copyWith(
                    color: ColorTokens.getTextTertiary(isDark),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: AppTypography.title3.copyWith(
                    color: ColorTokens.getTextPrimary(isDark),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  progressText,
                  style: AppTypography.subheadline.copyWith(
                    color: ColorTokens.getTextSecondary(isDark),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 50,
            height: 50,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 5,
                  backgroundColor: ColorTokens.getDivider(isDark),
                  valueColor: const AlwaysStoppedAnimation(ColorTokens.accent),
                ),
                Icon(
                  LucideIcons.zap,
                  color: progress >= 1.0 ? ColorTokens.success : ColorTokens.accent,
                  size: 16,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsGrid(
    BuildContext context,
    int totalPapers,
    int totalTimeSec,
    int totalWords,
    int totalSavedVocab,
    int totalHighlights,
    int totalNotes,
    bool isDark,
  ) {
    final hours = (totalTimeSec / 3600).toStringAsFixed(1);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ColorTokens.getBackground(isDark),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ColorTokens.getDivider(isDark), width: 1.0),
        boxShadow: ColorTokens.getShadow(isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reading Statistics',
            style: AppTypography.headline.copyWith(
              color: ColorTokens.getTextPrimary(isDark),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 20,
            childAspectRatio: 1.1,
            children: [
              _buildStatItem('Papers', '$totalPapers', LucideIcons.book, isDark),
              _buildStatItem('Duration', '${hours}h', LucideIcons.clock, isDark),
              _buildStatItem('Words', _formatWords(totalWords), LucideIcons.type, isDark),
              _buildStatItem('Vocab', '$totalSavedVocab', LucideIcons.bookmark, isDark),
              _buildStatItem('Highlights', '$totalHighlights', LucideIcons.edit3, isDark),
              _buildStatItem('Notes', '$totalNotes', LucideIcons.fileText, isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 18, color: ColorTokens.getTextTertiary(isDark)),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: ColorTokens.getTextPrimary(isDark),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTypography.caption2.copyWith(
            color: ColorTokens.getTextTertiary(isDark),
          ),
        ),
      ],
    );
  }

  String _formatWords(int count) {
    if (count < 1000) return '$count';
    if (count < 1000000) return '${(count / 1000).toStringAsFixed(1)}k';
    return '${(count / 1000000).toStringAsFixed(1)}m';
  }

  Widget _buildContinueReading(
      BuildContext context, List<Article> docs, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
          child: Text(
            'Continue Reading',
            style: AppTypography.title2.copyWith(
              color: ColorTokens.getTextPrimary(isDark),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: GestureDetector(
                  onTap: () => context.push('/reader/${doc.id}'),
                  child: Container(
                    width: 220,
                    decoration: BoxDecoration(
                      color: ColorTokens.getBackground(isDark),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: ColorTokens.getDivider(isDark), width: 1.0),
                      boxShadow: ColorTokens.getShadow(isDark),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              doc.fileType.toUpperCase(),
                              style: AppTypography.caption2.copyWith(
                                color: ColorTokens.accent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              doc.title,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.headline.copyWith(
                                color: ColorTokens.getTextPrimary(isDark),
                                fontWeight: FontWeight.w600,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDate(doc.lastReadTime ?? doc.importDate),
                                  style: AppTypography.caption2.copyWith(
                                    color: ColorTokens.getTextTertiary(isDark),
                                  ),
                                ),
                                Text(
                                  '${(doc.progress * 100).round()}%',
                                  style: AppTypography.caption2.copyWith(
                                    color: ColorTokens.getTextSecondary(isDark),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: doc.progress,
                                backgroundColor: ColorTokens.getDivider(isDark),
                                valueColor: const AlwaysStoppedAnimation(ColorTokens.accent),
                                minHeight: 3,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final diff = DateTime.now().difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    return DateFormat.yMMMd().format(date);
  }

  Future<void> _importDocument(BuildContext context, WidgetRef ref) async {
    try {
      final files = await openFiles(
        acceptedTypeGroups: [
          XTypeGroup(
            label: 'Documents',
            extensions: ['pdf', 'epub', 'md', 'markdown', 'html', 'htm', 'txt'],
          ),
        ],
      );
      if (files.isEmpty) return;

      final importer = ref.read(importerServiceProvider);
      int importedCount = 0;
      String? lastError;

      for (final file in files) {
        try {
          final article = await importer.importLocalFile(
            sourcePath: file.path,
            title: p.basenameWithoutExtension(file.name),
          );
          if (article.id != null) {
            importedCount++;
          }
        } catch (e) {
          lastError = 'Error importing ${file.name}: $e';
          debugPrint(lastError);
        }
      }

      ref.invalidate(filteredDocumentsProvider);
      ref.invalidate(continueReadingProvider);
      ref.invalidate(statsProvider);

      if (context.mounted) {
        if (importedCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Imported $importedCount document(s)')),
          );
        } else if (lastError != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(lastError), backgroundColor: ColorTokens.error),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e'), backgroundColor: ColorTokens.error),
        );
      }
    }
  }

  void _showSearch(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ColorTokens.getBackground(Theme.of(context).brightness == Brightness.dark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Search'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Search by title...'),
          onChanged: (v) => ref.read(searchQueryProvider.notifier).state = v,
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(searchQueryProvider.notifier).state = '';
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    ).then((_) => ref.read(searchQueryProvider.notifier).state = '');
  }
}

class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;

  const _HeaderButton({
    required this.icon,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: ColorTokens.getSurfaceSecondary(isDark),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ColorTokens.getDivider(isDark), width: 0.5),
        ),
        child: Icon(
          icon,
          size: 18,
          color: ColorTokens.getTextSecondary(isDark),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isDark;

  const _EmptyState({required this.isDark});

  @override
  Widget build(BuildContext context) {
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
                LucideIcons.bookOpen,
                size: 32,
                color: ColorTokens.getTextTertiary(isDark),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No papers yet',
              style: AppTypography.title2.copyWith(
                color: ColorTokens.getTextPrimary(isDark),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Import your research papers and start active reading with PaperFlow.',
              textAlign: TextAlign.center,
              style: AppTypography.subheadline.copyWith(
                color: ColorTokens.getTextTertiary(isDark),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
