import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../common/database/app_database.dart';
import '../../../common/ai/ai_client.dart';
import '../../library/data/document_repository.dart';
import '../../library/presentation/library_screen.dart';
import '../data/recall_session_dao.dart';

final recallSessionDaoProvider = Provider<RecallSessionDao>((ref) {
  return RecallSessionDao(ref.watch(databaseProvider));
});

class RecallScreen extends ConsumerStatefulWidget {
  final int documentId;

  const RecallScreen({super.key, required this.documentId});

  @override
  ConsumerState<RecallScreen> createState() => _RecallScreenState();
}

class _RecallScreenState extends ConsumerState<RecallScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _answerController = TextEditingController();
  final SpeechToText _speechToText = SpeechToText();

  List<String> _paragraphs = [];
  List<String> _answers = [];
  int _currentIndex = 0;
  bool _isSubmitting = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _loadDocument();
    _initSpeech();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _loadDocument() async {
    final repo = ref.read(documentRepositoryProvider);
    final doc = await repo.getDocumentById(widget.documentId);
    if (doc != null && mounted) {
      // In a real app, parse the document content into paragraphs
      // For now, show placeholder
      setState(() {
        _paragraphs = [
          'This is a sample paragraph from the document. '
              'In a real implementation, the document would be parsed '
              'into meaningful paragraphs for recall practice.',
          'Another paragraph that demonstrates the active recall feature. '
              'The user would read the paper, then try to recall '
              'what each paragraph was about.',
          'A third paragraph covering the methodology section. '
              'Users should describe the approach taken by the authors '
              'and the key techniques used.',
        ];
        _answers = List.filled(_paragraphs.length, '');
      });
    }
  }

  Future<void> _initSpeech() async {
    await _speechToText.initialize();
  }

  @override
  Widget build(BuildContext context) {
    if (_paragraphs.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Active Recall')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Paragraph ${_currentIndex + 1} / ${_paragraphs.length}'),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _submitAll,
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Finish Review'),
          ),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: (_currentIndex + 1) / _paragraphs.length,
          ),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _paragraphs.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                  _answerController.text = _answers[index];
                });
              },
              itemBuilder: (context, index) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _paragraphs[index],
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(height: 1.6),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Describe what this paragraph means',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'What did the author express here?',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _answerController,
                        maxLines: 6,
                        decoration: InputDecoration(
                          hintText: 'Write your recall here...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                        ),
                        onChanged: (value) {
                          _answers[index] = value;
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _toggleVoiceInput,
                              icon: Icon(
                                _isListening ? Icons.mic : Icons.mic_none,
                                color: _isListening ? Colors.red : null,
                              ),
                              label: Text(
                                _isListening
                                    ? 'Listening...'
                                    : 'Voice Input',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _currentIndex > 0 ? _previousParagraph : null,
                      child: const Text('Previous'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton(
                      onPressed: _currentIndex < _paragraphs.length - 1
                          ? _nextParagraph
                          : _submitAll,
                      child: Text(
                        _currentIndex < _paragraphs.length - 1
                            ? 'Next Paragraph'
                            : 'Finish Review',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _nextParagraph() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _previousParagraph() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _toggleVoiceInput() async {
    if (_isListening) {
      await _speechToText.stop();
      setState(() => _isListening = false);
    } else {
      final available = await _speechToText.hasPermission;
      if (!available) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Microphone permission required')),
          );
        }
        return;
      }

      setState(() => _isListening = true);
      await _speechToText.listen(
        onResult: (result) {
          setState(() {
            _answerController.text = result.recognizedWords;
            _answers[_currentIndex] = result.recognizedWords;
          });
        },
      );
    }
  }

  Future<void> _submitAll() async {
    setState(() => _isSubmitting = true);

    try {
      final dao = ref.read(recallSessionDaoProvider);
      final aiClient = ref.read(aiClientProvider);

      // Create recall session
      final sessionId = await dao.createSession(
        RecallSessionsCompanion(
          documentId: Value(widget.documentId),
          createdAt: Value(DateTime.now().millisecondsSinceEpoch),
        ),
      );

      // Save all answers
      for (int i = 0; i < _paragraphs.length; i++) {
        await dao.insertAnswer(
          RecallAnswersCompanion(
            sessionId: Value(sessionId),
            paragraphIdx: Value(i),
            paragraphText: Value(_paragraphs[i]),
            userAnswer: Value(_answers[i]),
          ),
        );
      }

      // Call AI for analysis
      try {
        final messages = [
          {
            'role': 'system',
            'content': _buildSystemPrompt(),
          },
          {
            'role': 'user',
            'content': _buildUserPrompt(),
          },
        ];

        final result = await aiClient.chatJson(messages);
        final overallScore =
            (result['overall_understanding'] as num?)?.toDouble() ?? 0.0;

        await dao.updateSessionScore(sessionId, overallScore);

        // Update individual answers with AI feedback
        final misunderstood =
            result['misunderstood_paragraphs'] as List<dynamic>? ?? [];
        for (final item in misunderstood) {
          final idx = item['index'] as int;
          if (idx < _paragraphs.length) {
            final answers = await dao.getAnswersBySession(sessionId);
            final answer = answers.firstWhere((a) => a.paragraphIdx == idx);
            await dao.updateAnswer(
              answer.id,
              (item['score'] as num?)?.toDouble() ?? 0.0,
              item['judgment'] as String? ?? 'wrong',
              item['reason'] as String? ?? '',
            );
          }
        }

        // Update mastery score
        final masteryDao = ref.read(masteryDaoProvider);
        await masteryDao.insertScore(
          MasteryScoresCompanion(
            documentId: Value(widget.documentId),
            score: Value(overallScore),
            createdAt: Value(DateTime.now().millisecondsSinceEpoch),
          ),
        );
      } catch (e) {
        // AI call failed, still save the session
        debugPrint('AI analysis failed: $e');
      }

      if (mounted) {
        context.push('/review/$sessionId');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _buildSystemPrompt() {
    return '''You are an academic paper reading comprehension evaluator. 
Evaluate strictly according to the rubric below. Do not be subjective.

Scoring Rubric (0-100):
- 90-100: Accurately restates core contributions, method details, experimental conclusions, no significant errors
- 70-89: Understands main ideas, some details vague or minor errors
- 50-69: Understands general direction, but significant misunderstandings in method/experiment
- 30-49: Only understands background and motivation, core content misunderstood
- 0-29: Basically no understanding

Rules:
1. First quote key expressions from the user's response
2. Compare with the original text
3. Give clear correct / partial / wrong judgment
4. Incomplete but correct statements → do not deduct points
5. Only deduct for incorrect statements

Output: Strict JSON only, no other content

JSON format:
{
  "overall_understanding": 82,
  "misunderstood_paragraphs": [
    {"index": 0, "score": 60, "judgment": "partial", "reason": "..."}
  ],
  "suggestions": ["suggestion 1", "suggestion 2"]
}''';
  }

  String _buildUserPrompt() {
    final buffer = StringBuffer();
    buffer.writeln('Please evaluate the following recall responses:\n');

    for (int i = 0; i < _paragraphs.length; i++) {
      buffer.writeln('[Paragraph ${i + 1}]');
      buffer.writeln('Original: ${_paragraphs[i]}');
      buffer.writeln('User recall: ${_answers[i]}');
      buffer.writeln();
    }

    return buffer.toString();
  }
}

final masteryDaoProvider = Provider((ref) {
  return MasteryDao(ref.watch(databaseProvider));
});
