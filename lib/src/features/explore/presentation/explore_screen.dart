import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';

import 'package:paperflow/src/common/providers.dart';
import '../../../common/theme/colors.dart';
import '../../../common/theme/typography.dart';
import '../domain/article.dart';
import '../data/article_adapter.dart';
import '../../library/presentation/library_screen.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  InAppWebViewController? _webViewController;
  final TextEditingController _urlController = TextEditingController();
  final ReadabilityInjector _injector = ReadabilityInjector();
  String _currentUrl = '';
  String _currentTitle = '';
  bool _isLoading = false;
  bool _isExtracting = false;
  double _progress = 0;
  String? _injectScript;

  @override
  void initState() {
    super.initState();
    _loadReadability();
  }

  Future<void> _loadReadability() async {
    _injectScript = await _injector.getInjectScript();
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // URL bar
            _buildUrlBar(isDark),

            // Progress
            if (_isLoading)
              LinearProgressIndicator(
                value: _progress,
                backgroundColor: isDark ? AppColors.darkDivider : AppColors.divider,
                valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                minHeight: 2,
              ),

            // WebView
            Expanded(
              child: Stack(
                children: [
                  InAppWebView(
                    initialUrlRequest: URLRequest(
                      url: WebUri('https://arxiv.org'),
                    ),
                    initialSettings: InAppWebViewSettings(
                      javaScriptEnabled: true,
                      useOnLoadResource: true,
                      useShouldOverrideUrlLoading: true,
                      mediaPlaybackRequiresUserGesture: false,
                      allowsInlineMediaPlayback: true,
                      supportZoom: true,
                      builtInZoomControls: false,
                      displayZoomControls: false,
                    ),
                    onWebViewCreated: (controller) {
                      _webViewController = controller;
                      controller.addJavaScriptHandler(
                        handlerName: 'onArticleExtracted',
                        callback: _onArticleExtracted,
                      );
                    },
                    onLoadStart: (controller, url) {
                      setState(() {
                        _currentUrl = url?.toString() ?? '';
                        _urlController.text = _currentUrl;
                        _isLoading = true;
                      });
                    },
                    onLoadStop: (controller, url) async {
                      setState(() {
                        _isLoading = false;
                        _currentUrl = url?.toString() ?? '';
                        _urlController.text = _currentUrl;
                      });
                      // Get title
                      final title = await controller.getTitle();
                      if (title != null) {
                        setState(() => _currentTitle = title);
                      }
                      // Inject Readability.js
                      if (_injectScript != null) {
                        await controller.evaluateJavascript(
                          source: _injectScript!,
                        );
                      }
                    },
                    onProgressChanged: (controller, progress) {
                      setState(() => _progress = progress / 100);
                    },
                    shouldOverrideUrlLoading: (controller, navigationAction) async {
                      return NavigationActionPolicy.ALLOW;
                    },
                  ),

                  // Capture gesture - left edge swipe
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: 24,
                    child: GestureDetector(
                      onHorizontalDragEnd: (details) {
                        if (details.primaryVelocity != null && details.primaryVelocity! > 100) {
                          _captureArticle();
                        }
                      },
                      child: Container(color: Colors.transparent),
                    ),
                  ),

                  // Extracting overlay
                  if (_isExtracting)
                    Container(
                      color: isDark ? AppColors.darkBackground.withOpacity(0.9) : AppColors.background.withOpacity(0.9),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 24),
                            Text('Preparing Reading...', style: AppTypography.title3.copyWith(
                              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                            )),
                            const SizedBox(height: 8),
                            Text('Extracting article content', style: AppTypography.subheadline.copyWith(
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            )),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUrlBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkDivider : AppColors.divider,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Back
          GestureDetector(
            onTap: () => _webViewController?.goBack(),
            child: Icon(Icons.arrow_back_ios, size: 18,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
          ),
          const SizedBox(width: 12),
          // URL input
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceSecondary : AppColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  if (_currentUrl.isNotEmpty)
                    Icon(Icons.lock_outline, size: 14,
                        color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary),
                  if (_currentUrl.isNotEmpty) const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _currentTitle.isNotEmpty ? _currentTitle : _currentUrl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption1.copyWith(
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Capture button
          GestureDetector(
            onTap: _captureArticle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.auto_stories, size: 16, color: Colors.white),
                  const SizedBox(width: 6),
                  Text('Read', style: AppTypography.caption1.copyWith(
                    color: Colors.white, fontWeight: FontWeight.w600,
                  )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _captureArticle() async {
    if (_webViewController == null || _injectScript == null) return;

    setState(() => _isExtracting = true);

    try {
      // First ensure Readability is injected
      await _webViewController!.evaluateJavascript(source: _injectScript!);

      // Wait a bit for the script to load
      await Future.delayed(const Duration(milliseconds: 500));

      // Run extraction
      await _webViewController!.evaluateJavascript(source: _injector.getExtractScript());
    } catch (e) {
      setState(() => _isExtracting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Extraction failed: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _onArticleExtracted(List<dynamic> args) async {
    if (args.isEmpty) return;

    try {
      final json = jsonDecode(args[0] as String) as Map<String, dynamic>;

      if (json.containsKey('error')) {
        setState(() => _isExtracting = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${json['error']}'), backgroundColor: AppColors.error),
          );
        }
        return;
      }

      final article = Article.fromJson(json);

      // Save as HTML file
      final appDir = await getApplicationDocumentsDirectory();
      final papersDir = Directory(p.join(appDir.path, 'papers'));
      if (!await papersDir.exists()) {
        await papersDir.create(recursive: true);
      }

      final uniqueName = '${const Uuid().v4()}.html';
      final destPath = p.join(papersDir.path, uniqueName);

      // Build a clean HTML from the article
      final cleanHtml = _buildCleanHtml(article);
      await File(destPath).writeAsString(cleanHtml);

      // Insert into database
      final repo = await ref.read(documentRepositoryProvider.future);
      final id = await repo.insertDocument({
        'title': article.title,
        'authors': article.author,
        'filePath': destPath,
        'fileType': 'html',
        'importDate': DateTime.now().millisecondsSinceEpoch,
      });

      ref.invalidate(documentsProvider);
      ref.invalidate(filteredDocumentsProvider);

      setState(() => _isExtracting = false);

      if (mounted) {
        // Navigate to reader
        context.push('/reader/$id');
      }
    } catch (e) {
      setState(() => _isExtracting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  String _buildCleanHtml(Article article) {
    final buffer = StringBuffer();
    buffer.writeln('<!DOCTYPE html>');
    buffer.writeln('<html><head>');
    buffer.writeln('<meta charset="utf-8">');
    buffer.writeln('<meta name="viewport" content="width=device-width, initial-scale=1">');
    buffer.writeln('<title>${_escapeHtml(article.title)}</title>');
    buffer.writeln('</head><body>');
    buffer.writeln('<article>');
    buffer.writeln('<h1>${_escapeHtml(article.title)}</h1>');
    if (article.author != null && article.author!.isNotEmpty) {
      buffer.writeln('<p class="author">${_escapeHtml(article.author!)}</p>');
    }
    if (article.siteName != null) {
      buffer.writeln('<p class="site">${_escapeHtml(article.siteName!)}</p>');
    }
    buffer.writeln('<hr>');

    // Use HTML content if available, otherwise text
    if (article.htmlContent != null && article.htmlContent!.isNotEmpty) {
      buffer.writeln(article.htmlContent!);
    } else if (article.textContent != null) {
      for (final section in article.sections) {
        buffer.writeln('<p>${_escapeHtml(section.content)}</p>');
      }
    }

    buffer.writeln('</article></body></html>');
    return buffer.toString();
  }

  String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;');
  }
}
