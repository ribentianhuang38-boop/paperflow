import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../common/database/app_database.dart';
import '../data/document_repository.dart';
import '../data/import_service.dart';
import 'document_card.dart';

final documentRepositoryProvider = Provider<DocumentRepository>((ref) {
  return DocumentRepository(ref.watch(databaseProvider));
});

final importServiceProvider = Provider<ImportService>((ref) {
  return ImportService(ref.watch(databaseProvider));
});

final documentsProvider = FutureProvider<List<Document>>((ref) async {
  final repo = ref.watch(documentRepositoryProvider);
  return repo.getAllDocuments();
});

final continueReadingProvider = FutureProvider<List<Document>>((ref) async {
  final repo = ref.watch(documentRepositoryProvider);
  return repo.getContinueReading();
});

final searchQueryProvider = StateProvider<String>((ref) => '');

final filteredDocumentsProvider = FutureProvider<List<Document>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  final repo = ref.watch(documentRepositoryProvider);
  if (query.isEmpty) return repo.getAllDocuments();
  return repo.searchDocuments(query);
});

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docsAsync = ref.watch(filteredDocumentsProvider);
    final continueReading = ref.watch(continueReadingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('PaperFlow'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearch(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.menu_book),
            tooltip: 'Vocabulary',
            onPressed: () => context.push('/vocabulary'),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: docsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (docs) {
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.library_books_outlined,
                      size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No documents yet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Import a PDF, EPUB, or other document to get started',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade500,
                        ),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              continueReading.when(
                data: (continuing) {
                  if (continuing.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Text(
                          'Continue Reading',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                      SizedBox(
                        height: 200,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: continuing.length,
                          itemBuilder: (context, index) {
                            return SizedBox(
                              width: 160,
                              child: DocumentCard(
                                document: continuing[index],
                                compact: true,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'All Documents',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              ...docs.map((doc) => DocumentCard(document: doc)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _importDocument(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _importDocument(
      BuildContext context, WidgetRef ref) async {
    final importService = ref.read(importServiceProvider);
    try {
      final ids = await importService.importMultipleDocuments();
      if (ids.isNotEmpty) {
        ref.invalidate(documentsProvider);
        ref.invalidate(continueReadingProvider);
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
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Search'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Search by title or author...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) {
              ref.read(searchQueryProvider.notifier).state = value;
            },
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
        );
      },
    ).then((_) {
      ref.read(searchQueryProvider.notifier).state = '';
    });
  }
}
