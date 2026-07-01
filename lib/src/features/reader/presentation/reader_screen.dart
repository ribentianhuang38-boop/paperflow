import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:epubx/epubx.dart';
import 'package:paperflow/src/features/library/domain/document.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

import 'package:paperflow/src/common/providers.dart';
import '../../library/domain/document.dart';
import '../../library/presentation/library_screen.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  final int documentId;
  const ReaderScreen({super.key, required this.documentId});

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  int _currentPage = 0;
  int _totalPages = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<Document?>(
          future: _loadDoc(),
          builder: (ctx, snap) => Text(
            snap.data?.title ?? 'Reader',
            maxLines: 1, overflow: TextOverflow.ellipsis,
          ),
        ),
        actions: [
          if (_totalPages > 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text('$_currentPage / $_totalPages',
                    style: Theme.of(context).textTheme.bodySmall),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.quiz_outlined),
            tooltip: 'Start Review',
            onPressed: () => context.push('/recall/${widget.documentId}'),
          ),
        ],
      ),
      body: FutureBuilder<Document?>(
        future: _loadDoc(),
        builder: (ctx, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final doc = snap.data!;
          return _buildReader(doc);
        },
      ),
    );
  }

  Future<Document?> _loadDoc() async {
    final repo = await ref.read(documentRepositoryProvider.future);
    return repo.getDocumentById(widget.documentId);
  }

  Widget _buildReader(Document doc) {
    switch (doc.fileType) {
      case 'pdf': return _buildPdfReader(doc);
      case 'epub': return _buildEpubReader(doc);
      case 'md': case 'html': case 'txt': return _buildTextReader(doc);
      default: return const Center(child: Text('Unsupported file type'));
    }
  }

  Widget _buildPdfReader(Document doc) {
    final file = File(doc.filePath);
    if (!file.existsSync()) return const Center(child: Text('PDF file not found'));
    return PDFView(
      filePath: doc.filePath,
      enableSwipe: true,
      autoSpacing: true,
      pageFling: true,
      onRender: (pages) => setState(() => _totalPages = pages ?? 0),
      onPageChanged: (page, total) {
        setState(() { _currentPage = page ?? 0; _totalPages = total ?? 0; });
        _saveProgress(doc);
      },
    );
  }

  Widget _buildEpubReader(Document doc) {
    return FutureBuilder<String>(
      future: _loadEpub(doc.filePath),
      builder: (ctx, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: SelectableText(snap.data!,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6, fontSize: 18)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextReader(Document doc) {
    return FutureBuilder<String>(
      future: File(doc.filePath).readAsString(),
      builder: (ctx, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: SelectableText(snap.data!,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6, fontSize: 18)),
            ),
          ),
        );
      },
    );
  }

  Future<String> _loadEpub(String filePath) async {
    try {
      final bytes = await File(filePath).readAsBytes();
      final book = await EpubReader.readBook(bytes);
      final buffer = StringBuffer();
      for (final chapter in book.Chapters ?? []) {
        if (chapter.Title != null) buffer.writeln('\n${chapter.Title}\n');
        if (chapter.HtmlContent != null) {
          buffer.writeln(chapter.HtmlContent!
              .replaceAll(RegExp(r'<[^>]*>'), '')
              .replaceAll('&nbsp;', ' ')
              .replaceAll('&amp;', '&')
              .trim());
          buffer.writeln();
        }
      }
      return buffer.toString().isEmpty ? 'Could not parse EPUB' : buffer.toString();
    } catch (e) { return 'Error loading EPUB: $e'; }
  }

  void _saveProgress(Document doc) {
    if (_totalPages > 0) {
      ref.read(documentRepositoryProvider.future).then((repo) {
        repo.updateProgress(doc.id, _currentPage / _totalPages);
        repo.updateLastReadTime(doc.id);
      });
    }
  }
}
