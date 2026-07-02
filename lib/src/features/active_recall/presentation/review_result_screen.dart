import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:paperflow/src/common/providers.dart';
import '../../../common/theme/colors.dart';
import '../../../common/theme/typography.dart';

class ReviewResultScreen extends ConsumerWidget {
  final int sessionId;
  const ReviewResultScreen({super.key, required this.sessionId});

  Future<Map<String, dynamic>> _loadData(WidgetRef ref) async {
    final dao = await ref.read(recallSessionDaoProvider.future);
    final session = await dao.getSessionById(sessionId);
    final answers = await dao.getAnswersBySession(sessionId);
    
    int totalSavedVocab = 0;
    if (session != null) {
      final docId = session['documentId'] as int;
      final vocabDao = await ref.read(vocabularyDaoProvider.future);
      final saved = await vocabDao.getVocabularyByDocument(docId);
      totalSavedVocab = saved.length;
    }

    return {
      'session': session,
      'answers': answers,
      'totalSavedVocab': totalSavedVocab,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: Text('Review Result', style: AppTypography.title2.copyWith(
          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
        )),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/'),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _loadData(ref),
        builder: (ctx, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          
          final data = snap.data!;
          final session = data['session'] as Map<String, dynamic>?;
          final answers = data['answers'] as List<Map<String, dynamic>>? ?? [];
          final totalSavedVocab = data['totalSavedVocab'] as int? ?? 0;

          if (session == null || answers.isEmpty) {
            return Center(child: Text('No data', style: AppTypography.bodySans));
          }

          final documentId = session['documentId'] as int;
          final overallScore = (session['overallScore'] as num?)?.toDouble() ?? 0.0;

          // Group by judgment
          final correct = answers.where((a) => a['aiJudgment'] == 'correct').toList();
          final partial = answers.where((a) => a['aiJudgment'] == 'partial').toList();
          final wrong = answers.where((a) => a['aiJudgment'] == 'wrong').toList();

          // Parse suggestions and sub-scores
          List<String> suggestions = [];
          List<String> strengths = [];
          List<String> needReviewList = [];
          double paragraphScore = 0;
          double conceptScore = 0;
          double logicScore = 0;
          double vocabularyScore = 0;
          String calculationProcess = '';

          try {
            if (session['suggestions'] != null) {
              final parsed = jsonDecode(session['suggestions'] as String);
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
              } else if (parsed is List) {
                // Backward compatibility
                suggestions = parsed.map((e) => e.toString()).toList();
              }
            }
          } catch (_) {}

          // Parse vocab impact
          List<String> vocabImpact = [];
          try {
            if (session['vocabImpact'] != null) {
              final parsed = jsonDecode(session['vocabImpact'] as String);
              if (parsed is List) {
                vocabImpact = parsed.map((e) => e.toString()).toList();
              }
            }
          } catch (_) {}

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Score card
                _ScoreCard(score: overallScore, isDark: isDark),
                const SizedBox(height: 24),

                // Sub-scores breakdown
                if (paragraphScore > 0 || conceptScore > 0 || logicScore > 0 || vocabularyScore > 0) ...[
                  _SubScoresSection(
                    paragraph: paragraphScore,
                    concept: conceptScore,
                    logic: logicScore,
                    vocabulary: vocabularyScore,
                    calculation: calculationProcess,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 24),
                ],

                // Strengths
                if (strengths.isNotEmpty) ...[
                  _BulletSection(
                    title: 'Strengths',
                    items: strengths,
                    iconColor: AppColors.success,
                    icon: Icons.check_circle_outline,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 24),
                ],

                // Need Review Bullet list
                if (needReviewList.isNotEmpty) ...[
                  _BulletSection(
                    title: 'Focus Areas',
                    items: needReviewList,
                    iconColor: AppColors.warning,
                    icon: Icons.offline_bolt_outlined,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 24),
                ],

                // Suggestions from AI Coach
                if (suggestions.isNotEmpty) ...[
                  _SuggestionsSection(suggestions: suggestions, isDark: isDark),
                  const SizedBox(height: 24),
                ],

                // Vocabulary Impact
                _VocabularyImpactSection(
                  totalSaved: totalSavedVocab,
                  impactedWords: vocabImpact,
                  isDark: isDark,
                ),
                const SizedBox(height: 24),

                // UNDERSTOOD WELL
                if (correct.isNotEmpty) ...[
                  _CategoryHeader(
                    icon: Icons.check_circle,
                    color: AppColors.success,
                    title: 'Understood Well',
                    count: correct.length,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  ...correct.map((a) => _CorrectAnswerTile(a: a, isDark: isDark)),
                  const SizedBox(height: 24),
                ],

                // NEED REVIEW
                if (partial.isNotEmpty) ...[
                  _CategoryHeader(
                    icon: Icons.warning_amber_rounded,
                    color: AppColors.warning,
                    title: 'Need Review',
                    count: partial.length,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  ...partial.map((a) => _DetailAnswerCard(
                        a: a,
                        documentId: documentId,
                        color: AppColors.warning,
                        isDark: isDark,
                      )),
                  const SizedBox(height: 24),
                ],

                // MISUNDERSTOOD
                if (wrong.isNotEmpty) ...[
                  _CategoryHeader(
                    icon: Icons.error_outline_rounded,
                    color: AppColors.error,
                    title: 'Misunderstood Paragraphs',
                    count: wrong.length,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  ...wrong.map((a) => _DetailAnswerCard(
                        a: a,
                        documentId: documentId,
                        color: AppColors.error,
                        isDark: isDark,
                      )),
                  const SizedBox(height: 24),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  final double score;
  final bool isDark;

  const _ScoreCard({required this.score, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final color = score >= 80 ? AppColors.success : score >= 60 ? AppColors.warning : AppColors.error;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text('Overall Understanding', style: AppTypography.subheadline.copyWith(
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          )),
          const SizedBox(height: 20),
          SizedBox(
            width: 130,
            height: 130,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 130,
                  height: 130,
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 10,
                    backgroundColor: isDark ? AppColors.darkDivider : AppColors.divider,
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${score.round()}%', style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: color,
                    )),
                    const SizedBox(height: 4),
                    Text(
                      score >= 80 ? 'Mastered' : score >= 60 ? 'Review Needed' : 'Low Recall',
                      style: AppTypography.caption1.copyWith(
                        color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final int count;
  final bool isDark;

  const _CategoryHeader({
    required this.icon,
    required this.color,
    required this.title,
    required this.count,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 8),
        Text(title, style: AppTypography.title3.copyWith(
          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          fontWeight: FontWeight.bold,
        )),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text('$count', style: AppTypography.caption1.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          )),
        ),
      ],
    );
  }
}

class _CorrectAnswerTile extends StatelessWidget {
  final Map<String, dynamic> a;
  final bool isDark;

  const _CorrectAnswerTile({required this.a, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final previewText = a['paragraphText'] as String? ?? '';
    final trimmedPreview = previewText.length > 80 
        ? '${previewText.substring(0, 80)}...' 
        : previewText;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('P ${(a['paragraphIdx'] as int) + 1}', style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.success,
            )),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              trimmedPreview,
              style: AppTypography.caption1.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailAnswerCard extends StatelessWidget {
  final Map<String, dynamic> a;
  final int documentId;
  final Color color;
  final bool isDark;

  const _DetailAnswerCard({
    required this.a,
    required this.documentId,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final idx = a['paragraphIdx'] as int;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Paragraph ${idx + 1}', style: AppTypography.headline.copyWith(
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              )),
              if (a['aiScore'] != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('${(a['aiScore'] as double).round()}%', style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  )),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Original Text:', style: AppTypography.caption1.copyWith(
            color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
            fontWeight: FontWeight.w600,
          )),
          const SizedBox(height: 4),
          Text(a['paragraphText'] as String? ?? '', style: AppTypography.caption1.copyWith(
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          )),
          const SizedBox(height: 12),
          Text('Your Recall:', style: AppTypography.caption1.copyWith(
            color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
            fontWeight: FontWeight.w600,
          )),
          const SizedBox(height: 4),
          Text(
            (a['userAnswer'] as String? ?? '').trim().isEmpty 
                ? '(No recall entered)' 
                : a['userAnswer'] as String, 
            style: AppTypography.caption1.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              fontStyle: (a['userAnswer'] as String? ?? '').trim().isEmpty ? FontStyle.italic : null,
            )
          ),
          if (a['aiFeedback'] != null && (a['aiFeedback'] as String).isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Coach Feedback:', style: AppTypography.caption2.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  )),
                  const SizedBox(height: 4),
                  Text(a['aiFeedback'] as String, style: AppTypography.subheadline.copyWith(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    fontSize: 14,
                  )),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => context.push('/reader/$documentId?paragraph=$idx'),
              icon: const Icon(Icons.arrow_forward_rounded, size: 16),
              label: const Text('Jump to Reader'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.accent,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: AppColors.accent.withOpacity(0.2)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionsSection extends StatelessWidget {
  final List<String> suggestions;
  final bool isDark;

  const _SuggestionsSection({required this.suggestions, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppColors.accent, size: 20),
              const SizedBox(width: 8),
              Text('Coach Suggestions', style: AppTypography.headline.copyWith(
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              )),
            ],
          ),
          const SizedBox(height: 14),
          ...suggestions.take(5).map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ', style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                    )),
                    Expanded(
                      child: Text(s, style: AppTypography.subheadline.copyWith(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        height: 1.4,
                      )),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _VocabularyImpactSection extends StatelessWidget {
  final int totalSaved;
  final List<String> impactedWords;
  final bool isDark;

  const _VocabularyImpactSection({
    required this.totalSaved,
    required this.impactedWords,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Vocabulary Impact', style: AppTypography.headline.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          )),
          const SizedBox(height: 12),
          Text(
            'Words saved: $totalSaved. ${impactedWords.isNotEmpty ? "${impactedWords.length} directly affected recall understanding." : "No saved words affected understanding."}',
            style: AppTypography.subheadline.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
          if (impactedWords.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: impactedWords.map((word) => Chip(
                    label: Text(word, style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    )),
                    backgroundColor: AppColors.error.withOpacity(0.08),
                    labelStyle: const TextStyle(color: AppColors.error),
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  )).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _SubScoresSection extends StatelessWidget {
  final double paragraph;
  final double concept;
  final double logic;
  final double vocabulary;
  final String calculation;
  final bool isDark;

  const _SubScoresSection({
    required this.paragraph,
    required this.concept,
    required this.logic,
    required this.vocabulary,
    required this.calculation,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Score Breakdown',
            style: AppTypography.headline.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildRow('Paragraph (40%)', paragraph, isDark),
          const SizedBox(height: 12),
          _buildRow('Concept (30%)', concept, isDark),
          const SizedBox(height: 12),
          _buildRow('Logic (20%)', logic, isDark),
          const SizedBox(height: 12),
          _buildRow('Vocabulary (10%)', vocabulary, isDark),
          if (calculation.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(),
            ),
            Text(
              'Calculation Process:',
              style: AppTypography.caption1.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              calculation,
              style: TextStyle(
                fontFamily: 'Courier',
                fontSize: 12,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRow(String label, double score, bool isDark) {
    final color = score >= 80 ? AppColors.success : score >= 60 ? AppColors.warning : AppColors.error;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.subheadline.copyWith(
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
        ),
        Row(
          children: [
            Container(
              width: 80,
              height: 6,
              decoration: BoxDecoration(
                color: (isDark ? AppColors.darkDivider : AppColors.divider).withOpacity(0.5),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Stack(
                children: [
                  Container(
                    width: 80 * (score / 100).clamp(0.0, 1.0),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${score.round()}',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BulletSection extends StatelessWidget {
  final String title;
  final List<String> items;
  final Color iconColor;
  final IconData icon;
  final bool isDark;

  const _BulletSection({
    required this.title,
    required this.items,
    required this.iconColor,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.headline.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: iconColor, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item,
                    style: AppTypography.subheadline.copyWith(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
