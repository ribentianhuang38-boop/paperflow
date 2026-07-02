import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../../core/app/providers.dart';
import '../../../core/design_system/color_tokens.dart';
import '../../../core/design_system/typography.dart';
import '../../../services/browser/browser_service.dart';
import '../../../services/importer/article_adapter/generic_adapter.dart';
import '../../../services/importer/article_adapter/nature_adapter.dart';
import '../../../services/importer/article_adapter/science_adapter.dart';
import '../../../services/importer/article_adapter/arxiv_adapter.dart';
import '../../../services/importer/article_adapter/cell_adapter.dart';
import '../../../services/importer/article_adapter/pubmed_adapter.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  late final WebViewController _webViewController;
  final TextEditingController _urlController = TextEditingController();
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
    final browser = ref.read(browserServiceProvider);
    _injectScript = await browser.getInjectScript();
  }

  void _initWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(BrowserService.mobileChromeUserAgent)
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
            if (_injectScript != null) {
              try {
                await _webViewController.runJavaScript(_injectScript!);
              } catch (_) {}
            }
          },
          onProgress: (progress) {
            setState(() => _progress = progress / 100);
          },
        ),
      )
      ..loadRequest(Uri.parse('https://arxiv.org'));
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  BaseArticleAdapter _selectAdapter(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return GenericAdapter();
    final host = uri.host.toLowerCase();
    if (host.contains('nature.com')) {
      return NatureAdapter();
    } else if (host.contains('science.org')) {
      return ScienceAdapter();
    } else if (host.contains('arxiv.org')) {
      return ArxivAdapter();
    } else if (host.contains('cell.com')) {
      return CellAdapter();
    } else if (host.contains('ncbi.nlm.nih.gov')) {
      return PubmedAdapter();
    }
    return GenericAdapter();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: ColorTokens.getBackground(isDark),
      body: SafeArea(
        child: Column(
          children: [
            _buildUrlBar(isDark),
            if (_isLoading)
              LinearProgressIndicator(
                value: _progress,
                backgroundColor: ColorTokens.getDivider(isDark),
                valueColor: const AlwaysStoppedAnimation(ColorTokens.accent),
                minHeight: 2,
              ),
            Expanded(
              child: Stack(
                children: [
                  WebViewWidget(controller: _webViewController),
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
                  if (_isExtracting)
                    Container(
                      color: ColorTokens.getBackground(isDark).withOpacity(0.92),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 24),
                            Text('Preparing Reading...', style: AppTypography.title3.copyWith(
                              color: ColorTokens.getTextPrimary(isDark),
                            )),
                            const SizedBox(height: 8),
                            Text('Extracting article content', style: AppTypography.subheadline.copyWith(
                              color: ColorTokens.getTextSecondary(isDark),
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
        color: ColorTokens.getSurface(isDark),
        border: Border(
          bottom: BorderSide(
            color: ColorTokens.getDivider(isDark),
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
                  color: ColorTokens.getTextSecondary(isDark)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              decoration: BoxDecoration(
                color: ColorTokens.getSurfaceSecondary(isDark),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock_outline, size: 14,
                      color: ColorTokens.getTextTertiary(isDark)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextField(
                      controller: _urlController,
                      style: AppTypography.caption1.copyWith(
                        color: ColorTokens.getTextPrimary(isDark),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search or enter URL',
                        hintStyle: AppTypography.caption1.copyWith(
                          color: ColorTokens.getTextTertiary(isDark),
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
                color: ColorTokens.accent,
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
    setState(() => _isExtracting = true);

    try {
      final browser = ref.read(browserServiceProvider);
      if (_injectScript != null) {
        await _webViewController.runJavaScript(_injectScript!);
        await Future.delayed(const Duration(milliseconds: 800));
      }

      final result = await _webViewController.runJavaScriptReturningResult(
        browser.getExtractScript(),
      );

      String jsonStr;
      if (result is String) {
        jsonStr = result;
      } else {
        jsonStr = result.toString();
      }

      if (jsonStr.startsWith('"') && jsonStr.endsWith('"')) {
        jsonStr = jsonDecode(jsonStr) as String;
      }

      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      if (json.containsKey('error')) {
        setState(() => _isExtracting = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${json['error']}'), backgroundColor: ColorTokens.error),
          );
        }
        return;
      }

      final url = _currentUrl;
      final adapter = _selectAdapter(url);
      final rawArticle = adapter.adapt(json, url);

      final importer = ref.read(importerServiceProvider);
      
      // Save web capture using the ImporterService
      final cleanContent = json['content'] as String? ?? '';
      final savedArticle = await importer.importCapturedWeb(
        title: rawArticle.title,
        content: cleanContent,
        url: url,
        author: rawArticle.author,
      );

      setState(() => _isExtracting = false);

      if (mounted) {
        context.push('/reader/${savedArticle.id}');
      }
    } catch (e) {
      setState(() => _isExtracting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Extraction failed: $e'), backgroundColor: ColorTokens.error),
        );
      }
    }
  }
}
