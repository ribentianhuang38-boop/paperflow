import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:paperflow/src/common/providers.dart';
import '../../../common/theme/colors.dart';
import '../../../common/theme/typography.dart';

class MasteryDetailScreen extends ConsumerWidget {
  final int documentId;
  const MasteryDetailScreen({super.key, required this.documentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: Text('Mastery', style: AppTypography.title2.copyWith(
          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
        )),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _loadLatest(ref),
        builder: (ctx, snap) {
          if (!snap.hasData) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.trending_up, size: 64,
                        color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary),
                    const SizedBox(height: 20),
                    Text('No data yet', style: AppTypography.title2.copyWith(
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    )),
                    const SizedBox(height: 8),
                    Text('Complete a recall session to see your mastery.',
                      textAlign: TextAlign.center,
                      style: AppTypography.subheadline.copyWith(
                        color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final latest = snap.data!;
          final score = (latest['score'] as num).toDouble();
          final color = score >= 80 ? AppColors.success : score >= 60 ? AppColors.warning : AppColors.error;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Mastery card - Apple Fitness style
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 32),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.surface,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    children: [
                      Text('Reading Mastery', style: AppTypography.subheadline.copyWith(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      )),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: 160,
                        height: 160,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 160,
                              height: 160,
                              child: CircularProgressIndicator(
                                value: score / 100,
                                strokeWidth: 12,
                                backgroundColor: isDark ? AppColors.darkDivider : AppColors.divider,
                                valueColor: AlwaysStoppedAnimation(color),
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('${score.round()}%',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 42,
                                      fontWeight: FontWeight.w700,
                                      color: color,
                                      letterSpacing: -1,
                                    )),
                                Text(score >= 80 ? 'Excellent' : 'Keep Going',
                                    style: AppTypography.subheadline.copyWith(
                                      color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                                    )),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Trend chart
                _TrendSection(documentId: documentId, isDark: isDark),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<Map<String, dynamic>?> _loadLatest(WidgetRef ref) async {
    final dao = await ref.read(masteryDaoProvider.future);
    return dao.getLatestScore(documentId);
  }
}

class _TrendSection extends StatelessWidget {
  final int documentId;
  final bool isDark;

  const _TrendSection({required this.documentId, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (ctx, ref, _) => FutureBuilder<List<Map<String, dynamic>>>(
        future: _load(ref),
        builder: (ctx, snap) {
          if (!snap.hasData || snap.data!.length < 2) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.surface,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  Text('Trend', style: AppTypography.headline.copyWith(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  )),
                  const SizedBox(height: 12),
                  Text('Complete more sessions to see your trend.',
                    style: AppTypography.subheadline.copyWith(
                      color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            );
          }

          final scores = snap.data!.map((s) => (s['score'] as num).toDouble()).toList();
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.surface,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Trend', style: AppTypography.headline.copyWith(
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                )),
                const SizedBox(height: 20),
                SizedBox(
                  height: 160,
                  child: CustomPaint(
                    size: const Size(double.infinity, 160),
                    painter: _TrendPainter(
                      scores: scores,
                      color: AppColors.accent,
                      lineColor: isDark ? AppColors.darkDivider : AppColors.divider,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _load(WidgetRef ref) async {
    final dao = await ref.read(masteryDaoProvider.future);
    return dao.getScoresByDocument(documentId);
  }
}

class _TrendPainter extends CustomPainter {
  final List<double> scores;
  final Color color;
  final Color lineColor;

  _TrendPainter({required this.scores, required this.color, required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (scores.isEmpty) return;

    // Grid lines
    final gridPaint = Paint()
      ..color = lineColor
      ..strokeWidth = 0.5;
    for (int i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final stepX = size.width / (scores.length - 1).clamp(1, double.infinity);
    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < scores.length; i++) {
      final x = i * stepX;
      final y = size.height - (scores[i] / 100 * size.height);
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo((scores.length - 1) * stepX, size.height);
    fillPath.close();

    // Fill
    final fillPaint = Paint()
      ..color = color.withOpacity(0.08)
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    // Line
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);

    // Dots
    final dotPaint = Paint()..color = color;
    for (int i = 0; i < scores.length; i++) {
      canvas.drawCircle(Offset(i * stepX, size.height - (scores[i] / 100 * size.height)), 4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}
