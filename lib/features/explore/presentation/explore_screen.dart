import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle, SystemNavigator;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';

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
  String _currentUrl = '';
  String _currentTitle = '';
  bool _isLoading = false;
  bool _isExtracting = false;
  double _progress = 0;
  double? _dragStartX;

  bool get _isShowingHub {
    return _currentUrl.isEmpty ||
        _currentUrl.contains('assets/explore/index.html') ||
        _currentUrl.startsWith('file://');
  }

  @override
  void initState() {
    super.initState();
    _initWebView();
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
              _isLoading = true;
              _progress = 0;
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

            // If loading the local explore hub, read sites.json and inject it
            if (url.contains('assets/explore/index.html') || url.startsWith('file://')) {
              try {
                final jsonStr = await rootBundle.loadString('assets/explore/sites.json');
                await _webViewController.runJavaScript('window.initExplore($jsonStr);');
              } catch (e) {
                debugPrint("Error injecting sites.json: $e");
              }
            } else {
              // Inject Readability.js into the external page for reading mode
              try {
                final browser = ref.read(browserServiceProvider);
                final injectScript = await browser.getInjectScript();
                await _webViewController.runJavaScript(injectScript);
              } catch (_) {}
            }
          },
          onProgress: (progress) {
            setState(() => _progress = progress / 100);
          },
        ),
      )
      ..addJavaScriptChannel(
        'ExploreChannel',
        onMessageReceived: (JavaScriptMessage message) {
          try {
            final json = jsonDecode(message.message);
            final action = json['action'] as String;
            if (action == 'navigate') {
              final targetUrl = json['url'] as String;
              _webViewController.loadRequest(Uri.parse(targetUrl));
            }
          } catch (e) {
            debugPrint("ExploreChannel Error: $e");
          }
        },
      )
      ..loadFlutterAsset('assets/explore/index.html');
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
    } else if (host.contains('pubmed.ncbi.nlm.nih.gov')) {
      return PubmedAdapter();
    }
    return GenericAdapter();
  }

  Future<void> _captureArticle() async {
    if (_isExtracting || _isShowingHub) return;
    setState(() => _isExtracting = true);

    try {
      final browser = ref.read(browserServiceProvider);
      
      // Double check that Readability.js is loaded
      final injectScript = await browser.getInjectScript();
      await _webViewController.runJavaScript(injectScript);

      // Run extraction
      final extractScript = browser.getExtractScript();
      final result = await _webViewController.runJavaScriptReturningResult(extractScript);
      
      String jsonStr = result.toString();
      // Remove enclosing quotes if returned as raw string literal representation
      if (jsonStr.startsWith('"') && jsonStr.endsWith('"')) {
        try {
          jsonStr = jsonDecode(jsonStr) as String;
        } catch (_) {}
      }

      final articleData = jsonDecode(jsonStr) as Map<String, dynamic>;
      if (articleData.containsKey('error')) {
        throw Exception(articleData['error']);
      }

      final adapter = _selectAdapter(_currentUrl);
      final parsedArticle = adapter.adapt(articleData, _currentUrl);
      
      final docTitle = parsedArticle.title.isNotEmpty ? parsedArticle.title : _currentTitle;
      final articleWithMeta = parsedArticle.copyWith(
        title: docTitle,
        source: _currentUrl,
      );

      final repo = ref.read(articleRepositoryProvider);
      final savedId = await repo.saveArticle(articleWithMeta);
      
      if (mounted) {
        setState(() => _isExtracting = false);
        context.push('/reader/$savedId');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isExtracting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('无法识别为可阅读文章: $e'),
            backgroundColor: ColorTokens.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget webViewContent = WebViewWidget(controller: _webViewController);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final canGoBack = await _webViewController.canGoBack();
        if (canGoBack) {
          await _webViewController.goBack();
        } else if (!_isShowingHub) {
          await _webViewController.loadFlutterAsset('assets/explore/index.html');
        } else {
          // If we are showing the local hub and cannot go back in WebView history,
          // go to the default Library screen tab if we aren't there yet, or pop out.
          if (context.mounted) {
            final state = GoRouterState.of(context);
            if (state.matchedLocation != '/') {
              context.go('/');
            } else {
              SystemNavigator.pop();
            }
          }
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? Colors.black : const Color(0xFFFAFAFA),
        body: SafeArea(
          child: Column(
            children: [
              if (!_isShowingHub) _buildTopBrowserBar(isDark),
              if (_isLoading && _progress < 1.0)
                LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: ColorTokens.getDivider(isDark),
                  valueColor: const AlwaysStoppedAnimation(ColorTokens.accent),
                  minHeight: 2,
                ),
              Expanded(
                child: Stack(
                  children: [
                    webViewContent,
                    // Active edge swipe zone on the left margin (24px wide)
                    if (!_isShowingHub)
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        width: 24,
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onHorizontalDragStart: (details) {
                            _dragStartX = details.globalPosition.dx;
                          },
                          onHorizontalDragUpdate: (details) {
                            if (_dragStartX != null) {
                              final delta = details.globalPosition.dx - _dragStartX!;
                              if (delta > 80) {
                                _dragStartX = null; // Trigger once
                                _captureArticle();
                              }
                            }
                          },
                          onHorizontalDragEnd: (_) {
                            _dragStartX = null;
                          },
                          child: Container(
                            color: Colors.transparent,
                          ),
                        ),
                      ),
                    if (_isExtracting)
                      Container(
                        color: ColorTokens.getBackground(isDark).withOpacity(0.95),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildSkeletonLoader(isDark),
                              const SizedBox(height: 24),
                              Text(
                                'PaperFlow Reading Mode',
                                style: AppTypography.title3.copyWith(
                                  color: ColorTokens.getTextPrimary(isDark),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Extracting article text and figures...',
                                style: AppTypography.subheadline.copyWith(
                                  color: ColorTokens.getTextSecondary(isDark),
                                ),
                              ),
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
      ),
    );
  }

  Widget _buildTopBrowserBar(bool isDark) {
    final domain = Uri.tryParse(_currentUrl)?.host ?? _currentUrl;
    final displayDomain = domain.startsWith("www.") ? domain.substring(4) : domain;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: ColorTokens.getBackground(isDark),
        border: Border(
          bottom: BorderSide(
            color: ColorTokens.getDivider(isDark),
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              _webViewController.loadFlutterAsset('assets/explore/index.html');
            },
            child: Icon(
              LucideIcons.arrowLeft,
              size: 20,
              color: ColorTokens.getTextSecondary(isDark),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              displayDomain,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.subheadline.copyWith(
                color: ColorTokens.getTextPrimary(isDark),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: _captureArticle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: ColorTokens.accent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.bookOpen, size: 16, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    'Read',
                    style: AppTypography.caption1.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonLoader(bool isDark) {
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[900]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[800]! : Colors.grey[100]!,
      child: Column(
        children: [
          Container(width: 220, height: 16, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 12),
          Container(width: 170, height: 12, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 12),
          Container(width: 270, height: 12, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
        ],
      ),
    );
  }
}
