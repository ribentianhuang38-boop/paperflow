import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:paperflow/src/common/providers.dart';

class MasteryDetailScreen extends ConsumerWidget {
  final int documentId;
  const MasteryDetailScreen({super.key, required this.documentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reading Mastery')),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _loadLatest(ref),
        builder: (ctx, snap) {
          if (!snap.hasData) {
            return Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.trending_up, size: 80, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text('No mastery data yet', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey.shade600)),
                const SizedBox(height: 8),
                Text('Complete a recall session to see your scores',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade500)),
              ]),
            );
          }
          final latest = snap.data!;
          final score = (latest['score'] as num).toDouble();
          final color = score >= 80 ? Colors.green : score >= 60 ? Colors.orange : Colors.red;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(children: [
                    Text('Reading Mastery', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey.shade600)),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: 160, height: 160,
                      child: Stack(alignment: Alignment.center, children: [
                        SizedBox(
                          width: 160, height: 160,
                          child: CircularProgressIndicator(value: score / 100, strokeWidth: 12,
                              backgroundColor: Colors.grey.shade200, valueColor: AlwaysStoppedAnimation(color)),
                        ),
                        Column(mainAxisSize: MainAxisSize.min, children: [
                          Text('${score.round()}%',
                              style: Theme.of(context).textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w700, color: color)),
                          Text(score >= 80 ? 'Excellent' : 'Keep Going',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600)),
                        ]),
                      ]),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 32),
              _buildTrend(context, ref),
            ]),
          );
        },
      ),
    );
  }

  Future<Map<String, dynamic>?> _loadLatest(WidgetRef ref) async {
    final dao = await ref.read(masteryDaoProvider.future);
    return dao.getLatestScore(documentId);
  }

  Widget _buildTrend(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _loadScores(ref),
      builder: (ctx, snap) {
        if (!snap.hasData || snap.data!.length < 2) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(children: [
                Text('Mastery Trend', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),
                Text('Complete more recall sessions to see your trend',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600)),
              ]),
            ),
          );
        }
        final scores = snap.data!.map((s) => (s['score'] as num).toDouble()).toList();
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Mastery Trend', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 24),
              SizedBox(
                height: 200,
                child: CustomPaint(
                  size: const Size(double.infinity, 200),
                  painter: _TrendChartPainter(scores: scores, color: Theme.of(context).colorScheme.primary),
                ),
              ),
            ]),
          ),
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _loadScores(WidgetRef ref) async {
    final dao = await ref.read(masteryDaoProvider.future);
    return dao.getScoresByDocument(documentId);
  }
}

class _TrendChartPainter extends CustomPainter {
  final List<double> scores;
  final Color color;
  _TrendChartPainter({required this.scores, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (scores.isEmpty) return;
    final paint = Paint()..color = color..strokeWidth = 2..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final fillPaint = Paint()..color = color.withOpacity(0.1)..style = PaintingStyle.fill;
    final path = Path();
    final fillPath = Path();
    final stepX = size.width / (scores.length - 1).clamp(1, double.infinity);

    for (int i = 0; i < scores.length; i++) {
      final x = i * stepX;
      final y = size.height - (scores[i] / 100 * size.height);
      if (i == 0) { path.moveTo(x, y); fillPath.moveTo(x, size.height); fillPath.lineTo(x, y); }
      else { path.lineTo(x, y); fillPath.lineTo(x, y); }
    }
    fillPath.lineTo((scores.length - 1) * stepX, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    final dotPaint = Paint()..color = color..style = PaintingStyle.fill;
    for (int i = 0; i < scores.length; i++) {
      canvas.drawCircle(Offset(i * stepX, size.height - (scores[i] / 100 * size.height)), 4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}
