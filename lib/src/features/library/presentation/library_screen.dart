import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperflow/src/features/library/domain/document.dart';
import 'package:go_router/go_router.dart';
import 'package:file_selector/file_selector.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../../common/database/app_database.dart';
import 'package:paperflow/src/common/providers.dart';
import '../../../common/theme/colors.dart';
import '../../../common/theme/typography.dart';
import 'document_card.dart';

final documentsProvider = FutureProvider<List<Document>>((ref) async {
  final repo = await ref.watch(documentRepositoryProvider.future);
  return repo.getAllDocuments();
});

final continueReadingProvider = FutureProvider<List<Document>>((ref) async {
  final repo = await ref.watch(documentRepositoryProvider.future);
  return repo.getContinueReading();
});

final searchQueryProvider = StateProvider<String>((ref) => '');

final filteredDocumentsProvider = FutureProvider<List<Document>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  final repo = await ref.watch(documentRepositoryProvider.future);
  if (query.isEmpty) return repo.getAllDocuments();
  return repo.searchDocuments(query);
});

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docsAsync = ref.watch(filteredDocumentsProvider);
    final continueReading = ref.watch(continueReadingProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Large Title Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _greeting(),
                                style: AppTypography.caption1.copyWith(
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'PaperFlow',
                                style: AppTypography.largeTitle.copyWith(
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _IconButton(
                          icon: Icons.search,
                          isDark: isDark,
                          onTap: () => _showSearch(context, ref),
                        ),
                        const SizedBox(width: 8),
                        _IconButton(
                          icon: Icons.book_outlined,
                          isDark: isDark,
                          onTap: () => context.push('/vocabulary'),
                        ),
                        const SizedBox(width: 8),
                        _IconButton(
                          icon: Icons.settings_outlined,
                          isDark: isDark,
                          onTap: () => context.push('/settings'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // Content
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
                    // Continue Reading
                    continueReading.when(
                      data: (continuing) {
                        if (continuing.isEmpty) return const SizedBox.shrink();
                        return _buildContinueReading(context, continuing, isDark);
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),

                    // Recent Papers
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                      child: Text(
                        'Recent Papers',
                        style: AppTypography.title2.copyWith(
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        ),
                      ),
                    ),

                    ...docs.map((doc) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
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
      floatingActionButton: _ImportButton(
        onTap: () => _importDocument(context, ref),
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Widget _buildContinueReading(
      BuildContext context, List<Document> docs, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
          child: Text(
            'Continue Reading',
            style: AppTypography.title2.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
        ),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: docs.length,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: SizedBox(
                width: 160,
                child: DocumentCard(document: docs[index], compact: true),
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
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

      final repo = await ref.read(documentRepositoryProvider.future);
      final appDir = await getApplicationDocumentsDirectory();
      final papersDir = Directory(p.join(appDir.path, 'papers'));
      if (!await papersDir.exists()) {
        await papersDir.create(recursive: true);
      }

      int importedCount = 0;
      for (final file in files) {
        final name = file.name;
        final ext = p.extension(name).toLowerCase();
        final fileType = ext == '.pdf' ? 'pdf'
            : ext == '.epub' ? 'epub'
            : (ext == '.md' || ext == '.markdown') ? 'md'
            : (ext == '.html' || ext == '.htm') ? 'html'
            : ext == '.txt' ? 'txt' : 'unknown';

        if (fileType == 'unknown') continue;

        try {
          final bytes = await file.readAsBytes();
          if (bytes.isEmpty) continue;
          final uniqueName = '${const Uuid().v4()}_$name';
          final destPath = p.join(papersDir.path, uniqueName);
          await File(destPath).writeAsBytes(bytes);

          await repo.insertDocument({
            'title': p.basenameWithoutExtension(name),
            'filePath': destPath,
            'fileType': fileType,
            'importDate': DateTime.now().millisecondsSinceEpoch,
          });
          importedCount++;
        } catch (e) {
          debugPrint('Failed to import $name: $e');
        }
      }

      ref.invalidate(documentsProvider);
      ref.invalidate(filteredDocumentsProvider);
      ref.invalidate(continueReadingProvider);

      if (context.mounted && importedCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imported $importedCount document(s)')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e')),
        );
      }
    }
  }

  void _showSearch(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Search'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Search by title or author...'),
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

class _IconButton extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;

  const _IconButton({
    required this.icon,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceSecondary : AppColors.surfaceSecondary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _ImportButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ImportButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              'Import Paper',
              style: AppTypography.headline.copyWith(color: Colors.white),
            ),
          ],
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
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceSecondary : AppColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(
                Icons.menu_book_outlined,
                size: 48,
                color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Start Building',
              style: AppTypography.title1.copyWith(
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Your Research Library',
              style: AppTypography.title1.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Import your first paper and begin\nyour active reading journey.',
              textAlign: TextAlign.center,
              style: AppTypography.subheadline.copyWith(
                color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
