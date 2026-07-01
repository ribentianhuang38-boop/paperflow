import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';
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
  late WebViewController _webViewController;
  bool _isLoading = true;
  bool _useReadest = false;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) => setState(() => _isLoading = false),
        ),
      );
  }

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
          IconButton(
            icon: Icon(_useReadest ? Icons.chrome_reader_mode : Icons.menu_book),
            tooltip: _useReadest ? 'Native Reader' : 'Readest',
            onPressed: () => setState(() => _useReadest = !_useReadest),
          ),
        ],
      ),
      body: FutureBuilder<Document?>(
        future: _loadDoc(),
        builder: (ctx, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final doc = snap.data!;
          return Stack(
            children: [
              _useReadest ? _buildReadestView(doc, isDark) : _buildNativeReader(doc, isDark),
              Positioned(
                left: 0, right: 0, bottom: 0,
                child: _buildBottomBar(context, doc, isDark),
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

  // Readest WebView - loads web.readest.com
  Widget _buildReadestView(Document doc, bool isDark) {
    // For local files, we'd need to serve them via a local server
    // For now, use Readest's web app for supported formats
    final readestUrl = 'https://web.readest.com';

    return Stack(
      children: [
        WebViewWidget(controller: _webViewController),
        if (_isLoading)
          const Center(child: CircularProgressIndicator()),
      ],
    );
  }

  // Native reader for text-based formats
  Widget _buildNativeReader(Document doc, bool isDark) {
    switch (doc.fileType) {
      case 'pdf':
        return _buildPdfView(doc, isDark);
      case 'epub':
        return _buildEpubView(doc, isDark);
      case 'md': case 'html': case 'txt':
        return _buildTextView(doc, isDark);
      default:
        return Center(
          child: Text('Unsupported format: ${doc.fileType}',
              style: AppTypography.bodySans.copyWith(
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              )),
        );
    }
  }

  Widget _buildPdfView(Document doc, bool isDark) {
    if (!File(doc.filePath).existsSync()) {
      return const Center(child: Text('File not found'));
    }
    // Use a WebView to display PDF with pdf.js (like Readest does)
    return WebViewWidget(
      controller: WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..loadFile(doc.filePath),
    );
  }

  Widget _buildEpubView(Document doc, bool isDark) {
    // For EPUB, we'll use a WebView with Readest's rendering
    // For now, show a placeholder with extracted text
    return FutureBuilder<String>(
      future: _loadEpubText(doc.filePath),
      builder: (ctx, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: SelectableText(
                snap.data!,
                style: AppTypography.body.copyWith(
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  fontSize: 18, height: 1.7,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextView(Document doc, bool isDark) {
    return FutureBuilder<String>(
      future: File(doc.filePath).readAsString(),
      builder: (ctx, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: SelectableText(
                snap.data!,
                style: AppTypography.body.copyWith(
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  fontSize: 18, height: 1.7,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<String> _loadEpubText(String path) async {
    try {
      final bytes = await File(path).readAsBytes();
      final book = await EpubReader.readBook(bytes);
      final buf = StringBuffer();
      for (final ch in book.Chapters ?? []) {
        if (ch.Title != null) buf.writeln('\n${ch.Title}\n');
        if (ch.HtmlContent != null) {
          buf.writeln(ch.HtmlContent!
              .replaceAll(RegExp(r'<[^>]*>'), ' ')
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim());
          buf.writeln();
        }
      }
      return buf.toString().isEmpty ? 'Could not parse EPUB' : buf.toString();
    } catch (e) { return 'Error: $e'; }
  }

  Widget _buildBottomBar(BuildContext context, Document doc, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: BoxDecoration(
        color: (isDark ? AppColors.darkSurface : AppColors.surface).withOpacity(0.96),
        border: Border(
          top: BorderSide(color: isDark ? AppColors.darkDivider : AppColors.divider, width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (doc.progress > 0) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceSecondary : AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('${(doc.progress * 100).round()}%',
                    style: AppTypography.caption1.copyWith(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    )),
              ),
              const SizedBox(width: 12),
            ],
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
            GestureDetector(
              onTap: () => context.push('/mastery/${doc.id}'),
              child: Container(
                width: 48, height: 48,
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
}
