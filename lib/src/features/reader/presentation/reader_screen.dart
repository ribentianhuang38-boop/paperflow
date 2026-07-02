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
  final int? initialParagraphIdx;
  const ReaderScreen({super.key, required this.documentId, this.initialParagraphIdx});

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
        return _buildHtmlTextView(doc, isDark);
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

  final List<GlobalKey> _paragraphKeys = [];

  Widget _buildParagraphReader(String content, bool isDark) {
    final rawParagraphs = content.split(RegExp(r'\n{2,}'))
        .map((p) => p.trim())
        .where((p) => p.length > 50)
        .toList();

    if (rawParagraphs.isEmpty) {
      final lines = content.split('\n')
          .map((l) => l.trim())
          .where((l) => l.length > 50)
          .toList();
      rawParagraphs.addAll(lines);
    }

    if (rawParagraphs.isEmpty && content.trim().length > 20) {
      rawParagraphs.add(content.trim().substring(0, content.trim().length.clamp(0, 2000)));
    }

    if (_paragraphKeys.length != rawParagraphs.length) {
      _paragraphKeys.clear();
      for (int i = 0; i < rawParagraphs.length; i++) {
        _paragraphKeys.add(GlobalKey());
      }
    }

    if (widget.initialParagraphIdx != null && 
        widget.initialParagraphIdx! >= 0 && 
        widget.initialParagraphIdx! < _paragraphKeys.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final key = _paragraphKeys[widget.initialParagraphIdx!];
        if (key.currentContext != null) {
          Scrollable.ensureVisible(
            key.currentContext!,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
          );
        }
      });
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(rawParagraphs.length, (idx) {
              final isHighlighted = widget.initialParagraphIdx == idx;
              return Container(
                key: _paragraphKeys[idx],
                margin: const EdgeInsets.only(bottom: 24),
                padding: isHighlighted ? const EdgeInsets.all(16) : EdgeInsets.zero,
                decoration: isHighlighted
                    ? BoxDecoration(
                        color: isDark 
                            ? AppColors.darkSurfaceSecondary.withOpacity(0.4) 
                            : AppColors.surfaceSecondary.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.accent, width: 1.5),
                      )
                    : null,
                child: SelectionArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isHighlighted) ...[
                        Row(
                          children: [
                            const Icon(Icons.info_outline, size: 14, color: AppColors.accent),
                            const SizedBox(width: 6),
                            Text(
                              'Review Target (Paragraph ${idx + 1})',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                color: AppColors.accent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      Text(
                        rawParagraphs[idx],
                        style: AppTypography.body.copyWith(
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          fontSize: 18,
                          height: 1.75,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildEpubView(Document doc, bool isDark) {
    return FutureBuilder<String>(
      future: _loadEpubText(doc.filePath),
      builder: (ctx, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        return _buildParagraphReader(snap.data!, isDark);
      },
    );
  }

  Widget _buildHtmlTextView(Document doc, bool isDark) {
    return FutureBuilder<String>(
      future: _prepareHtmlContent(doc),
      builder: (ctx, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        
        final htmlContent = snap.data!;
        
        final controller = WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setBackgroundColor(isDark ? Colors.black : Colors.white)
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageFinished: (_) {
                if (widget.initialParagraphIdx != null) {
                  final idx = widget.initialParagraphIdx!;
                  controller.runJavaScript('''
                    (function() {
                      var paragraphs = document.querySelectorAll('p');
                      if (paragraphs && paragraphs.length > $idx) {
                        var target = paragraphs[$idx];
                        target.scrollIntoView({behavior: 'smooth', block: 'center'});
                        target.classList.add('highlight-paragraph');
                      }
                    })();
                  ''');
                }
              },
            ),
          )
          ..loadHtmlString(htmlContent);

        return WebViewWidget(controller: controller);
      },
    );
  }

  Future<String> _prepareHtmlContent(Document doc) async {
    final file = File(doc.filePath);
    if (!await file.exists()) return '<html><body>File not found</body></html>';
    
    final content = await file.readAsString();
    
    final stylesheet = '''
      <style>
        body {
          font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Source Serif 4", Georgia, serif;
          font-size: 19px;
          line-height: 1.75;
          color: #1c1c1e;
          background-color: #fafafb;
          margin: 0;
          padding: 24px 24px 120px 24px;
        }
        @media (prefers-color-scheme: dark) {
          body {
            color: #f5f5f7;
            background-color: #000000;
          }
        }
        article {
          max-width: 640px;
          margin: 0 auto;
        }
        h1 {
          font-size: 28px;
          font-weight: 700;
          line-height: 1.3;
          margin-top: 16px;
          margin-bottom: 12px;
        }
        h2 {
          font-size: 22px;
          font-weight: 600;
          margin-top: 24px;
          margin-bottom: 12px;
        }
        .author, .site {
          font-size: 14px;
          color: #8e8e93;
          margin: 4px 0;
        }
        hr {
          border: 0;
          border-top: 1px solid #e5e5ea;
          margin: 20px 0;
        }
        @media (prefers-color-scheme: dark) {
          hr {
            border-top: 1px solid #38383a;
          }
        }
        p {
          margin-bottom: 24px;
        }
        img {
          max-width: 100%;
          height: auto;
          border-radius: 12px;
          margin: 16px 0;
        }
        blockquote {
          border-left: 3px solid #007aff;
          padding-left: 16px;
          margin: 20px 0;
          font-style: italic;
          color: #8e8e93;
        }
        .highlight-paragraph {
          background-color: rgba(0, 122, 255, 0.15);
          border-left: 4px solid #007aff;
          padding-left: 12px;
          padding-top: 8px;
          padding-bottom: 8px;
          border-radius: 4px;
        }
      </style>
    ''';

    if (doc.fileType == 'html') {
      if (content.contains('</head>')) {
        return content.replaceFirst('</head>', '$stylesheet</head>');
      }
      return '<html><head>$stylesheet</head><body><article>$content</article></body></html>';
    } else {
      final paragraphs = content.split(RegExp(r'\n{2,}'))
          .map((p) => p.trim())
          .where((p) => p.isNotEmpty)
          .toList();
      
      final buf = StringBuffer();
      buf.writeln('<!DOCTYPE html><html><head><meta charset="utf-8">');
      buf.writeln('<meta name="viewport" content="width=device-width, initial-scale=1">');
      buf.writeln(stylesheet);
      buf.writeln('</head><body><article>');
      buf.writeln('<h1>${doc.title}</h1><hr>');
      
      for (final p in paragraphs) {
        if (p.startsWith('# ')) {
          buf.writeln('<h1>${p.substring(2)}</h1>');
        } else if (p.startsWith('## ')) {
          buf.writeln('<h2>${p.substring(3)}</h2>');
        } else if (p.startsWith('- ')) {
          buf.writeln('<ul><li>${p.substring(2)}</li></ul>');
        } else {
          buf.writeln('<p>$p</p>');
        }
      }
      
      buf.writeln('</article></body></html>');
      return buf.toString();
    }
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
