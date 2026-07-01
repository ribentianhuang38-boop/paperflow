import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../common/ai/ai_client.dart';
import 'package:paperflow/src/common/providers.dart';
import '../../library/presentation/library_screen.dart';

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
    _speechToText.initialize();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _loadDocument() async {
    final repo = await ref.read(documentRepositoryProvider.future);
    final doc = await repo.getDocumentById(widget.documentId);
    if (doc != null && mounted) {
      setState(() {
        _paragraphs = [
          'This is a sample paragraph from the document. In a real implementation, the document would be parsed into meaningful paragraphs for recall practice.',
          'Another paragraph that demonstrates the active recall feature. The user would read the paper, then try to recall what each paragraph was about.',
          'A third paragraph covering the methodology section. Users should describe the approach taken by the authors and the key techniques used.',
        ];
        _answers = List.filled(_paragraphs.length, '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_paragraphs.isEmpty) {
      return Scaffold(appBar: AppBar(title: const Text('Active Recall')),
          body: const Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Paragraph ${_currentIndex + 1} / ${_paragraphs.length}'),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _submitAll,
            child: _isSubmitting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Finish'),
          ),
        ],
      ),
      body: Column(children: [
        LinearProgressIndicator(value: (_currentIndex + 1) / _paragraphs.length),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _paragraphs.length,
            onPageChanged: (i) {
              setState(() { _currentIndex = i; _answerController.text = _answers[i]; });
            },
            itemBuilder: (ctx, i) => SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(_paragraphs[i],
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6)),
                ),
                const SizedBox(height: 24),
                Text('Describe what this paragraph means',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Text('What did the author express here?',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600)),
                const SizedBox(height: 16),
                TextField(
                  controller: _answerController,
                  maxLines: 6,
                  decoration: InputDecoration(
                    hintText: 'Write your recall here...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                  ),
                  onChanged: (v) => _answers[i] = v,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _toggleVoice,
                    icon: Icon(_isListening ? Icons.mic : Icons.mic_none, color: _isListening ? Colors.red : null),
                    label: Text(_isListening ? 'Listening...' : 'Voice Input'),
                  ),
                ),
              ]),
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Expanded(child: OutlinedButton(
                  onPressed: _currentIndex > 0 ? () => _pageController.previousPage(
                      duration: const Duration(milliseconds: 300), curve: Curves.easeInOut) : null,
                  child: const Text('Previous'))),
              const SizedBox(width: 16),
              Expanded(child: FilledButton(
                  onPressed: _currentIndex < _paragraphs.length - 1
                      ? () => _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut)
                      : _submitAll,
                  child: Text(_currentIndex < _paragraphs.length - 1 ? 'Next' : 'Finish'))),
            ]),
          ),
        ),
      ]),
    );
  }

  Future<void> _toggleVoice() async {
    if (_isListening) {
      await _speechToText.stop();
      setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);
      await _speechToText.listen(onResult: (r) {
        setState(() { _answerController.text = r.recognizedWords; _answers[_currentIndex] = r.recognizedWords; });
      });
    }
  }

  Future<void> _submitAll() async {
    setState(() => _isSubmitting = true);
    try {
      final recallDao = await ref.read(recallSessionDaoProvider.future);
      final masteryDao = await ref.read(masteryDaoProvider.future);
      final aiClient = ref.read(aiClientProvider);

      final sessionId = await recallDao.createSession(widget.documentId);
      for (int i = 0; i < _paragraphs.length; i++) {
        await recallDao.insertAnswer(
          sessionId: sessionId, paragraphIdx: i,
          paragraphText: _paragraphs[i], userAnswer: _answers[i],
        );
      }

      try {
        final result = await aiClient.chatJson([
          {'role': 'system', 'content': _systemPrompt},
          {'role': 'user', 'content': _userPrompt},
        ]);
        final score = (result['overall_understanding'] as num?)?.toDouble() ?? 0.0;
        await recallDao.updateSessionScore(sessionId, score);
        await masteryDao.insertScore(widget.documentId, score);
      } catch (e) { debugPrint('AI failed: $e'); }

      if (mounted) context.push('/review/$sessionId');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String get _systemPrompt => '''You are an academic paper reading comprehension evaluator. Evaluate strictly according to the rubric.

Scoring Rubric (0-100):
- 90-100: Accurately restates core contributions, method details, experimental conclusions, no significant errors
- 70-89: Understands main ideas, some details vague or minor errors
- 50-69: Understands general direction, but significant misunderstandings in method/experiment
- 30-49: Only understands background and motivation, core content misunderstood
- 0-29: Basically no understanding

Rules:
1. Quote key expressions from the user's response
2. Compare with the original text
3. Give clear correct / partial / wrong judgment
4. Incomplete but correct statements: do not deduct points
5. Only deduct for incorrect statements

Output: Strict JSON only
{"overall_understanding":82,"misunderstood_paragraphs":[{"index":0,"score":60,"judgment":"partial","reason":"..."}],"suggestions":["..."]}''';

  String get _userPrompt {
    final buf = StringBuffer('Evaluate the following recall responses:\n\n');
    for (int i = 0; i < _paragraphs.length; i++) {
      buf.writeln('[Paragraph ${i + 1}]');
      buf.writeln('Original: ${_paragraphs[i]}');
      buf.writeln('User recall: ${_answers[i]}\n');
    }
    return buf.toString();
  }
}
