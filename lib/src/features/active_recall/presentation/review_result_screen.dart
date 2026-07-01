import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../common/database/app_database.dart';
import '../data/recall_session_dao.dart';
import '../domain/ai_review_result.dart';
import 'recall_screen.dart';

final reviewSessionProvider =
    FutureProvider.family<RecallSession?, int>((ref, sessionId) async {
  final dao = ref.watch(recallSessionDaoProvider);
  final sessions = await dao.getSessionsByDocument(0); // TODO: get by session id
  return sessions.where((s) => s.id == sessionId).firstOrNull;
});

final reviewAnswersProvider =
    FutureProvider.family<List<RecallAnswer>, int>((ref, sessionId) async {
  final dao = ref.watch(recallSessionDaoProvider);
  return dao.getAnswersBySession(sessionId);
});

class ReviewResultScreen extends ConsumerWidget {
  final int sessionId;

  const ReviewResultScreen({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final answersAsync = ref.watch(reviewAnswersProvider(sessionId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Review'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: answersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (answers) {
          if (answers.isEmpty) {
            return const Center(child: Text('No review data'));
          }

          final answeredCount = answers.where((a) => a.userAnswer.isNotEmpty).length;
          final scoredAnswers = answers.where((a) => a.aiScore != null).toList();
          final avgScore = scoredAnswers.isEmpty
              ? 0.0
              : scoredAnswers.map((a) => a.aiScore!).reduce((a, b) => a + b) /
                  scoredAnswers.length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOverallScore(context, avgScore, answeredCount),
                const SizedBox(height: 32),
                _buildParagraphScores(context, answers),
                const SizedBox(height: 32),
                _buildSuggestions(context, answers),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOverallScore(
      BuildContext context, double score, int totalParagraphs) {
    final scoreColor = score >= 80
        ? Colors.green
        : score >= 60
            ? Colors.orange
            : Colors.red;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'Overall Understanding',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 8,
                    backgroundColor: Colors.grey.shade200,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(scoreColor),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${score.round()}%',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: scoreColor,
                            ),
                      ),
                      Text(
                        score >= 80
                            ? 'You Understood Well'
                            : 'Need Review',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'You recalled $totalParagraphs paragraphs',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParagraphScores(
      BuildContext context, List<RecallAnswer> answers) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Paragraph Details',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        ...answers.map((answer) => _buildAnswerCard(context, answer)),
      ],
    );
  }

  Widget _buildAnswerCard(BuildContext context, RecallAnswer answer) {
    final judgmentColor = answer.aiJudgment == 'correct'
        ? Colors.green
        : answer.aiJudgment == 'partial'
            ? Colors.orange
            : Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Paragraph ${answer.paragraphIdx + 1}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const Spacer(),
                if (answer.aiScore != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: judgmentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${answer.aiScore!.round()}%',
                      style: TextStyle(
                        color: judgmentColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (answer.aiJudgment != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: judgmentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  answer.aiJudgment!.toUpperCase(),
                  style: TextStyle(
                    color: judgmentColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            if (answer.aiFeedback != null && answer.aiFeedback!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                answer.aiFeedback!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade700,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestions(
      BuildContext context, List<RecallAnswer> answers) {
    final wrongAnswers =
        answers.where((a) => a.aiJudgment == 'wrong').toList();
    final partialAnswers =
        answers.where((a) => a.aiJudgment == 'partial').toList();

    if (wrongAnswers.isEmpty && partialAnswers.isEmpty) {
      return Card(
        color: Colors.green.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade600),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Great job! You understood the paper well.',
                  style: TextStyle(color: Colors.green.shade800),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Suggestions',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        if (wrongAnswers.isNotEmpty)
          Card(
            color: Colors.red.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade600),
                      const SizedBox(width: 8),
                      Text(
                        'Misunderstood Paragraphs',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.red.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...wrongAnswers.map((a) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '• Paragraph ${a.paragraphIdx + 1}',
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      )),
                ],
              ),
            ),
          ),
        if (partialAnswers.isNotEmpty) ...[
          const SizedBox(height: 8),
          Card(
            color: Colors.orange.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.orange.shade600),
                      const SizedBox(width: 8),
                      Text(
                        'Need Review',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...partialAnswers.map((a) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '• Paragraph ${a.paragraphIdx + 1}',
                          style: TextStyle(color: Colors.orange.shade700),
                        ),
                      )),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
