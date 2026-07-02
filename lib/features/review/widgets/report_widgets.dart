import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design_system/color_tokens.dart';
import '../../../core/design_system/typography.dart';

class ScoreCard extends StatelessWidget {
  final double score;
  final bool isDark;

  const ScoreCard({super.key, required this.score, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final color = score >= 80 ? ColorTokens.success : score >= 60 ? ColorTokens.warning : ColorTokens.error;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: ColorTokens.getSurface(isDark),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Text('Overall Understanding', style: AppTypography.subheadline.copyWith(
            color: ColorTokens.getTextSecondary(isDark),
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
                    backgroundColor: ColorTokens.getDivider(isDark),
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
                        color: ColorTokens.getTextTertiary(isDark),
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

class CategoryHeader extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final int count;
  final bool isDark;

  const CategoryHeader({
    super.key,
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
          color: ColorTokens.getTextPrimary(isDark),
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

class CorrectAnswerTile extends StatelessWidget {
  final int index;
  final String previewText;
  final bool isDark;

  const CorrectAnswerTile({
    super.key,
    required this.index,
    required this.previewText,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final trimmedPreview = previewText.length > 80 
        ? '${previewText.substring(0, 80)}...' 
        : previewText;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: ColorTokens.getSurface(isDark),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: ColorTokens.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('P ${index + 1}', style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: ColorTokens.success,
            )),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              trimmedPreview,
              style: AppTypography.caption1.copyWith(
                color: ColorTokens.getTextSecondary(isDark),
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

class DetailAnswerCard extends StatelessWidget {
  final int index;
  final double score;
  final String originalText;
  final String userAnswer;
  final String feedback;
  final int documentId;
  final Color color;
  final bool isDark;

  const DetailAnswerCard({
    super.key,
    required this.index,
    required this.score,
    required this.originalText,
    required this.userAnswer,
    required this.feedback,
    required this.documentId,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ColorTokens.getSurface(isDark),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Paragraph ${index + 1}', style: AppTypography.headline.copyWith(
                color: ColorTokens.getTextPrimary(isDark),
                fontWeight: FontWeight.bold,
              )),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('${score.round()}%', style: TextStyle(
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
            color: ColorTokens.getTextTertiary(isDark),
            fontWeight: FontWeight.w600,
          )),
          const SizedBox(height: 4),
          Text(originalText, style: AppTypography.caption1.copyWith(
            color: ColorTokens.getTextSecondary(isDark),
          )),
          const SizedBox(height: 12),
          Text('Your Recall:', style: AppTypography.caption1.copyWith(
            color: ColorTokens.getTextTertiary(isDark),
            fontWeight: FontWeight.w600,
          )),
          const SizedBox(height: 4),
          Text(
            userAnswer.trim().isEmpty ? '(No recall entered)' : userAnswer, 
            style: AppTypography.caption1.copyWith(
              color: ColorTokens.getTextSecondary(isDark),
              fontStyle: userAnswer.trim().isEmpty ? FontStyle.italic : null,
            )
          ),
          if (feedback.isNotEmpty) ...[
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
                  Text(feedback, style: AppTypography.subheadline.copyWith(
                    color: ColorTokens.getTextPrimary(isDark),
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
              onPressed: () => context.push('/reader/$documentId?paragraph=$index'),
              icon: const Icon(Icons.arrow_forward_rounded, size: 16),
              label: const Text('Jump to Reader'),
              style: TextButton.styleFrom(
                foregroundColor: ColorTokens.accent,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: ColorTokens.accent.withOpacity(0.2)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SuggestionsSection extends StatelessWidget {
  final List<String> suggestions;
  final bool isDark;

  const SuggestionsSection({super.key, required this.suggestions, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ColorTokens.getSurface(isDark),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: ColorTokens.accent, size: 20),
              const SizedBox(width: 8),
              Text('Coach Suggestions', style: AppTypography.headline.copyWith(
                color: ColorTokens.getTextPrimary(isDark),
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
                      color: ColorTokens.getTextTertiary(isDark),
                    )),
                    Expanded(
                      child: Text(s, style: AppTypography.subheadline.copyWith(
                        color: ColorTokens.getTextSecondary(isDark),
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

class VocabularyImpactSection extends StatelessWidget {
  final int totalSaved;
  final List<String> impactedWords;
  final bool isDark;

  const VocabularyImpactSection({
    super.key,
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
        color: ColorTokens.getSurface(isDark),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Vocabulary Impact', style: AppTypography.headline.copyWith(
            color: ColorTokens.getTextPrimary(isDark),
            fontWeight: FontWeight.bold,
          )),
          const SizedBox(height: 12),
          Text(
            'Words saved: $totalSaved. ${impactedWords.isNotEmpty ? "${impactedWords.length} directly affected recall understanding." : "No saved words affected understanding."}',
            style: AppTypography.subheadline.copyWith(
              color: ColorTokens.getTextSecondary(isDark),
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
                    backgroundColor: ColorTokens.error.withOpacity(0.08),
                    labelStyle: const TextStyle(color: ColorTokens.error),
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

class SubScoresSection extends StatelessWidget {
  final double paragraph;
  final double concept;
  final double logic;
  final double vocabulary;
  final String calculation;
  final bool isDark;

  const SubScoresSection({
    super.key,
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
        color: ColorTokens.getSurface(isDark),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Score Breakdown',
            style: AppTypography.headline.copyWith(
              color: ColorTokens.getTextPrimary(isDark),
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
                color: ColorTokens.getTextSecondary(isDark),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              calculation,
              style: TextStyle(
                fontFamily: 'Courier',
                fontSize: 12,
                color: ColorTokens.getTextSecondary(isDark),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRow(String label, double score, bool isDark) {
    final color = score >= 80 ? ColorTokens.success : score >= 60 ? ColorTokens.warning : ColorTokens.error;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.subheadline.copyWith(
            color: ColorTokens.getTextSecondary(isDark),
          ),
        ),
        Row(
          children: [
            Container(
              width: 80,
              height: 6,
              decoration: BoxDecoration(
                color: ColorTokens.getDivider(isDark).withOpacity(0.5),
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
                color: ColorTokens.getTextPrimary(isDark),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class BulletSection extends StatelessWidget {
  final String title;
  final List<String> items;
  final Color iconColor;
  final IconData icon;
  final bool isDark;

  const BulletSection({
    super.key,
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
        color: ColorTokens.getSurface(isDark),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.headline.copyWith(
              color: ColorTokens.getTextPrimary(isDark),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 16, color: iconColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item,
                    style: AppTypography.subheadline.copyWith(
                      color: ColorTokens.getTextSecondary(isDark),
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
