import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/app/providers.dart';
import '../../../core/design_system/color_tokens.dart';
import '../../../core/design_system/typography.dart';
import '../../../models/article/article.dart';
import '../../../models/review/review.dart';

class RecallScreen extends ConsumerStatefulWidget {
  final int documentId;
  const RecallScreen({super.key, required this.documentId});

  @override
  ConsumerState<RecallScreen> createState() => _RecallScreenState();
}

class _RecallScreenState extends ConsumerState<RecallScreen> {
  final PageController _pageController = PageController();
  final List<TextEditingController> _answerControllers = [];

  List<String> _paragraphs = [];
  List<String> _answers = [];
  int? _sessionId;
  int _currentIndex = 0;
  bool _isSubmitting = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _loadDocumentData();
    ref.read(speechServiceProvider).initialize();
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final c in _answerControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _saveDraftAnswer(int index, String value) async {
    if (_sessionId == null) return;
    try {
      final reviewRepo = ref.read(reviewRepositoryProvider);
      await reviewRepo.updateUserAnswer(
        sessionId: _sessionId!,
        paragraphIdx: index,
        userAnswer: value,
      );
    } catch (e) {
      debugPrint('Failed to save draft answer: $e');
    }
  }

  Future<void> _loadDocumentData() async {
    final articleRepo = ref.read(articleRepositoryProvider);
    final reviewRepo = ref.read(reviewRepositoryProvider);
    
    final article = await articleRepo.getArticleById(widget.documentId);
    if (article == null || !mounted) return;

    final List<String> paragraphsList = [];
    for (final sec in article.sections) {
      for (final p in sec.paragraphs) {
        paragraphsList.add(p.text);
      }
    }

    if (paragraphsList.isEmpty) {
      paragraphsList.add('Could not extract text from this document. Try with a text-based document.');
    }

    int? sessionId;
    List<String> answers = [];

    try {
      final draft = await reviewRepo.getLatestDraftSession(widget.documentId);
      if (draft != null) {
        sessionId = draft.id;
        final savedAnswers = await reviewRepo.getAnswersBySession(sessionId!);
        answers = List.filled(paragraphsList.length, '');
        for (final sa in savedAnswers) {
          final idx = sa.paragraphIdx;
          if (idx >= 0 && idx < paragraphsList.length) {
            answers[idx] = sa.userAnswer;
          }
        }
      } else {
        sessionId = await reviewRepo.createSession(widget.documentId);
        answers = List.filled(paragraphsList.length, '');
        for (int i = 0; i < paragraphsList.length; i++) {
          await reviewRepo.insertAnswer(ReviewAnswer(
            sessionId: sessionId,
            paragraphIdx: i,
            paragraphText: paragraphsList[i],
            userAnswer: '',
          ));
        }
      }
    } catch (e) {
      debugPrint('Failed to initialize recall session in DB: $e');
    }

    if (mounted) {
      setState(() {
        _paragraphs = paragraphsList;
        _answers = answers;
        _sessionId = sessionId;
        _answerControllers.clear();
        _answerControllers.addAll(List.generate(paragraphsList.length, (i) => TextEditingController(text: answers[i])));
      });
    }
  }

  Future<void> _toggleVoice() async {
    final speech = ref.read(speechServiceProvider);
    if (_isListening) {
      await speech.stop();
      setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);
      await speech.listen(onResult: (words) {
        setState(() {
          _answerControllers[_currentIndex].text = words;
          _answers[_currentIndex] = words;
        });
        _saveDraftAnswer(_currentIndex, words);
      });
    }
  }

  Future<void> _submitAll() async {
    setState(() => _isSubmitting = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text('Analyzing with AI...'),
                const SizedBox(height: 8),
                Text('This may take a moment', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final reviewRepo = ref.read(reviewRepositoryProvider);
      final historyRepo = ref.read(historyRepositoryProvider);
      final vocabRepo = ref.read(vocabularyRepositoryProvider);
      final aiRepo = ref.read(aiRepositoryProvider);

      final sessionId = _sessionId!;
      final savedVocab = await vocabRepo.getVocabularyByDocument(widget.documentId);
      final vocabList = savedVocab.map((v) => v.word).toList();

      try {
        final result = await aiRepo.evaluateRecall(
          paragraphs: _paragraphs,
          answers: _answers,
          savedVocabulary: vocabList,
        );

        final score = (result['overall_understanding'] as num?)?.toDouble() ?? 0.0;
        final suggestions = jsonEncode({
          'suggestions': result['suggestions'] ?? [],
          'strengths': result['strengths'] ?? [],
          'need_review': result['need_review'] ?? [],
          'paragraph_score': (result['paragraph_score'] as num?)?.toDouble() ?? 0.0,
          'concept_score': (result['concept_score'] as num?)?.toDouble() ?? 0.0,
          'logic_score': (result['logic_score'] as num?)?.toDouble() ?? 0.0,
          'vocabulary_score': (result['vocabulary_score'] as num?)?.toDouble() ?? 0.0,
          'calculation_process': result['calculation_process'] ?? '',
        });
        final vocabImpact = jsonEncode(result['vocab_impact'] ?? []);

        await reviewRepo.updateSessionScore(
          sessionId: sessionId,
          score: score,
          suggestions: suggestions,
          vocabImpact: vocabImpact,
        );
        await historyRepo.insertScore(widget.documentId, score);

        final misunderstood = result['misunderstood_paragraphs'] as List<dynamic>? ?? [];
        final answers = await reviewRepo.getAnswersBySession(sessionId);
        for (final answer in answers) {
          final idx = answer.paragraphIdx;
          final misItem = misunderstood.firstWhere(
            (m) => (m['index'] as int? ?? -1) == idx,
            orElse: () => null,
          );
          if (misItem != null) {
            await reviewRepo.updateAnswerFeedback(
              answer.id!,
              (misItem['score'] as num?)?.toDouble() ?? 0.0,
              misItem['judgment'] as String? ?? 'partial',
              misItem['reason'] as String? ?? '',
            );
          } else {
            await reviewRepo.updateAnswerFeedback(
              answer.id!,
              100.0,
              'correct',
              'Understanding verified. Good comprehension.',
            );
          }
        }
      } catch (e) {
        debugPrint('AI analysis failed: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('AI Analysis failed: $e. Using offline mode.'),
              backgroundColor: ColorTokens.error,
              duration: const Duration(seconds: 8),
            ),
          );
        }
        final answers = await reviewRepo.getAnswersBySession(sessionId);
        for (final answer in answers) {
          await reviewRepo.updateAnswerFeedback(
            answer.id!,
            100.0,
            'correct',
            'Recall completed (AI analysis offline).',
          );
        }
      }

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        context.pushReplacement('/review/$sessionId');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_paragraphs.isEmpty) {
      return Scaffold(
        backgroundColor: ColorTokens.getBackground(isDark),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: ColorTokens.getBackground(isDark),
      appBar: AppBar(
        title: Text(
          '${_currentIndex + 1} / ${_paragraphs.length}',
          style: AppTypography.subheadline.copyWith(
            color: ColorTokens.getTextSecondary(isDark),
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _submitAll,
            child: Text('Done', style: AppTypography.headline.copyWith(color: ColorTokens.accent)),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: (_currentIndex + 1) / _paragraphs.length,
                backgroundColor: ColorTokens.getDivider(isDark),
                valueColor: const AlwaysStoppedAnimation(ColorTokens.accent),
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
                setState(() { _currentIndex = i; });
              },
              itemBuilder: (ctx, i) => SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: ColorTokens.getSurface(isDark),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _paragraphs[i],
                        style: AppTypography.body.copyWith(
                          color: ColorTokens.getTextPrimary(isDark),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'What does this paragraph mean?',
                      style: AppTypography.title3.copyWith(
                        color: ColorTokens.getTextPrimary(isDark),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Describe what the author is expressing here.',
                      style: AppTypography.subheadline.copyWith(
                        color: ColorTokens.getTextTertiary(isDark),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _answerControllers[i],
                      maxLines: 5,
                      style: AppTypography.bodySans.copyWith(
                        color: ColorTokens.getTextPrimary(isDark),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Write your recall here...',
                        fillColor: ColorTokens.getSurfaceSecondary(isDark),
                      ),
                      onChanged: (v) {
                        _answers[i] = v;
                        _saveDraftAnswer(i, v);
                      },
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _toggleVoice,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: ColorTokens.getSurfaceSecondary(isDark),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isListening ? Icons.mic : Icons.mic_none,
                              size: 20,
                              color: _isListening ? ColorTokens.error : ColorTokens.getTextSecondary(isDark),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isListening ? 'Listening...' : 'Voice Input',
                              style: AppTypography.subheadline.copyWith(
                                color: ColorTokens.getTextSecondary(isDark),
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
          _buildNavigationRow(isDark),
        ],
      ),
    );
  }

  Widget _buildNavigationRow(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: ColorTokens.getSurface(isDark),
        border: Border(top: BorderSide(color: ColorTokens.getDivider(isDark), width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _currentIndex > 0
                    ? () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut)
                    : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: _currentIndex > 0 ? ColorTokens.getSurfaceSecondary(isDark) : ColorTokens.getSurfaceSecondary(isDark).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      'Previous',
                      style: AppTypography.headline.copyWith(
                        color: _currentIndex > 0 ? ColorTokens.getTextPrimary(isDark) : ColorTokens.getTextTertiary(isDark),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GestureDetector(
                onTap: _currentIndex < _paragraphs.length - 1
                    ? () => _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut)
                    : _submitAll,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: ColorTokens.accent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      _currentIndex < _paragraphs.length - 1 ? 'Next' : 'Done',
                      style: AppTypography.headline.copyWith(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
