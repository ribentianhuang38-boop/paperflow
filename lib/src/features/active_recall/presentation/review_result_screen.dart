import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:paperflow/src/common/providers.dart';
import '../../../common/theme/colors.dart';
import '../../../common/theme/typography.dart';

class ReviewResultScreen extends ConsumerWidget {
  final int sessionId;
  const ReviewResultScreen({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: Text('Review', style: AppTypography.title2.copyWith(
          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
        )),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _load(ref),
        builder: (ctx, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final answers = snap.data!;
          if (answers.isEmpty) return Center(child: Text('No data', style: AppTypography.bodySans));

          final scored = answers.where((a) => a['aiScore'] != null).toList();
          final avg = scored.isEmpty ? 0.0
              : scored.map((a) => a['aiScore'] as double).reduce((a, b) => a + b) / scored.length;
          final wrong = answers.where((a) => a['aiJudgment'] == 'wrong').toList();
          final partial = answers.where((a) => a['aiJudgment'] == 'partial').toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Overall score card
                _ScoreCard(score: avg, isDark: isDark),
                const SizedBox(height: 24),

                // Section scores
                if (wrong.isNotEmpty) ...[
                  _StatusCard(
                    icon: Icons.close,
                    color: AppColors.error,
                    label: 'Misunderstood',
                    count: wrong.length,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 8),
                ],
                if (partial.isNotEmpty) ...[
                  _StatusCard(
                    icon: Icons.warning_amber,
                    color: AppColors.warning,
                    label: 'Need Review',
                    count: partial.length,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 8),
                ],
                if (wrong.isEmpty && partial.isEmpty)
                  _StatusCard(
                    icon: Icons.check_circle,
                    color: AppColors.success,
                    label: 'You understood well',
                    count: 0,
                    isDark: isDark,
                  ),
                const SizedBox(height: 24),

                // Paragraph details
                ...answers.map((a) => _AnswerCard(data: a, isDark: isDark)),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _load(WidgetRef ref) async {
    final dao = await ref.read(recallSessionDaoProvider.future);
    return dao.getAnswersBySession(sessionId);
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
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Text('Overall Understanding', style: AppTypography.subheadline.copyWith(
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          )),
          const SizedBox(height: 20),
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 8,
                    backgroundColor: isDark ? AppColors.darkDivider : AppColors.divider,
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${score.round()}%', style: AppTypography.title1.copyWith(color: color)),
                    Text(score >= 80 ? 'Well done' : 'Keep going', style: AppTypography.caption1.copyWith(
                      color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                    )),
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

class _StatusCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final int count;
  final bool isDark;

  const _StatusCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.count,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Text(label, style: AppTypography.headline.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          )),
          if (count > 0) ...[
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('$count', style: AppTypography.caption1.copyWith(color: color, fontWeight: FontWeight.w600)),
            ),
          ],
        ],
      ),
    );
  }
}

class _AnswerCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isDark;

  const _AnswerCard({required this.data, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final judgment = data['aiJudgment'] as String?;
    final color = judgment == 'correct' ? AppColors.success
        : judgment == 'partial' ? AppColors.warning : AppColors.error;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Paragraph ${(data['paragraphIdx'] as int) + 1}',
                  style: AppTypography.headline.copyWith(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  )),
              const Spacer(),
              if (data['aiScore'] != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('${(data['aiScore'] as double).round()}%',
                      style: AppTypography.caption1.copyWith(color: color, fontWeight: FontWeight.w600)),
                ),
            ],
          ),
          if (judgment != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(judgment.toUpperCase(),
                  style: AppTypography.caption2.copyWith(color: color)),
            ),
          ],
          if (data['aiFeedback'] != null && (data['aiFeedback'] as String).isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(data['aiFeedback'] as String, style: AppTypography.subheadline.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            )),
          ],
        ],
      ),
    );
  }
}
