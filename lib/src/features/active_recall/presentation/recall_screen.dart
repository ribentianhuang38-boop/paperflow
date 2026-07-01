import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'package:paperflow/src/common/providers.dart';
import '../../../common/theme/colors.dart';
import '../../../common/theme/typography.dart';
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
  final SpeechToText _speech = SpeechToText();

  List<String> _paragraphs = [];
  List<String> _answers = [];
  int _currentIndex = 0;
  bool _isSubmitting = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _loadDocument();
    _speech.initialize();
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
          'A third paragraph covering the methodology section. Users should describe the approach taken by the authors.',
        ];
        _answers = List.filled(_paragraphs.length, '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_paragraphs.isEmpty) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: Text(
          '${_currentIndex + 1} / ${_paragraphs.length}',
          style: AppTypography.subheadline.copyWith(
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _submitAll,
            child: Text('Done', style: AppTypography.headline.copyWith(color: AppColors.accent)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: (_currentIndex + 1) / _paragraphs.length,
                backgroundColor: isDark ? AppColors.darkDivider : AppColors.divider,
                valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                minHeight: 3,
              ),
            ),
          ),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Paragraph card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _paragraphs[i],
                        style: AppTypography.body.copyWith(
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'What does this paragraph mean?',
                      style: AppTypography.title3.copyWith(
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Describe what the author is expressing here.',
                      style: AppTypography.subheadline.copyWith(
                        color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Input
                    TextField(
                      controller: _answerController,
                      maxLines: 5,
                      style: AppTypography.bodySans.copyWith(
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Write your recall here...',
                        fillColor: isDark ? AppColors.darkSurfaceSecondary : AppColors.surfaceSecondary,
                      ),
                      onChanged: (v) => _answers[i] = v,
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _toggleVoice,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurfaceSecondary : AppColors.surfaceSecondary,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isListening ? Icons.mic : Icons.mic_none,
                              size: 20,
                              color: _isListening ? AppColors.error : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isListening ? 'Listening...' : 'Voice Input',
                              style: AppTypography.subheadline.copyWith(
                                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Bottom buttons
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _currentIndex > 0
                          ? () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut)
                          : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurfaceSecondary : AppColors.surfaceSecondary,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text('Previous', style: AppTypography.headline.copyWith(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          )),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: _currentIndex < _paragraphs.length - 1
                          ? () => _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut)
                          : _submitAll,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(
                            _currentIndex < _paragraphs.length - 1 ? 'Next' : 'Finish',
                            style: AppTypography.headline.copyWith(color: Colors.white),
                          ),
                        ),
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

  Future<void> _toggleVoice() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);
      await _speech.listen(onResult: (r) {
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

  String get _systemPrompt => '''You are an academic paper reading comprehension evaluator. Evaluate strictly.

Scoring (0-100):
- 90-100: Accurate restatement, no significant errors
- 70-89: Main ideas understood, some details vague
- 50-69: General direction, significant method/experiment misunderstandings
- 30-49: Only background/motivation, core misunderstood
- 0-29: Basically no understanding

Rules: Quote user's words, compare with original, give correct/partial/wrong. Only deduct for incorrect statements.
Output: Strict JSON {"overall_understanding":82,"misunderstood_paragraphs":[{"index":0,"score":60,"judgment":"partial","reason":"..."}],"suggestions":["..."]}''';

  String get _userPrompt {
    final buf = StringBuffer('Evaluate recall responses:\n\n');
    for (int i = 0; i < _paragraphs.length; i++) {
      buf.writeln('[Paragraph ${i+1}]');
      buf.writeln('Original: ${_paragraphs[i]}');
      buf.writeln('User recall: ${_answers[i]}\n');
    }
    return buf.toString();
  }
}
