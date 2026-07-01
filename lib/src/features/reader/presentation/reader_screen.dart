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
                  '${_currentPage + 1} / $_totalPages',
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
          return Stack(
            children: [
              _buildReader(snap.data!, isDark),
              // Bottom action bar
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildBottomBar(context, snap.data!, isDark),
              ),
            ],
          );
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

  Widget _buildBottomBar(BuildContext context, Document doc, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: BoxDecoration(
        color: (isDark ? AppColors.darkSurface : AppColors.surface).withOpacity(0.96),
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkDivider : AppColors.divider,
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Progress indicator
            if (doc.progress > 0) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceSecondary : AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${(doc.progress * 100).round()}%',
                  style: AppTypography.caption1.copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            // Start Review button
            Expanded(
              child: GestureDetector(
                onTap: () => context.push('/recall/${doc.id}'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.quiz_outlined, size: 18, color: Colors.white),
                      const SizedBox(width: 8),
                      Text('Start Review', style: AppTypography.headline.copyWith(color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Mastery button
            GestureDetector(
              onTap: () => context.push('/mastery/${doc.id}'),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceSecondary : AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.trending_up, size: 22,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
              ),
            ),
          ],
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
