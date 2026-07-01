import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

import '../../../common/database/app_database.dart';
import '../../library/data/document_repository.dart';
import '../../library/presentation/library_screen.dart';
import '../data/reading_position_dao.dart';
import 'word_popup.dart';

final readingPositionDaoProvider = Provider<ReadingPositionDao>((ref) {
  return ReadingPositionDao(ref.watch(databaseProvider));
});

final currentDocumentProvider =
    FutureProvider.family<Document?, int>((ref, documentId) async {
  final repo = ref.watch(documentRepositoryProvider);
  return repo.getDocumentById(documentId);
});

class ReaderScreen extends ConsumerStatefulWidget {
  final int documentId;

  const ReaderScreen({super.key, required this.documentId});

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  int _currentPage = 0;
  int _totalPages = 0;
  PDFViewController? _pdfController;

  @override
  Widget build(BuildContext context) {
    final docAsync = ref.watch(currentDocumentProvider(widget.documentId));

    return Scaffold(
      appBar: AppBar(
        title: docAsync.when(
          data: (doc) => Text(
            doc?.title ?? 'Reader',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          loading: () => const Text('Loading...'),
          error: (_, __) => const Text('Error'),
        ),
        actions: [
          if (_totalPages > 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '$_currentPage / $_totalPages',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.bookmark_outline),
            onPressed: () => _showBookmarks(context),
          ),
          IconButton(
            icon: const Icon(Icons.quiz_outlined),
            tooltip: 'Start Review',
            onPressed: () => context.push('/recall/${widget.documentId}'),
          ),
        ],
      ),
      body: docAsync.when(
        data: (doc) {
          if (doc == null) {
            return const Center(child: Text('Document not found'));
          }
          return _buildReader(doc);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildReader(Document doc) {
    switch (doc.fileType) {
      case 'pdf':
        return _buildPdfReader(doc);
      case 'epub':
        return _buildEpubReader(doc);
      case 'md':
      case 'html':
      case 'txt':
        return _buildTextReader(doc);
      default:
        return const Center(child: Text('Unsupported file type'));
    }
  }

  Widget _buildPdfReader(Document doc) {
    final file = File(doc.filePath);
    if (!file.existsSync()) {
      return const Center(child: Text('PDF file not found'));
    }

    return PDFView(
      filePath: doc.filePath,
      enableSwipe: true,
      swipeHorizontal: false,
      autoSpacing: true,
      pageFling: true,
      pageSnap: true,
      defaultPage: _currentPage,
      fitPolicy: FitPolicy.BOTH,
      preventLinkNavigation: false,
      onRender: (pages) {
        setState(() {
          _totalPages = pages ?? 0;
        });
      },
      onError: (error) {
        debugPrint('PDF Error: $error');
      },
      onPageError: (page, error) {
        debugPrint('PDF Page $page Error: $error');
      },
      onViewCreated: (controller) {
        _pdfController = controller;
      },
      onPageChanged: (page, total) {
        setState(() {
          _currentPage = page ?? 0;
          _totalPages = total ?? 0;
        });
        _saveProgress(doc);
      },
    );
  }

  Widget _buildEpubReader(Document doc) {
    return FutureBuilder(
      future: _loadEpubContent(doc.filePath),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: SelectableText(
                snapshot.data!,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      height: 1.6,
                      fontSize: 18,
                    ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextReader(Document doc) {
    return FutureBuilder<String>(
      future: _loadTextContent(doc.filePath),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: SelectableText(
                snapshot.data!,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      height: 1.6,
                      fontSize: 18,
                    ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<String> _loadEpubContent(String filePath) async {
    try {
      final bytes = await File(filePath).readAsBytes();
      final book = await EpubReader.readBook(bytes);
      final buffer = StringBuffer();

      if (book.Chapters != null) {
        for (final chapter in book.Chapters!) {
          if (chapter.Title != null) {
            buffer.writeln('\n${chapter.Title}\n');
          }
          if (chapter.HtmlContent != null) {
            // Strip HTML tags for plain text display
            final text = chapter.HtmlContent!
                .replaceAll(RegExp(r'<[^>]*>'), '')
                .replaceAll('&nbsp;', ' ')
                .replaceAll('&amp;', '&')
                .replaceAll('&lt;', '<')
                .replaceAll('&gt;', '>')
                .trim();
            if (text.isNotEmpty) {
              buffer.writeln(text);
              buffer.writeln();
            }
          }
        }
      }

      return buffer.toString().isEmpty
          ? 'Could not parse EPUB content'
          : buffer.toString();
    } catch (e) {
      return 'Error loading EPUB: $e';
    }
  }

  Future<String> _loadTextContent(String filePath) async {
    try {
      return await File(filePath).readAsString();
    } catch (e) {
      return 'Error reading file: $e';
    }
  }

  void _saveProgress(Document doc) {
    if (_totalPages > 0) {
      final progress = _currentPage / _totalPages;
      ref.read(documentRepositoryProvider).updateProgress(doc.id, progress);
      ref.read(documentRepositoryProvider).updateLastReadTime(doc.id);
    }
  }

  void _showBookmarks(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Bookmarks',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            const Text('No bookmarks yet'),
          ],
        ),
      ),
    );
  }
}
