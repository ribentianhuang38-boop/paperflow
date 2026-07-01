import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:epubx/epubx.dart';

import 'package:paperflow/src/common/providers.dart';
import '../../../common/theme/colors.dart';
import '../../../common/theme/typography.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: FutureBuilder<Document?>(
          future: _loadDoc(),
          builder: (ctx, snap) => Text(
            snap.data?.title ?? '',
            style: AppTypography.subheadline.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          if (_totalPages > 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  '$_currentPage / $_totalPages',
                  style: AppTypography.caption1.copyWith(
                    color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: FutureBuilder<Document?>(
        future: _loadDoc(),
        builder: (ctx, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          return _buildReader(snap.data!, isDark);
        },
      ),
    );
  }

  Future<Document?> _loadDoc() async {
    final repo = await ref.read(documentRepositoryProvider.future);
    return repo.getDocumentById(widget.documentId);
  }

  Widget _buildReader(Document doc, bool isDark) {
    switch (doc.fileType) {
      case 'pdf': return _buildPdf(doc);
      case 'epub': return _buildEpub(doc, isDark);
      case 'md': case 'html': case 'txt': return _buildText(doc, isDark);
      default: return Center(child: Text('Unsupported', style: AppTypography.bodySans));
    }
  }

  Widget _buildPdf(Document doc) {
    if (!File(doc.filePath).existsSync()) {
      return const Center(child: Text('File not found'));
    }
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

  Widget _buildEpub(Document doc, bool isDark) {
    return FutureBuilder<String>(
      future: _loadEpub(doc.filePath),
      builder: (ctx, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        return _buildReaderContent(snap.data!, isDark);
      },
    );
  }

  Widget _buildText(Document doc, bool isDark) {
    return FutureBuilder<String>(
      future: File(doc.filePath).readAsString(),
      builder: (ctx, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        return _buildReaderContent(snap.data!, isDark);
      },
    );
  }

  Widget _buildReaderContent(String content, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: SelectableText(
            content,
            style: AppTypography.body.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              fontSize: 18,
              height: 1.7,
            ),
          ),
        ),
      ),
    );
  }

  Future<String> _loadEpub(String path) async {
    try {
      final bytes = await File(path).readAsBytes();
      final book = await EpubReader.readBook(bytes);
      final buf = StringBuffer();
      for (final ch in book.Chapters ?? []) {
        if (ch.Title != null) buf.writeln('\n${ch.Title}\n');
        if (ch.HtmlContent != null) {
          buf.writeln(ch.HtmlContent!
              .replaceAll(RegExp(r'<[^>]*>'), '')
              .replaceAll('&nbsp;', ' ')
              .replaceAll('&amp;', '&')
              .trim());
          buf.writeln();
        }
      }
      return buf.toString().isEmpty ? 'Could not parse EPUB' : buf.toString();
    } catch (e) { return 'Error: $e'; }
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
