import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:paperflow/src/common/providers.dart';

class ReviewResultScreen extends ConsumerWidget {
  final int sessionId;
  const ReviewResultScreen({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Review'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/')),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _loadAnswers(ref),
        builder: (ctx, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final answers = snap.data!;
          if (answers.isEmpty) return const Center(child: Text('No review data'));

          final scored = answers.where((a) => a['aiScore'] != null).toList();
          final avg = scored.isEmpty ? 0.0
              : scored.map((a) => a['aiScore'] as double).reduce((a, b) => a + b) / scored.length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _buildOverall(context, avg, answers.length),
              const SizedBox(height: 32),
              _buildDetails(context, answers),
            ]),
          );
        },
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _loadAnswers(WidgetRef ref) async {
    final dao = await ref.read(recallSessionDaoProvider.future);
    return dao.getAnswersBySession(sessionId);
  }

  Widget _buildOverall(BuildContext context, double score, int total) {
    final color = score >= 80 ? Colors.green : score >= 60 ? Colors.orange : Colors.red;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          Text('Overall Understanding', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey.shade600)),
          const SizedBox(height: 16),
          SizedBox(
            width: 120, height: 120,
            child: Stack(alignment: Alignment.center, children: [
              CircularProgressIndicator(value: score / 100, strokeWidth: 8,
                  backgroundColor: Colors.grey.shade200, valueColor: AlwaysStoppedAnimation(color)),
              Column(mainAxisSize: MainAxisSize.min, children: [
                Text('${score.round()}%',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700, color: color)),
                Text(score >= 80 ? 'You Understood Well' : 'Need Review',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600)),
              ]),
            ]),
          ),
          const SizedBox(height: 16),
          Text('You recalled $total paragraphs', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600)),
        ]),
      ),
    );
  }

  Widget _buildDetails(BuildContext context, List<Map<String, dynamic>> answers) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Paragraph Details', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
      const SizedBox(height: 12),
      ...answers.map((a) {
        final judgment = a['aiJudgment'] as String?;
        final color = judgment == 'correct' ? Colors.green
            : judgment == 'partial' ? Colors.orange : Colors.red;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text('Paragraph ${(a['paragraphIdx'] as int) + 1}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                const Spacer(),
                if (a['aiScore'] != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                    child: Text('${(a['aiScore'] as double).round()}%',
                        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
                  ),
              ]),
              if (judgment != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                  child: Text(judgment.toUpperCase(),
                      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                ),
              ],
              if (a['aiFeedback'] != null && (a['aiFeedback'] as String).isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(a['aiFeedback'] as String, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700)),
              ],
            ]),
          ),
        );
      }),
    ]);
  }
}
