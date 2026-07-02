import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
  bool _isLoading = true;
  bool _isListening = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final c in _answerControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadDocument() async {
    final repo = ref.read(articleRepositoryProvider);
    final reviewRepo = ref.read(reviewRepositoryProvider);

    final article = await repo.getArticleById(widget.documentId);
    if (article != null) {
      final List<String> list = [];
      for (final sec in article.sections) {
        for (final p in sec.paragraphs) {
          if (p.text.trim().isNotEmpty) {
            list.add(p.text);
          }
        }
      }

      final draftSession = await reviewRepo.getLatestDraftSession(widget.documentId);
      List<String> draftAnswers = List.filled(list.length, '');
      int resumeIndex = 0;

      if (draftSession != null) {
        _sessionId = draftSession.id;
        final savedAnswers = await reviewRepo.getAnswersBySession(draftSession.id!);
        for (final sa in savedAnswers) {
          if (sa.paragraphIdx >= 0 && sa.paragraphIdx < list.length) {
            draftAnswers[sa.paragraphIdx] = sa.userAnswer;
            if (sa.userAnswer.isNotEmpty && sa.paragraphIdx >= resumeIndex) {
              resumeIndex = sa.paragraphIdx + 1;
            }
          }
        }
        if (resumeIndex >= list.length) {
          resumeIndex = list.length - 1;
        }
      } else {
        final sid = await reviewRepo.createSession(widget.documentId);
        _sessionId = sid;
        for (int idx = 0; idx < list.length; idx++) {
          await reviewRepo.insertAnswer(ReviewAnswer(
            sessionId: sid,
            paragraphIdx: idx,
            paragraphText: list[idx],
            userAnswer: '',
          ));
        }
      }

      setState(() {
        _paragraphs = list;
        _answers = draftAnswers;
        for (final ans in draftAnswers) {
          _answerControllers.add(TextEditingController(text: ans));
        }
        _isLoading = false;
        _currentIndex = resumeIndex;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) {
          _pageController.jumpToPage(resumeIndex);
        }
      });
    }
  }

  Future<void> _saveDraftAnswer(int paragraphIdx, String text) async {
    if (_sessionId == null) return;
    final reviewRepo = ref.read(reviewRepositoryProvider);
    await reviewRepo.updateUserAnswer(
      sessionId: _sessionId!,
      paragraphIdx: paragraphIdx,
      userAnswer: text,
    );
  }

  Future<void> _toggleVoice() async {
    final speech = ref.read(speechServiceProvider);
    if (_isListening) {
      await speech.stop();
      setState(() => _isListening = false);
    } else {
      final ok = await speech.initialize();
      if (ok) {
        setState(() => _isListening = true);
        await speech.listen(
          onResult: (text) {
            setState(() {
              _answerControllers[_currentIndex].text = text;
              _answers[_currentIndex] = text;
            });
            _saveDraftAnswer(_currentIndex, text);
          },
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Speech recognition is not available.')),
          );
        }
      }
    }
  }

  Future<void> _submitAll() async {
    if (_sessionId == null || _isSubmitting) return;
    setState(() => _isSubmitting = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('AI evaluating comprehension...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final reviewRepo = ref.read(reviewRepositoryProvider);
      final aiRepository = ref.read(aiRepositoryProvider);

      final sessionId = _sessionId!;

      final answers = await reviewRepo.getAnswersBySession(sessionId);

      try {
        final vocabRepo = ref.read(vocabularyRepositoryProvider);
        final savedVocab = await vocabRepo.getVocabularyByDocument(widget.documentId);
        final savedWords = savedVocab.map((v) => v.word).toList();

        final result = await aiRepository.evaluateRecall(
          paragraphs: answers.map((a) => a.paragraphText).toList(),
          answers: answers.map((a) => a.userAnswer).toList(),
          savedVocabulary: savedWords,
        );

        final double overall = (result['overall_score'] as num?)?.toDouble() ?? 0.0;

        final String suggestions = jsonEncode({
          'suggestions': result['suggestions'] ?? [],
          'strengths': result['strengths'] ?? [],
          'need_review': result['need_review'] ?? [],
          'paragraph_score': result['paragraph_score'] ?? 0,
          'concept_score': result['concept_score'] ?? 0,
          'logic_score': result['logic_score'] ?? 0,
          'vocabulary_score': result['vocabulary_score'] ?? 0,
          'calculation_process': result['calculation_process'] ?? '',
        });

        final String vocabImpact = jsonEncode(result['vocab_impact'] ?? []);

        await reviewRepo.updateSessionScore(
          sessionId: sessionId,
          score: overall,
          suggestions: suggestions,
          vocabImpact: vocabImpact,
        );

        final historyRepo = ref.read(historyRepositoryProvider);
        await historyRepo.insertScore(widget.documentId, overall);

        final misunderstood = result['misunderstood_paragraphs'] as List<dynamic>? ?? [];
        final completedAnswers = await reviewRepo.getAnswersBySession(sessionId);
        for (final answer in completedAnswers) {
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
        final completedAnswers = await reviewRepo.getAnswersBySession(sessionId);
        for (final answer in completedAnswers) {
          await reviewRepo.updateAnswerFeedback(
            answer.id!,
            100.0,
            'correct',
            'Recall completed (AI analysis offline).',
          );
        }
      }

      if (mounted) {
        Navigator.pop(context);
        context.pushReplacement('/review/$sessionId');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
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
            fontWeight: FontWeight.bold,
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
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (_currentIndex + 1) / _paragraphs.length,
                backgroundColor: ColorTokens.getDivider(isDark),
                valueColor: const AlwaysStoppedAnimation(ColorTokens.accent),
                minHeight: 4,
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
                        color: ColorTokens.getBackground(isDark),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: ColorTokens.getDivider(isDark), width: 1.0),
                        boxShadow: ColorTokens.getShadow(isDark),
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
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Describe what the author is expressing here.',
                      style: AppTypography.subheadline.copyWith(
                        color: ColorTokens.getTextSecondary(isDark),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _answerControllers[i],
                      maxLines: 5,
                      style: AppTypography.bodySans.copyWith(
                        color: ColorTokens.getTextPrimary(isDark),
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Write your recall here...',
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
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: ColorTokens.getSurfaceSecondary(isDark),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: ColorTokens.getDivider(isDark), width: 0.5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isListening ? LucideIcons.mic : LucideIcons.mic,
                              size: 16,
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: ColorTokens.getBackground(isDark),
        border: Border(top: BorderSide(color: ColorTokens.getDivider(isDark), width: 1.0)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(LucideIcons.chevronLeft, size: 16),
                label: const Text('Previous'),
                onPressed: _currentIndex > 0
                    ? () => _pageController.previousPage(duration: const Duration(milliseconds: 180), curve: Curves.easeOut)
                    : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FilledButton.icon(
                icon: Icon(_currentIndex < _paragraphs.length - 1 ? LucideIcons.chevronRight : LucideIcons.check, size: 16),
                label: Text(_currentIndex < _paragraphs.length - 1 ? 'Next' : 'Finish'),
                onPressed: _currentIndex < _paragraphs.length - 1
                    ? () => _pageController.nextPage(duration: const Duration(milliseconds: 180), curve: Curves.easeOut)
                    : _submitAll,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
