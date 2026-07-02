import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperflow/src/common/providers.dart';
import '../../../common/theme/colors.dart';
import '../../../common/theme/typography.dart';

class MasteryScreen extends ConsumerStatefulWidget {
  const MasteryScreen({super.key});

  @override
  ConsumerState<MasteryScreen> createState() => _MasteryScreenState();
}

class _MasteryScreenState extends ConsumerState<MasteryScreen> {
  String _timeframe = 'Week'; // 'Week', 'Month', 'Year'

  int get _days {
    switch (_timeframe) {
      case 'Month':
        return 30;
      case 'Year':
        return 365;
      case 'Week':
      default:
        return 7;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _loadMasteryData(),
          builder: (context, snapshot) {
            final hasData = snapshot.hasData && snapshot.data!.isNotEmpty;
            final data = snapshot.data ?? [];

            // Group by date to get a clean timeline
            final groupedData = _groupData(data);

            return CustomScrollView(
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reading Mastery',
                          style: AppTypography.largeTitle.copyWith(
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Track your comprehension fitness and retention trends.',
                          style: AppTypography.caption1.copyWith(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Timeframe Selector
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: _buildTimeframeSelector(isDark),
                  ),
                ),

                if (!hasData)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(48),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.trending_up_rounded,
                              size: 64,
                              color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No Data in this Period',
                              style: AppTypography.title2.copyWith(
                                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Complete Active Recall sessions to build your mastery curve.',
                              textAlign: TextAlign.center,
                              style: AppTypography.subheadline.copyWith(
                                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else ...[
                  // Overview Score Card
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                      child: _buildOverviewCard(groupedData, isDark),
                    ),
                  ),

                  // Mastery Curve Card
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      child: _buildChartCard(groupedData, isDark),
                    ),
                  ),

                  // Detail List Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                      child: Text(
                        'Recent Scores',
                        style: AppTypography.title2.copyWith(
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),

                  // Score history list
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          // Show list in reverse chronological order
                          final item = data[data.length - 1 - index];
                          final score = (item['score'] as num).toDouble();
                          final dt = DateTime.fromMillisecondsSinceEpoch(item['createdAt'] as int);
                          final dateStr = '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkSurface : AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: (score >= 80 ? AppColors.success : score >= 60 ? AppColors.warning : AppColors.error).withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    score >= 80 ? Icons.check_circle_outline : score >= 60 ? Icons.offline_bolt_outlined : Icons.help_outline,
                                    color: score >= 80 ? AppColors.success : score >= 60 ? AppColors.warning : AppColors.error,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Recall Attempt',
                                        style: AppTypography.headline.copyWith(
                                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        dateStr,
                                        style: AppTypography.caption1.copyWith(
                                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${score.round()}',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: score >= 80 ? AppColors.success : score >= 60 ? AppColors.warning : AppColors.error,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        childCount: data.length,
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _loadMasteryData() async {
    final dao = await ref.read(masteryDaoProvider.future);
    return dao.getAllRecentScores(_days);
  }

  // Groups and averages scores by date
  List<_ChartPoint> _groupData(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return [];

    final Map<String, List<double>> dateGroups = {};
    final List<String> dateKeysInOrder = [];

    for (final item in data) {
      final timestamp = item['createdAt'] as int;
      final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
      
      String key;
      if (_timeframe == 'Year') {
        key = '${dt.year}/${dt.month.toString().padLeft(2, '0')}';
      } else {
        key = '${dt.month}/${dt.day}';
      }

      if (!dateGroups.containsKey(key)) {
        dateGroups[key] = [];
        dateKeysInOrder.add(key);
      }
      dateGroups[key]!.add((item['score'] as num).toDouble());
    }

    return dateKeysInOrder.map((key) {
      final scores = dateGroups[key]!;
      final avgScore = scores.reduce((a, b) => a + b) / scores.length;
      return _ChartPoint(label: key, score: avgScore);
    }).toList();
  }

  Widget _buildTimeframeSelector(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceSecondary : AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: ['Week', 'Month', 'Year'].map((time) {
          final isSelected = _timeframe == time;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _timeframe = time),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? AppColors.darkSurface : AppColors.surface)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: Text(
                  time,
                  textAlign: TextAlign.center,
                  style: AppTypography.headline.copyWith(
                    color: isSelected
                        ? (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary)
                        : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOverviewCard(List<_ChartPoint> points, bool isDark) {
    if (points.isEmpty) return const SizedBox.shrink();
    
    final average = points.map((p) => p.score).reduce((a, b) => a + b) / points.length;
    final color = average >= 80 ? AppColors.success : average >= 60 ? AppColors.warning : AppColors.error;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Text(
            'Average Mastery',
            style: AppTypography.subheadline.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${average.round()}%',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            average >= 80
                ? 'Strong understanding across papers'
                : average >= 60
                    ? 'Reasonable retention, keep reviewing'
                    : 'Focus on reviewing key misunderstood parts',
            textAlign: TextAlign.center,
            style: AppTypography.caption1.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard(List<_ChartPoint> points, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Comprehension Trend',
            style: AppTypography.headline.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            width: double.infinity,
            child: CustomPaint(
              painter: _MasteryCurvePainter(
                points: points,
                lineColor: AppColors.accent,
                gridColor: isDark ? AppColors.darkDivider : AppColors.divider,
                isDark: isDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartPoint {
  final String label;
  final double score;

  _ChartPoint({required this.label, required this.score});
}

class _MasteryCurvePainter extends CustomPainter {
  final List<_ChartPoint> points;
  final Color lineColor;
  final Color gridColor;
  final bool isDark;

  _MasteryCurvePainter({
    required this.points,
    required this.lineColor,
    required this.gridColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    // Draw horizontal grid lines
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;
    
    for (int i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
      
      // Draw grid score labels (100, 75, 50, 25, 0)
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${100 - i * 25}',
          style: TextStyle(
            color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
            fontSize: 9,
            fontFamily: 'Inter',
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(4, y - textPainter.height - 2));
    }

    final int count = points.length;
    final double stepX = count > 1 ? size.width / (count - 1) : size.width;
    
    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < count; i++) {
      final x = i * stepX;
      final y = size.height - (points[i].score / 100 * size.height);
      
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    if (count > 1) {
      fillPath.lineTo(size.width, size.height);
      fillPath.close();

      // Draw gradient fill
      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            lineColor.withOpacity(0.12),
            lineColor.withOpacity(0.00),
          ],
        ).createShader(Rect.fromLTRB(0, 0, size.width, size.height))
        ..style = PaintingStyle.fill;
      canvas.drawPath(fillPath, fillPaint);
    }

    // Draw line
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);

    // Draw point dots and text labels
    final dotPaint = Paint()..color = lineColor;
    final dotOuterPaint = Paint()..color = isDark ? AppColors.darkBackground : AppColors.background;

    for (int i = 0; i < count; i++) {
      final x = i * stepX;
      final y = size.height - (points[i].score / 100 * size.height);
      
      canvas.drawCircle(Offset(x, y), 5, dotPaint);
      canvas.drawCircle(Offset(x, y), 2.5, dotOuterPaint);

      // Label at bottom
      // Avoid label crowding (show max 5 labels)
      final labelInterval = (count / 5).ceil();
      if (i % labelInterval == 0 || i == count - 1) {
        final labelPainter = TextPainter(
          text: TextSpan(
            text: points[i].label,
            style: TextStyle(
              color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
              fontSize: 9,
              fontFamily: 'Inter',
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        
        // Position at bottom centered under the dot
        labelPainter.paint(
          canvas,
          Offset(x - labelPainter.width / 2, size.height + 4),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}
