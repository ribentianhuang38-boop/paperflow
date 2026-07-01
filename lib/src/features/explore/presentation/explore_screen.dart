import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';
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
  late final WebViewController _webViewController;
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
    _initWebView();
  }

  Future<void> _loadReadability() async {
    _injectScript = await _injector.getInjectScript();
  }

  void _initWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() {
              _currentUrl = url;
              _urlController.text = url;
              _isLoading = true;
            });
          },
          onPageFinished: (url) async {
            setState(() {
              _isLoading = false;
              _currentUrl = url;
            });
            final title = await _webViewController.getTitle();
            if (title != null) {
              setState(() => _currentTitle = title);
            }
            // Inject Readability.js
            if (_injectScript != null) {
              await _webViewController.runJavaScript(_injectScript!);
            }
          },
          onProgress: (progress) {
            setState(() => _progress = progress / 100);
          },
        ),
      )
      ..addJavaScriptChannel(
        'onArticleExtracted',
        onMessageReceived: (message) => _onArticleExtracted(message.message),
      )
      ..loadRequest(Uri.parse('https://arxiv.org'));
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
            _buildUrlBar(isDark),
            if (_isLoading)
              LinearProgressIndicator(
                value: _progress,
                backgroundColor: isDark ? AppColors.darkDivider : AppColors.divider,
                valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                minHeight: 2,
              ),
            Expanded(
              child: Stack(
                children: [
                  WebViewWidget(controller: _webViewController),

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
                      color: isDark
                          ? AppColors.darkBackground.withOpacity(0.92)
                          : AppColors.background.withOpacity(0.92),
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
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
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
          GestureDetector(
            onTap: () => _webViewController.goBack(),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(Icons.arrow_back_ios, size: 18,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceSecondary : AppColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock_outline, size: 14,
                      color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextField(
                      controller: _urlController,
                      style: AppTypography.caption1.copyWith(
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search or enter URL',
                        hintStyle: AppTypography.caption1.copyWith(
                          color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        isDense: true,
                      ),
                      keyboardType: TextInputType.url,
                      textInputAction: TextInputAction.go,
                      onSubmitted: (value) {
                        String url = value.trim();
                        if (url.isEmpty) return;
                        if (!url.startsWith('http://') && !url.startsWith('https://')) {
                          if (url.contains('.') && !url.contains(' ')) {
                            url = 'https://$url';
                          } else {
                            url = 'https://www.google.com/search?q=${Uri.encodeComponent(url)}';
                          }
                        }
                        _webViewController.loadRequest(Uri.parse(url));
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _captureArticle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.auto_stories, size: 16, color: Colors.white),
                  const SizedBox(width: 4),
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
    if (_injectScript == null) return;

    setState(() => _isExtracting = true);

    try {
      // Ensure Readability is injected
      await _webViewController.runJavaScript(_injectScript!);
      await Future.delayed(const Duration(milliseconds: 500));

      // Run extraction
      await _webViewController.runJavaScript(_injector.getExtractScript());
    } catch (e) {
      setState(() => _isExtracting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Extraction failed: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _onArticleExtracted(String message) async {
    try {
      final json = jsonDecode(message) as Map<String, dynamic>;

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
