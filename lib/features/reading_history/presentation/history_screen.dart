import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/app/providers.dart';
import '../../../core/design_system/color_tokens.dart';
import '../../../core/design_system/typography.dart';
import '../../../models/reading_history/reading_history.dart';
import '../../library/presentation/library_screen.dart';

class ReadingHistoryScreen extends ConsumerStatefulWidget {
  const ReadingHistoryScreen({super.key});

  @override
  ConsumerState<ReadingHistoryScreen> createState() => _ReadingHistoryScreenState();
}

class _ReadingHistoryScreenState extends ConsumerState<ReadingHistoryScreen> {
  String _timeframe = 'Week';

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
    final statsAsync = ref.watch(statsProvider);

    return Scaffold(
      backgroundColor: ColorTokens.getBackground(isDark),
      body: SafeArea(
        child: FutureBuilder<List<ReadingHistory>>(
          future: ref.read(historyRepositoryProvider).getRecentHistory(_days),
          builder: (context, snapshot) {
            final hasData = snapshot.hasData && snapshot.data!.isNotEmpty;
            final data = snapshot.data ?? [];
            final groupedData = _groupData(data);

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Progress',
                          style: AppTypography.largeTitle.copyWith(
                            color: ColorTokens.getTextPrimary(isDark),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Track your comprehension fitness and retention trends.',
                          style: AppTypography.subheadline.copyWith(
                            color: ColorTokens.getTextSecondary(isDark),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: ColorTokens.getSurfaceSecondary(isDark),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: ColorTokens.getDivider(isDark), width: 0.5),
                              ),
                              child: Icon(
                                LucideIcons.trendingUp,
                                size: 32,
                                color: ColorTokens.getTextTertiary(isDark),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'No Data in this Period',
                              style: AppTypography.title2.copyWith(
                                color: ColorTokens.getTextPrimary(isDark),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Complete Active Recall sessions to build your history curve.',
                              textAlign: TextAlign.center,
                              style: AppTypography.subheadline.copyWith(
                                color: ColorTokens.getTextSecondary(isDark),
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                      child: _buildOverviewCard(groupedData, isDark),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      child: _buildChartCard(groupedData, isDark),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
                      child: Text(
                        'Metrics',
                        style: AppTypography.title2.copyWith(
                          color: ColorTokens.getTextPrimary(isDark),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverToBoxAdapter(
                      child: statsAsync.when(
                        data: (stats) => _buildOverviewGrid(context, stats, isDark),
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (_, __) => const SizedBox.shrink(),
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

  Widget _buildTimeframeSelector(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: ColorTokens.getSurfaceSecondary(isDark),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ColorTokens.getDivider(isDark), width: 0.5),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        children: ['Week', 'Month', 'Year'].map((time) {
          final isSelected = _timeframe == time;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _timeframe = time),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? ColorTokens.getBackground(isDark) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isSelected ? ColorTokens.getShadow(isDark) : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  time,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? ColorTokens.getTextPrimary(isDark) : ColorTokens.getTextSecondary(isDark),
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
    double sum = 0;
    double maxVal = 0;
    for (final p in points) {
      sum += p.score;
      if (p.score > maxVal) maxVal = p.score;
    }
    final avg = points.isNotEmpty ? sum / points.length : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ColorTokens.getBackground(isDark),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ColorTokens.getDivider(isDark), width: 1.0),
        boxShadow: ColorTokens.getShadow(isDark),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('COMPREHENSION', '${avg.round()}%', isDark),
          Container(width: 1, height: 40, color: ColorTokens.getDivider(isDark)),
          _buildSummaryItem('PEAK SCORE', '${maxVal.round()}%', isDark),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, bool isDark) {
    return Column(
      children: [
        Text(
          label,
          style: AppTypography.caption2.copyWith(
            color: ColorTokens.getTextTertiary(isDark),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: ColorTokens.getTextPrimary(isDark),
          ),
        ),
      ],
    );
  }

  Widget _buildChartCard(List<_ChartPoint> points, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ColorTokens.getBackground(isDark),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ColorTokens.getDivider(isDark), width: 1.0),
        boxShadow: ColorTokens.getShadow(isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Comprehension Trend',
            style: AppTypography.headline.copyWith(
              color: ColorTokens.getTextPrimary(isDark),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            width: double.infinity,
            child: CustomPaint(
              painter: _HistoryCurvePainter(
                points: points,
                lineColor: ColorTokens.accent,
                gridColor: ColorTokens.getDivider(isDark),
                isDark: isDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewGrid(BuildContext context, Map<String, int> stats, bool isDark) {
    final settings = ref.read(settingsRepositoryProvider);
    final hours = (settings.totalReadingTime / 3600).toStringAsFixed(1);
    
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.35,
      children: [
        _buildAppleHealthCard('Papers Read', '${stats['papers'] ?? 0}', LucideIcons.bookOpen, isDark),
        _buildAppleHealthCard('Focus Duration', '${hours}h', LucideIcons.clock, isDark),
        _buildAppleHealthCard('Words Processed', _formatWords(stats['words'] ?? 0), LucideIcons.type, isDark),
        _buildAppleHealthCard('Vocabulary Saved', '${stats['vocab'] ?? 0}', LucideIcons.bookmark, isDark),
        _buildAppleHealthCard('Highlights Made', '${stats['highlights'] ?? 0}', LucideIcons.edit3, isDark),
        _buildAppleHealthCard('Notes Written', '${stats['notes'] ?? 0}', LucideIcons.fileText, isDark),
      ],
    );
  }

  Widget _buildAppleHealthCard(String label, String value, IconData icon, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: ColorTokens.getBackground(isDark),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ColorTokens.getDivider(isDark), width: 1.0),
        boxShadow: ColorTokens.getShadow(isDark),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: AppTypography.caption1.copyWith(
                  color: ColorTokens.getTextSecondary(isDark),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(icon, size: 16, color: ColorTokens.accent),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: ColorTokens.getTextPrimary(isDark),
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  String _formatWords(int count) {
    if (count < 1000) return '$count';
    if (count < 1000000) return '${(count / 1000).toStringAsFixed(1)}k';
    return '${(count / 1000000).toStringAsFixed(1)}m';
  }

  List<_ChartPoint> _groupData(List<ReadingHistory> data) {
    if (data.isEmpty) return [];

    final Map<String, List<double>> dateGroups = {};
    final List<String> dateKeysInOrder = [];

    for (final item in data) {
      final dt = DateTime.fromMillisecondsSinceEpoch(item.createdAt);
      String key;
      if (_timeframe == 'Week') {
        key = DateFormat('E').format(dt);
      } else if (_timeframe == 'Month') {
        key = '${dt.month}/${dt.day}';
      } else {
        key = DateFormat('MMM').format(dt);
      }

      if (!dateGroups.containsKey(key)) {
        dateGroups[key] = [];
        dateKeysInOrder.add(key);
      }
      dateGroups[key]!.add(item.score);
    }

    final List<_ChartPoint> points = [];
    for (final key in dateKeysInOrder) {
      final scores = dateGroups[key]!;
      final avg = scores.reduce((a, b) => a + b) / scores.length;
      points.add(_ChartPoint(label: key, score: avg));
    }

    if (points.length > 8) {
      final int skip = (points.length / 8).ceil();
      final List<_ChartPoint> thinned = [];
      for (int i = 0; i < points.length; i += skip) {
        thinned.add(points[i]);
      }
      if (thinned.last != points.last) {
        thinned.add(points.last);
      }
      return thinned;
    }

    return points;
  }
}

class _ChartPoint {
  final String label;
  final double score;

  _ChartPoint({required this.label, required this.score});
}

class _HistoryCurvePainter extends CustomPainter {
  final List<_ChartPoint> points;
  final Color lineColor;
  final Color gridColor;
  final bool isDark;

  _HistoryCurvePainter({
    required this.points,
    required this.lineColor,
    required this.gridColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;
    
    for (int i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
      
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${100 - i * 25}',
          style: TextStyle(
            color: ColorTokens.getTextTertiary(isDark),
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

      final fillPaint = Paint()
        ..color = lineColor.withOpacity(0.04)
        ..style = PaintingStyle.fill;
      canvas.drawPath(fillPath, fillPaint);
    }

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);

    final dotPaint = Paint()..color = lineColor;
    final dotOuterPaint = Paint()..color = ColorTokens.getBackground(isDark);

    for (int i = 0; i < count; i++) {
      final x = i * stepX;
      final y = size.height - (points[i].score / 100 * size.height);
      
      canvas.drawCircle(Offset(x, y), 4, dotPaint);
      canvas.drawCircle(Offset(x, y), 2, dotOuterPaint);

      final labelInterval = (count / 5).ceil();
      if (i % labelInterval == 0 || i == count - 1) {
        final labelPainter = TextPainter(
          text: TextSpan(
            text: points[i].label,
            style: TextStyle(
              color: ColorTokens.getTextTertiary(isDark),
              fontSize: 9,
              fontFamily: 'Inter',
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        
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
