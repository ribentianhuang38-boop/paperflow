import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/app/providers.dart';
import '../../../core/design_system/color_tokens.dart';
import '../../../core/design_system/typography.dart';
import '../../../models/article/article.dart';
import '../widgets/report_widgets.dart';
import '../widgets/share_card.dart';

class ReviewResultScreen extends ConsumerStatefulWidget {
  final int sessionId;
  const ReviewResultScreen({super.key, required this.sessionId});

  @override
  ConsumerState<ReviewResultScreen> createState() => _ReviewResultScreenState();
}

class _ReviewResultScreenState extends ConsumerState<ReviewResultScreen> {
  bool _isStoryRatio = false;

  Future<Map<String, dynamic>> _loadData() async {
    final reviewRepo = ref.read(reviewRepositoryProvider);
    final vocabRepo = ref.read(vocabularyRepositoryProvider);
    final articleRepo = ref.read(articleRepositoryProvider);

    final session = await reviewRepo.getSessionById(widget.sessionId);
    final answers = await reviewRepo.getAnswersBySession(widget.sessionId);

    int totalSavedVocab = 0;
    int totalHighlights = 0;
    int totalNotes = 0;
    Article? article;

    if (session != null) {
      article = await articleRepo.getArticleById(session.documentId);
      final saved = await vocabRepo.getVocabularyByDocument(session.documentId);
      totalSavedVocab = saved.length;
      final hls = await articleRepo.getHighlightsForArticle(session.documentId);
      totalHighlights = hls.length;
      final nts = await articleRepo.getNotesForArticle(session.documentId);
      totalNotes = nts.length;
    }

    return {
      'session': session,
      'answers': answers,
      'totalSavedVocab': totalSavedVocab,
      'totalHighlights': totalHighlights,
      'totalNotes': totalNotes,
      'article': article,
    };
  }

  void _triggerShare({
    required Article article,
    required double overallScore,
    required double paragraphScore,
    required double conceptScore,
    required double logicScore,
    required double vocabularyScore,
    required int vocabCount,
    required int highlightsCount,
    required int notesCount,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: ColorTokens.getBackground(Theme.of(context).brightness == Brightness.dark),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(LucideIcons.maximize2),
              title: const Text('Share Standard Card (1080 x 1350)'),
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _isStoryRatio = false);
                ShareCardCapture.captureAndShare(
                  context: context,
                  article: article,
                  overallScore: overallScore,
                  paragraphScore: paragraphScore,
                  conceptScore: conceptScore,
                  logicScore: logicScore,
                  vocabularyScore: vocabularyScore,
                  durationSec: ref.read(settingsRepositoryProvider).totalReadingTime,
                  vocabCount: vocabCount,
                  highlightsCount: highlightsCount,
                  notesCount: notesCount,
                  isStoryRatio: false,
                );
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.smartphone),
              title: const Text('Share Story Card (1080 x 1920)'),
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _isStoryRatio = true);
                ShareCardCapture.captureAndShare(
                  context: context,
                  article: article,
                  overallScore: overallScore,
                  paragraphScore: paragraphScore,
                  conceptScore: conceptScore,
                  logicScore: logicScore,
                  vocabularyScore: vocabularyScore,
                  durationSec: ref.read(settingsRepositoryProvider).totalReadingTime,
                  vocabCount: vocabCount,
                  highlightsCount: highlightsCount,
                  notesCount: notesCount,
                  isStoryRatio: true,
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: ColorTokens.getBackground(isDark),
      appBar: AppBar(
        title: Text('Review Result', style: AppTypography.title2.copyWith(
          color: ColorTokens.getTextPrimary(isDark),
          fontWeight: FontWeight.bold,
        )),
        leading: IconButton(
          icon: const Icon(LucideIcons.x),
          onPressed: () => context.go('/'),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _loadData(),
        builder: (ctx, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());

          final data = snap.data!;
          final session = data['session'];
          final answers = data['answers'] as List<dynamic>? ?? [];
          final totalSavedVocab = data['totalSavedVocab'] as int? ?? 0;
          final totalHighlights = data['totalHighlights'] as int? ?? 0;
          final totalNotes = data['totalNotes'] as int? ?? 0;
          final Article? article = data['article'] as Article?;

          if (session == null || answers.isEmpty || article == null) {
            return Center(child: Text('No data found', style: AppTypography.bodySans));
          }

          final documentId = session.documentId;
          final overallScore = session.overallScore ?? 0.0;

          final correct = answers.where((a) => a.aiJudgment == 'correct').toList();
          final partial = answers.where((a) => a.aiJudgment == 'partial').toList();
          final wrong = answers.where((a) => a.aiJudgment == 'wrong').toList();

          List<String> suggestions = [];
          List<String> strengths = [];
          List<String> needReviewList = [];
          double paragraphScore = 0;
          double conceptScore = 0;
          double logicScore = 0;
          double vocabularyScore = 0;
          String calculationProcess = '';

          try {
            if (session.suggestions != null) {
              final parsed = jsonDecode(session.suggestions as String);
              if (parsed is Map) {
                if (parsed['suggestions'] is List) {
                  suggestions = (parsed['suggestions'] as List).map((e) => e.toString()).toList();
                }
                if (parsed['strengths'] is List) {
                  strengths = (parsed['strengths'] as List).map((e) => e.toString()).toList();
                }
                if (parsed['need_review'] is List) {
                  needReviewList = (parsed['need_review'] as List).map((e) => e.toString()).toList();
                }
                paragraphScore = (parsed['paragraph_score'] as num?)?.toDouble() ?? 0;
                conceptScore = (parsed['concept_score'] as num?)?.toDouble() ?? 0;
                logicScore = (parsed['logic_score'] as num?)?.toDouble() ?? 0;
                vocabularyScore = (parsed['vocabulary_score'] as num?)?.toDouble() ?? 0;
                calculationProcess = parsed['calculation_process']?.toString() ?? '';
              }
            }
          } catch (_) {}

          List<String> vocabImpact = [];
          try {
            if (session.vocabImpact != null) {
              final parsed = jsonDecode(session.vocabImpact as String);
              if (parsed is List) {
                vocabImpact = parsed.map((e) => e.toString()).toList();
              }
            }
          } catch (_) {}

          return Stack(
            children: [
              // Off-screen RepaintBoundary widget to render capture card
              Positioned(
                left: -2000,
                top: -2000,
                child: RepaintBoundary(
                  key: ShareCardCapture.boundaryKey,
                  child: ShareSummaryCardWidget(
                    article: article,
                    overallScore: overallScore,
                    paragraphScore: paragraphScore,
                    conceptScore: conceptScore,
                    logicScore: logicScore,
                    vocabularyScore: vocabularyScore,
                    durationSec: ref.read(settingsRepositoryProvider).totalReadingTime,
                    vocabCount: totalSavedVocab,
                    highlightsCount: totalHighlights,
                    notesCount: totalNotes,
                    isStoryRatio: _isStoryRatio,
                  ),
                ),
              ),
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ScoreCard(score: overallScore, isDark: isDark),
                    const SizedBox(height: 20),
                    Center(
                      child: OutlinedButton.icon(
                        icon: const Icon(LucideIcons.share2),
                        label: const Text('Share Reading Summary'),
                        onPressed: () => _triggerShare(
                          article: article,
                          overallScore: overallScore,
                          paragraphScore: paragraphScore,
                          conceptScore: conceptScore,
                          logicScore: logicScore,
                          vocabularyScore: vocabularyScore,
                          vocabCount: totalSavedVocab,
                          highlightsCount: totalHighlights,
                          notesCount: totalNotes,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (paragraphScore > 0 || conceptScore > 0 || logicScore > 0 || vocabularyScore > 0) ...[
                      SubScoresSection(
                        paragraph: paragraphScore,
                        concept: conceptScore,
                        logic: logicScore,
                        vocabulary: vocabularyScore,
                        calculation: calculationProcess,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 24),
                    ],
                    if (strengths.isNotEmpty) ...[
                      BulletSection(
                        title: 'Strengths',
                        items: strengths,
                        iconColor: ColorTokens.success,
                        icon: LucideIcons.checkCircle,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 24),
                    ],
                    if (needReviewList.isNotEmpty) ...[
                      BulletSection(
                        title: 'Focus Areas',
                        items: needReviewList,
                        iconColor: ColorTokens.warning,
                        icon: LucideIcons.zap,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 24),
                    ],
                    if (suggestions.isNotEmpty) ...[
                      SuggestionsSection(suggestions: suggestions, isDark: isDark),
                      const SizedBox(height: 24),
                    ],
                    VocabularyImpactSection(
                      totalSaved: totalSavedVocab,
                      impactedWords: vocabImpact,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 24),
                    if (correct.isNotEmpty) ...[
                      CategoryHeader(
                        icon: LucideIcons.checkCircle,
                        color: ColorTokens.success,
                        title: 'Understood Well',
                        count: correct.length,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),
                      ...correct.map((a) => CorrectAnswerTile(index: a.paragraphIdx, previewText: a.paragraphText, isDark: isDark)),
                      const SizedBox(height: 24),
                    ],
                    if (partial.isNotEmpty) ...[
                      CategoryHeader(
                        icon: LucideIcons.alertTriangle,
                        color: ColorTokens.warning,
                        title: 'Need Review',
                        count: partial.length,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),
                      ...partial.map((a) => DetailAnswerCard(
                            index: a.paragraphIdx,
                            score: a.aiScore ?? 0.0,
                            originalText: a.paragraphText,
                            userAnswer: a.userAnswer,
                            feedback: a.aiFeedback ?? '',
                            documentId: documentId,
                            color: ColorTokens.warning,
                            isDark: isDark,
                           )),
                      const SizedBox(height: 24),
                    ],
                    if (wrong.isNotEmpty) ...[
                      CategoryHeader(
                        icon: LucideIcons.xCircle,
                        color: ColorTokens.error,
                        title: 'Misunderstood Paragraphs',
                        count: wrong.length,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),
                      ...wrong.map((a) => DetailAnswerCard(
                            index: a.paragraphIdx,
                            score: a.aiScore ?? 0.0,
                            originalText: a.paragraphText,
                            userAnswer: a.userAnswer,
                            feedback: a.aiFeedback ?? '',
                            documentId: documentId,
                            color: ColorTokens.error,
                            isDark: isDark,
                          )),
                      const SizedBox(height: 24),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
