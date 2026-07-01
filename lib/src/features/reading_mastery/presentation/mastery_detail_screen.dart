import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../common/database/app_database.dart';
import '../data/mastery_dao.dart';
import '../../library/presentation/library_screen.dart';

final masteryDaoProvider = Provider<MasteryDao>((ref) {
  return MasteryDao(ref.watch(databaseProvider));
});

final documentMasteryProvider =
    FutureProvider.family<List<MasteryScore>, int>((ref, documentId) async {
  final dao = ref.watch(masteryDaoProvider);
  return dao.getScoresByDocument(documentId);
});

final latestMasteryProvider =
    FutureProvider.family<MasteryScore?, int>((ref, documentId) async {
  final dao = ref.watch(masteryDaoProvider);
  return dao.getLatestScore(documentId);
});

class MasteryDetailScreen extends ConsumerWidget {
  final int documentId;

  const MasteryDetailScreen({super.key, required this.documentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scoresAsync = ref.watch(documentMasteryProvider(documentId));
    final latestAsync = ref.watch(latestMasteryProvider(documentId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reading Mastery'),
      ),
      body: latestAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (latest) {
          if (latest == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.trending_up,
                      size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No mastery data yet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Complete a recall session to see your scores',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade500,
                        ),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMasteryCard(context, latest),
                const SizedBox(height: 32),
                _buildTrendChart(context, scoresAsync),
                const SizedBox(height: 32),
                _buildHistory(context, scoresAsync),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMasteryCard(BuildContext context, MasteryScore latest) {
    final score = latest.score;
    final color = score >= 80
        ? Colors.green
        : score >= 60
            ? Colors.orange
            : Colors.red;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Text(
              'Reading Mastery',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
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
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${score.round()}%',
                        style: Theme.of(context)
                            .textTheme
                            .displayMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                      ),
                      Text(
                        score >= 80 ? 'Excellent' : 'Keep Going',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendChart(
      BuildContext context, AsyncValue<List<MasteryScore>> scoresAsync) {
    return scoresAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (scores) {
        if (scores.length < 2) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    'Mastery Trend',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Complete more recall sessions to see your trend',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
                ],
              ),
            ),
          );
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mastery Trend',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 200,
                  child: CustomPaint(
                    size: const Size(double.infinity, 200),
                    painter: _TrendChartPainter(
                      scores: scores.map((s) => s.score).toList(),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHistory(
      BuildContext context, AsyncValue<List<MasteryScore>> scoresAsync) {
    return scoresAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (scores) {
        if (scores.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mastery History',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            ...scores.reversed.take(10).map((score) {
              final date = DateTime.fromMillisecondsSinceEpoch(score.createdAt);
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: score.score >= 80
                      ? Colors.green.shade100
                      : score.score >= 60
                          ? Colors.orange.shade100
                          : Colors.red.shade100,
                  child: Text(
                    '${score.score.round()}',
                    style: TextStyle(
                      color: score.score >= 80
                          ? Colors.green
                          : score.score >= 60
                              ? Colors.orange
                              : Colors.red,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                title: Text('${score.score.round()}%'),
                subtitle: Text(
                  '${date.month}/${date.day} ${date.hour}:${date.minute.toString().padLeft(2, '0')}',
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

class _TrendChartPainter extends CustomPainter {
  final List<double> scores;
  final Color color;

  _TrendChartPainter({required this.scores, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (scores.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = color.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();
    final stepX = size.width / (scores.length - 1).clamp(1, double.infinity);

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

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    // Draw dots
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (int i = 0; i < scores.length; i++) {
      final x = i * stepX;
      final y = size.height - (scores[i] / 100 * size.height);
      canvas.drawCircle(Offset(x, y), 4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
