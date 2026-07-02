import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/app/providers.dart';
import '../../../core/design_system/color_tokens.dart';
import '../../../core/design_system/typography.dart';
import '../../../models/article/article.dart';
import '../../../models/article/highlight.dart';
import '../../../models/article/note.dart';
import 'widgets/dictionary_lookup_sheet.dart';
import 'widgets/image_viewer_screen.dart';
import 'widgets/reader_actions_sheet.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  final int documentId;
  final int? initialParagraphIdx;
  
  const ReaderScreen({
    super.key,
    required this.documentId,
    this.initialParagraphIdx,
  });

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  Article? _article;
  List<Highlight> _highlights = [];
  List<Note> _notes = [];
  bool _isLoading = true;
  late DateTime _enterTime;
  late final WebViewController _webViewController;

  @override
  void initState() {
    super.initState();
    _enterTime = DateTime.now();
    _loadArticleData();
  }

  @override
  void dispose() {
    final focusSec = DateTime.now().difference(_enterTime).inSeconds;
    ref.read(settingsRepositoryProvider).addReadingTime(focusSec);
    super.dispose();
  }

  Future<void> _loadArticleData() async {
    final repo = ref.read(articleRepositoryProvider);
    final art = await repo.getArticleById(widget.documentId);
    if (art != null) {
      await repo.updateLastRead(widget.documentId);
      final hls = await repo.getHighlightsForArticle(widget.documentId);
      final nts = await repo.getNotesForArticle(widget.documentId);
      setState(() {
        _article = art;
        _highlights = hls;
        _notes = nts;
        _isLoading = false;
      });
    }
  }

  String _getParagraphText(Article article, int index) {
    int current = 0;
    for (final sec in article.sections) {
      for (final p in sec.paragraphs) {
        if (current == index) return p.text;
        current++;
      }
    }
    return '';
  }

  void _scrollToParagraph(int idx) {
    _webViewController.runJavaScript('''
      (function() {
        var paragraphs = document.querySelectorAll('p');
        if (paragraphs && paragraphs.length > $idx) {
          var target = paragraphs[$idx];
          target.scrollIntoView({behavior: 'smooth', block: 'center'});
          target.classList.add('highlight-paragraph');
          setTimeout(() => {
            target.classList.remove('highlight-paragraph');
          }, 2000);
        }
      })();
    ''');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: ColorTokens.getBackground(isDark),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_article == null) {
      return Scaffold(
        backgroundColor: ColorTokens.getBackground(isDark),
        appBar: AppBar(),
        body: const Center(child: Text('Document not found')),
      );
    }

    final article = _article!;

    return Scaffold(
      backgroundColor: ColorTokens.getBackground(isDark),
      appBar: AppBar(
        title: Text(
          article.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.subheadline.copyWith(
            color: ColorTokens.getTextSecondary(isDark),
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          _buildWebView(article, isDark),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomBar(context, article, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildWebView(Article article, bool isDark) {
    final htmlContent = _buildHtmlFromArticle(article, _highlights, _notes, isDark);
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(isDark ? Colors.black : Colors.white)
      ..addJavaScriptChannel(
        'DictionaryChannel',
        onMessageReceived: (JavaScriptMessage message) {
          final word = message.message.trim();
          if (word.isNotEmpty) {
            _showWordLookupDialog(context, word, article.id!);
          }
        },
      )
      ..addJavaScriptChannel(
        'SelectionChannel',
        onMessageReceived: (JavaScriptMessage message) {
          try {
            final json = jsonDecode(message.message);
            final text = json['text'] as String;
            final paragraphIdx = json['paragraphIdx'] as int;
            final offset = json['offset'] as int;
            final length = json['length'] as int;
            
            showModalBottomSheet(
              context: context,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
              builder: (ctx) => ProviderScope(
                parent: ProviderScope.containerOf(context),
                child: HighlightOptionsSheet(
                  articleId: article.id!,
                  paragraphId: paragraphIdx,
                  offset: offset,
                  length: length,
                  text: text,
                  onReload: _loadArticleData,
                ),
              ),
            );
          } catch (_) {}
        },
      )
      ..addJavaScriptChannel(
        'HighlightClickChannel',
        onMessageReceived: (JavaScriptMessage message) {
          final id = int.tryParse(message.message);
          if (id != null) {
            showModalBottomSheet(
              context: context,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
              builder: (ctx) => ProviderScope(
                parent: ProviderScope.containerOf(context),
                child: ModifyHighlightSheet(
                  highlightId: id,
                  onReload: _loadArticleData,
                ),
              ),
            );
          }
        },
      )
      ..addJavaScriptChannel(
        'NoteClickChannel',
        onMessageReceived: (JavaScriptMessage message) {
          final idx = int.tryParse(message.message);
          if (idx != null) {
            final text = _getParagraphText(article, idx);
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
              builder: (ctx) => ProviderScope(
                parent: ProviderScope.containerOf(context),
                child: NoteEditorSheet(
                  articleId: article.id!,
                  paragraphId: idx,
                  paragraphText: text,
                  onReload: _loadArticleData,
                ),
              ),
            );
          }
        },
      )
      ..addJavaScriptChannel(
        'ImageClickChannel',
        onMessageReceived: (JavaScriptMessage message) {
          final path = message.message.trim();
          if (path.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ImageViewerScreen(imagePath: path)),
            );
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            _webViewController.runJavaScript('''
              document.addEventListener('dblclick', function(e) {
                var sel = window.getSelection().toString().trim();
                if (sel && /^[a-zA-Z\\'-]+\$/.test(sel)) {
                  DictionaryChannel.postMessage(sel);
                }
              });

              document.addEventListener('mouseup', function() {
                var sel = window.getSelection();
                if (sel && sel.toString().trim().length > 0) {
                  var range = sel.getRangeAt(0);
                  var container = range.commonAncestorContainer;
                  while (container && container.nodeName !== 'P') {
                    container = container.parentNode;
                  }
                  if (container) {
                    var paragraphs = Array.from(document.querySelectorAll('p'));
                    var idx = paragraphs.indexOf(container);
                    if (idx !== -1) {
                      var preSelectionRange = range.cloneRange();
                      preSelectionRange.selectNodeContents(container);
                      preSelectionRange.setEnd(range.startContainer, range.startOffset);
                      var offset = preSelectionRange.toString().length;
                      var length = range.toString().length;
                      SelectionChannel.postMessage(JSON.stringify({
                        paragraphIdx: idx,
                        offset: offset,
                        length: length,
                        text: range.toString()
                      }));
                    }
                  }
                }
              });

              document.querySelectorAll('img').forEach(img => {
                img.addEventListener('click', function(e) {
                  e.stopPropagation();
                  ImageClickChannel.postMessage(img.src);
                });
              });

              document.querySelectorAll('table').forEach(table => {
                if (!table.parentElement.classList.contains('table-wrapper')) {
                  var wrapper = document.createElement('div');
                  wrapper.className = 'table-wrapper';
                  table.parentNode.insertBefore(wrapper, table);
                  wrapper.appendChild(table);
                }
              });
            ''');

            if (widget.initialParagraphIdx != null) {
              final idx = widget.initialParagraphIdx!;
              _webViewController.runJavaScript('''
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

    return WebViewWidget(controller: _webViewController);
  }

  String _buildHtmlFromArticle(Article article, List<Highlight> highlights, List<Note> notes, bool isDark) {
    final stylesheet = '''
      <style>
        body {
          background-color: ${isDark ? '#000000' : '#FFFFFF'};
          color: ${isDark ? '#F5F5F7' : '#111111'};
          font-family: 'Source Serif 4', serif;
          font-size: 18px;
          line-height: 1.8;
          margin: 0;
          padding: 24px 24px 140px 24px;
          user-select: text;
          -webkit-user-select: text;
        }
        article {
          max-width: 640px;
          margin: 0 auto;
        }
        h1 {
          font-family: 'Inter', sans-serif;
          font-size: 28px;
          font-weight: 700;
          margin-bottom: 8px;
          line-height: 1.3;
        }
        h2 {
          font-family: 'Inter', sans-serif;
          font-size: 22px;
          font-weight: 600;
          margin-top: 24px;
          margin-bottom: 12px;
        }
        p {
          margin-bottom: 24px;
          position: relative;
        }
        blockquote {
          border-left: 3px solid #666666;
          margin: 0 0 24px 0;
          padding-left: 16px;
          color: #666666;
        }
        .highlight-paragraph {
          background-color: rgba(79, 107, 255, 0.08);
          border-left: 3px solid #4f6bff;
          padding: 8px 12px;
          border-radius: 4px;
        }
        
        .hl-yellow { background-color: rgba(255, 235, 59, 0.35); border-bottom: 2px solid #fbc02d; }
        .hl-green { background-color: rgba(76, 175, 80, 0.3); border-bottom: 2px solid #388e3c; }
        .hl-blue { background-color: rgba(33, 150, 243, 0.3); border-bottom: 2px solid #1976d2; }
        .hl-pink { background-color: rgba(233, 30, 99, 0.3); border-bottom: 2px solid #c2185b; }
        
        .para-note-btn {
          color: #4f6bff;
          font-size: 11px;
          margin-left: 8px;
          cursor: pointer;
          opacity: 0.5;
          user-select: none;
          -webkit-user-select: none;
        }
        .para-note-btn.has-note {
          opacity: 1.0;
          font-weight: bold;
        }
        
        .table-wrapper {
          width: 100%;
          overflow-x: auto;
          margin: 20px 0;
          border-radius: 12px;
          border: 1px solid ${isDark ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.08)'};
        }
        table {
          width: 100%;
          border-collapse: collapse;
          font-size: 15px;
        }
        th, td {
          padding: 10px;
          border-bottom: 1px solid ${isDark ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.08)'};
          text-align: left;
        }
        th {
          background-color: ${isDark ? 'rgba(255,255,255,0.05)' : 'rgba(0,0,0,0.02)'};
          font-weight: bold;
        }
        
        img {
          max-width: 100%;
          height: auto;
          border-radius: 12px;
          cursor: zoom-in;
        }
      </style>
      <script>
        function onHighlightClick(e, id) {
          e.stopPropagation();
          HighlightClickChannel.postMessage(id.toString());
        }
        function onNoteClick(e, idx) {
          e.stopPropagation();
          NoteClickChannel.postMessage(idx.toString());
        }
      </script>
    ''';

    final buf = StringBuffer();
    buf.writeln('<!DOCTYPE html><html><head><meta charset="utf-8">');
    buf.writeln('<meta name="viewport" content="width=device-width, initial-scale=1">');
    buf.writeln(stylesheet);
    buf.writeln('</head><body><article>');
    buf.writeln('<h1>${article.title}</h1>');
    if (article.author != null) {
      buf.writeln('<p style="color: #666666; font-size: 14px;">${article.author}</p>');
    }
    buf.writeln('<hr style="border: 0; border-top: 1px solid ${isDark ? '#242426' : '#ececec'}; margin: 20px 0;">');

    int globalParagraphIdx = 0;
    for (final sec in article.sections) {
      if (sec.heading.isNotEmpty && sec.heading != 'Content') {
        buf.writeln('<h2>${sec.heading}</h2>');
      }
      for (final p in sec.paragraphs) {
        final isTarget = widget.initialParagraphIdx == globalParagraphIdx;
        final highlightClass = isTarget ? 'highlight-paragraph' : '';
        
        final paraHighlights = highlights.where((h) => h.paragraphId == globalParagraphIdx).toList();
        String renderedText = p.text;
        
        if (paraHighlights.isNotEmpty) {
          paraHighlights.sort((a, b) => b.offset.compareTo(a.offset));
          for (final hl in paraHighlights) {
            if (hl.offset >= 0 && hl.offset + hl.length <= renderedText.length) {
              final startText = renderedText.substring(0, hl.offset);
              final hlText = renderedText.substring(hl.offset, hl.offset + hl.length);
              final endText = renderedText.substring(hl.offset + hl.length);
              renderedText = '$startText<span class="hl-${hl.color}" onclick="onHighlightClick(event, ${hl.id})">$hlText</span>$endText';
            }
          }
        }
        
        final hasNote = notes.any((n) => n.paragraphId == globalParagraphIdx);
        
        buf.writeln('<p class="$highlightClass" data-index="$globalParagraphIdx">');
        buf.writeln(renderedText);
        buf.writeln('<span class="para-note-btn ${hasNote ? 'has-note' : ''}" onclick="onNoteClick(event, $globalParagraphIdx)">${hasNote ? '📝 Note' : '➕ Note'}</span>');
        buf.writeln('</p>');
        
        globalParagraphIdx++;
      }
    }

    buf.writeln('</article></body></html>');
    return buf.toString();
  }

  void _showWordLookupDialog(BuildContext context, String word, int documentId) async {
    final cleanWord = word.toLowerCase().trim();
    final vocabRepo = ref.read(vocabularyRepositoryProvider);
    final existing = await vocabRepo.getVocabularyByWord(cleanWord);
    if (existing != null) {
      await vocabRepo.updateQueryInfo(existing.id!);
    }

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return DictionaryLookupSheet(cleanWord: cleanWord, documentId: documentId);
      },
    );
  }

  void _showLookupWordManual() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ColorTokens.getBackground(isDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Look up Word', style: AppTypography.title3.copyWith(color: ColorTokens.getTextPrimary(isDark))),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: AppTypography.bodySans.copyWith(color: ColorTokens.getTextPrimary(isDark)),
          decoration: const InputDecoration(hintText: 'Enter word to search...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final w = ctrl.text.trim();
              Navigator.pop(ctx);
              if (w.isNotEmpty) {
                _showWordLookupDialog(context, w, widget.documentId);
              }
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void _showHighlightsList() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: ColorTokens.getBackground(isDark),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
              child: Text(
                'Highlights (${_highlights.length})',
                style: AppTypography.title3.copyWith(color: ColorTokens.getTextPrimary(isDark), fontWeight: FontWeight.bold),
              ),
            ),
            if (_highlights.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Center(
                  child: Text('No highlights in this paper.', style: AppTypography.bodySans.copyWith(color: ColorTokens.getTextSecondary(isDark))),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _highlights.length,
                  itemBuilder: (context, idx) {
                    final hl = _highlights[idx];
                    return ListTile(
                      leading: Container(
                        width: 12, height: 12,
                        decoration: BoxDecoration(
                          color: _hlColorVal(hl.color),
                          shape: BoxShape.circle,
                        ),
                      ),
                      title: Text(
                        'Paragraph ${hl.paragraphId + 1}',
                        style: AppTypography.headline.copyWith(color: ColorTokens.getTextPrimary(isDark)),
                      ),
                      subtitle: Text(
                        'Tap to navigate to highlighted section',
                        style: AppTypography.caption1.copyWith(color: ColorTokens.getTextSecondary(isDark)),
                      ),
                      onTap: () {
                        Navigator.pop(ctx);
                        _scrollToParagraph(hl.paragraphId);
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _hlColorVal(String name) {
    switch (name) {
      case 'green': return Colors.green;
      case 'blue': return Colors.blue;
      case 'pink': return Colors.pink;
      case 'yellow':
      default:
        return Colors.amber;
    }
  }

  void _showNotesList() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: ColorTokens.getBackground(isDark),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
              child: Text(
                'Notes (${_notes.length})',
                style: AppTypography.title3.copyWith(color: ColorTokens.getTextPrimary(isDark), fontWeight: FontWeight.bold),
              ),
            ),
            if (_notes.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Center(
                  child: Text('No notes in this paper.', style: AppTypography.bodySans.copyWith(color: ColorTokens.getTextSecondary(isDark))),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _notes.length,
                  itemBuilder: (context, idx) {
                    final note = _notes[idx];
                    return ListTile(
                      leading: Icon(LucideIcons.fileText, color: ColorTokens.accent, size: 18),
                      title: Text(
                        note.content,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.headline.copyWith(color: ColorTokens.getTextPrimary(isDark)),
                      ),
                      subtitle: Text(
                        'Paragraph ${note.paragraphId + 1}',
                        style: AppTypography.caption1.copyWith(color: ColorTokens.getTextSecondary(isDark)),
                      ),
                      onTap: () {
                        Navigator.pop(ctx);
                        _scrollToParagraph(note.paragraphId);
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, Article article, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: ColorTokens.getBackground(isDark).withOpacity(0.96),
        border: Border(
          top: BorderSide(color: ColorTokens.getDivider(isDark), width: 1.0),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _BottomBtn(
              icon: LucideIcons.search,
              label: 'Look up',
              isDark: isDark,
              onTap: _showLookupWordManual,
            ),
            _BottomBtn(
              icon: LucideIcons.edit3,
              label: 'Highlights',
              isDark: isDark,
              onTap: _showHighlightsList,
            ),
            _BottomBtn(
              icon: LucideIcons.fileText,
              label: 'Notes',
              isDark: isDark,
              onTap: _showNotesList,
            ),
            _BottomBtn(
              icon: LucideIcons.fileSpreadsheet,
              label: 'Review',
              isAccent: true,
              isDark: isDark,
              onTap: () {
                ref.read(settingsRepositoryProvider).incrementTodayPapersRead();
                context.push('/recall/${article.id}');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback onTap;
  final bool isAccent;

  const _BottomBtn({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
    this.isAccent = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isAccent ? ColorTokens.accent : ColorTokens.getTextSecondary(isDark);
    
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                fontWeight: isAccent ? FontWeight.bold : FontWeight.normal,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
