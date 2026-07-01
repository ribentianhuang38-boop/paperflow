import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pdfrx/pdfrx.dart';

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
  PdfViewerController? _pdfController;
  int _currentPage = 0;
  int _totalPages = 0;

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
          if (doc == null) return const Center(child: Text('Document not found'));
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
    return PdfViewer.uri(
      Uri.file(doc.filePath),
      controller: _pdfController,
      params: PdfViewerParams(
        enableTextSelection: true,
        onTextSelectionChange: (selection) {
          if (selection != null && selection.text.isNotEmpty) {
            _showWordPopup(selection.text, doc.id);
          }
        },
        onPageChanged: (page) {
          setState(() {
            _currentPage = page?.pageNumber ?? 0;
          });
          _saveProgress(doc);
        },
        onDocumentChanged: (document) {
          setState(() {
            _totalPages = document?.pages.length ?? 0;
          });
        },
        viewerOverlayBuilder: (context, size, handleLinkTap) => [
          PdfViewerScrollbar(
            controller: _pdfController!,
          ),
        ],
      ),
    );
  }

  Widget _buildEpubReader(Document doc) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: const Center(
          child: Text(
            'EPUB reader will be rendered here.\nEPUB parsing requires additional setup.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildTextReader(Document doc) {
    return FutureBuilder<String>(
      future: _readTextFile(doc.filePath),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return GestureDetector(
          onTapUp: (details) => _handleTextTap(details, doc),
          child: SingleChildScrollView(
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
          ),
        );
      },
    );
  }

  Future<String> _readTextFile(String path) async {
    try {
      final file = await Future.delayed(
        Duration.zero,
        () => Uri.file(path),
      );
      return '';
    } catch (e) {
      return 'Error reading file: $e';
    }
  }

  void _showWordPopup(String selectedText, int documentId) {
    final word = selectedText.trim().split(RegExp(r'\s+')).first;
    if (word.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => WordPopup(
        word: word,
        documentId: documentId,
      ),
    );
  }

  void _handleTextTap(TapUpDetails details, Document doc) {
    // Text selection handling for non-PDF files
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
