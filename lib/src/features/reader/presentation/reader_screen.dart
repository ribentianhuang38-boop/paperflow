import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:epubx/epubx.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:dio/dio.dart';

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
      ),
      body: FutureBuilder<Document?>(
        future: _loadDoc(),
        builder: (ctx, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final doc = snap.data!;
          return Stack(
            children: [
              _buildNativeReader(doc, isDark),
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



  // Native reader for text-based formats
  Widget _buildNativeReader(Document doc, bool isDark) {
    switch (doc.fileType) {
      case 'pdf':
        return _buildPdfView(doc, isDark);
      case 'epub':
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
    return PDFView(
      filePath: doc.filePath,
      enableSwipe: true,
      swipeHorizontal: false,
      autoSpacing: true,
      pageFling: true,
      onError: (error) {
        debugPrint('PDFView error: $error');
      },
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



  Widget _buildHtmlTextView(Document doc, bool isDark) {
    return FutureBuilder<String>(
      future: _prepareHtmlContent(doc),
      builder: (ctx, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        
        final htmlContent = snap.data!;
        
        final controller = WebViewController();
        controller
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setBackgroundColor(isDark ? Colors.black : Colors.white)
          ..addJavaScriptChannel(
            'DictionaryChannel',
            onMessageReceived: (JavaScriptMessage message) {
              final word = message.message.trim();
              if (word.isNotEmpty) {
                _showWordLookupDialog(context, word, doc.id);
              }
            },
          )
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageFinished: (_) {
                controller.runJavaScript('''
                  document.addEventListener('dblclick', function(e) {
                    var sel = window.getSelection().toString().trim();
                    if (sel && /^[a-zA-Z\\'-]+\$/.test(sel)) {
                      DictionaryChannel.postMessage(sel);
                    }
                  });
                ''');

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

  Future<Map<String, dynamic>?> _lookupDictionary(String word) async {
    try {
      final dio = Dio();
      final response = await dio.get('https://api.dictionaryapi.dev/api/v2/entries/en/$word')
          .timeout(const Duration(seconds: 3));
      if (response.statusCode == 200 && response.data is List && (response.data as List).isNotEmpty) {
        final entry = (response.data as List).first;
        final wordText = entry['word'] ?? word;
        final phonetic = entry['phonetic'] ?? '';
        final meanings = entry['meanings'] as List?;
        
        String definition = '';
        String pos = '';
        
        if (meanings != null && meanings.isNotEmpty) {
          final firstMeaning = meanings.first;
          pos = firstMeaning['partOfSpeech'] ?? '';
          final definitions = firstMeaning['definitions'] as List?;
          if (definitions != null && definitions.isNotEmpty) {
            definition = definitions.first['definition'] ?? '';
          }
        }
        
        return {
          'word': wordText,
          'phonetic': phonetic,
          'pos': pos,
          'definition': definition,
        };
      }
    } catch (e) {
      debugPrint('Dictionary API error: $e');
    }
    return {
      'word': word,
      'phonetic': '',
      'pos': 'word',
      'definition': 'Definition not found online. Tap Bookmark to save to your local vocabulary.',
    };
  }

  void _showWordLookupDialog(BuildContext context, String word, int documentId) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cleanWord = word.toLowerCase().trim();
    
    final vocabDao = await ref.read(vocabularyDaoProvider.future);
    final existingVocab = await vocabDao.getVocabularyByWord(cleanWord);
    
    if (existingVocab != null) {
      await vocabDao.updateQueryInfo(existingVocab['id']);
    }

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return FutureBuilder<Map<String, dynamic>?>(
          future: _lookupDictionary(cleanWord),
          builder: (context, snap) {
            final data = snap.data ?? {
              'word': cleanWord,
              'phonetic': '',
              'pos': 'word',
              'definition': snap.connectionState == ConnectionState.waiting 
                  ? 'Searching...' 
                  : 'Definition not found online. Tap Bookmark to save to your local vocabulary.',
            };

            final displayWord = data['word'] as String;
            final phonetic = data['phonetic'] as String;
            final pos = data['pos'] as String;
            final definition = data['definition'] as String;

            return StatefulBuilder(
              builder: (context, setModalState) {
                return FutureBuilder<Map<String, dynamic>?>(
                  future: vocabDao.getVocabularyByWord(cleanWord),
                  builder: (context, vocabSnap) {
                    final isSaved = vocabSnap.data != null;
                    final queryCount = vocabSnap.data?['queryCount'] ?? (existingVocab?['queryCount'] ?? 1);

                    return Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              width: 36,
                              height: 5,
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkDivider : AppColors.divider,
                                borderRadius: BorderRadius.circular(2.5),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      displayWord,
                                      style: AppTypography.largeTitle.copyWith(
                                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                        fontSize: 28,
                                      ),
                                    ),
                                    if (phonetic.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        phonetic,
                                        style: AppTypography.caption1.copyWith(
                                          color: AppColors.accent,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  isSaved ? Icons.star_rounded : Icons.star_outline_rounded,
                                  color: isSaved ? Colors.amber : (isDark ? AppColors.darkTextTertiary : AppColors.textTertiary),
                                  size: 28,
                                ),
                                onPressed: () async {
                                  if (isSaved) {
                                    final id = vocabSnap.data!['id'] as int;
                                    await vocabDao.deleteVocabulary(id);
                                  } else {
                                    await vocabDao.addWord(
                                      word: displayWord,
                                      definition: definition,
                                      pos: pos,
                                      documentId: documentId,
                                    );
                                  }
                                  setModalState(() {});
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          if (pos.isNotEmpty && pos != 'word') ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                pos.toUpperCase(),
                                style: AppTypography.caption1.copyWith(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          Text(
                            definition,
                            style: AppTypography.body.copyWith(
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                              fontSize: 16,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Icon(
                                Icons.remove_red_eye_outlined,
                                size: 16,
                                color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Looked up $queryCount time(s)',
                                style: AppTypography.caption1.copyWith(
                                  color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: queryCount > 2 
                                      ? AppColors.error.withOpacity(0.1) 
                                      : queryCount > 1 
                                          ? AppColors.warning.withOpacity(0.1) 
                                          : AppColors.success.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  queryCount > 2 
                                      ? 'Difficult Word' 
                                      : queryCount > 1 
                                          ? 'Needs Review' 
                                          : 'New Word',
                                  style: AppTypography.caption1.copyWith(
                                    color: queryCount > 2 
                                        ? AppColors.error 
                                        : queryCount > 1 
                                            ? AppColors.warning 
                                            : AppColors.success,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Future<String> _prepareHtmlContent(Document doc) async {
    final file = File(doc.filePath);
    if (!await file.exists()) return '<html><body>File not found</body></html>';
    
    final content = await file.readAsString();
    
    final stylesheet = '''
      <style>
        * {
          max-width: 100%;
          box-sizing: border-box;
        }
        body {
          font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Source Serif 4", Georgia, serif;
          font-size: 19px;
          line-height: 1.75;
          color: #1c1c1e;
          background-color: #fafafb;
          margin: 0;
          padding: 24px 24px 120px 24px;
          word-wrap: break-word;
          overflow-wrap: break-word;
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
        h1, h2, h3, h4, h5, h6, p, ul, ol, li, blockquote, pre, code {
          word-wrap: break-word;
          overflow-wrap: break-word;
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
    } else if (doc.fileType == 'epub') {
      final epubHtml = await _loadEpubHtml(doc.filePath);
      return '<html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">$stylesheet</head><body><article>$epubHtml</article></body></html>';
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
        } else if (p.startsWith('---') || p.startsWith('***') || p.startsWith('___') || p.startsWith('===')) {
          buf.writeln('<hr>');
        } else {
          buf.writeln('<p>$p</p>');
        }
      }
      
      buf.writeln('</article></body></html>');
      return buf.toString();
    }
  }

  Future<String> _loadEpubHtml(String path) async {
    try {
      final bytes = await File(path).readAsBytes();
      final book = await EpubReader.readBook(bytes).timeout(const Duration(seconds: 5));
      final buf = StringBuffer();
      for (final ch in book.Chapters ?? []) {
        if (ch.Title != null) buf.writeln('<h2>${ch.Title}</h2>');
        if (ch.HtmlContent != null) {
          buf.writeln(ch.HtmlContent!);
        }
      }
      return buf.toString();
    } catch (e) {
      debugPrint('Epub loading error: $e');
      return '<html><body>Error loading EPUB: $e</body></html>';
    }
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
