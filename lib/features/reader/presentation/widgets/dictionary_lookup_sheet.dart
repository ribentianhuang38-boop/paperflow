import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/app/providers.dart';
import '../../../../core/design_system/color_tokens.dart';
import '../../../../core/design_system/typography.dart';
import '../../../../models/vocabulary/vocabulary.dart';

class DictionaryLookupSheet extends ConsumerStatefulWidget {
  final String cleanWord;
  final int documentId;

  const DictionaryLookupSheet({
    super.key,
    required this.cleanWord,
    required this.documentId,
  });

  @override
  ConsumerState<DictionaryLookupSheet> createState() => _DictionaryLookupSheetState();
}

class _DictionaryLookupSheetState extends ConsumerState<DictionaryLookupSheet> {
  late String _currentWord;
  bool _isSaved = false;
  int _queryCount = 1;
  Vocabulary? _existingVocab;
  List<Vocabulary> _recentLookups = [];

  @override
  void initState() {
    super.initState();
    _currentWord = widget.cleanWord;
    _checkStatus();
    _loadRecentLookups();
  }

  Future<void> _checkStatus() async {
    final vocabRepo = ref.read(vocabularyRepositoryProvider);
    final vocab = await vocabRepo.getVocabularyByWord(_currentWord);
    if (vocab != null) {
      setState(() {
        _isSaved = vocab.isStarred;
        _queryCount = vocab.queryCount;
        _existingVocab = vocab;
      });
    }
  }

  Future<void> _loadRecentLookups() async {
    final vocabRepo = ref.read(vocabularyRepositoryProvider);
    final recents = await vocabRepo.getRecentLookups(8);
    setState(() {
      _recentLookups = recents.where((v) => v.word != _currentWord).toList();
    });
  }

  Future<Map<String, dynamic>> _fetchDefinition() async {
    final dictService = ref.read(dictionaryServiceProvider);
    final result = await dictService.lookupWord(_currentWord);
    if (result != null) {
      return result;
    }
    return {
      'word': _currentWord,
      'phonetic': '',
      'pos': 'word',
      'definition': 'Definition not found online. Tap Bookmark to save to your local vocabulary.',
    };
  }

  void _updateWord(String word) {
    setState(() {
      _currentWord = word.toLowerCase().trim();
      _isSaved = false;
      _queryCount = 1;
      _existingVocab = null;
    });
    _checkStatus();
    _loadRecentLookups();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchDefinition(),
      builder: (context, snap) {
        final data = snap.data ?? {
          'word': _currentWord,
          'phonetic': '',
          'pos': 'word',
          'definition': snap.connectionState == ConnectionState.waiting 
              ? 'Searching...' 
              : 'Definition not found online. Tap Bookmark to save to your local vocabulary.',
        };

        final displayWord = data['word'] as String;
        final phonetic = data['phonetic'] as String;
        final pos = data['pos'] as String;
        final definition = data['definition'] as String;

        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 5,
                  decoration: BoxDecoration(
                    color: ColorTokens.getDivider(isDark),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayWord,
                          style: AppTypography.largeTitle.copyWith(
                            color: ColorTokens.getTextPrimary(isDark),
                            fontSize: 28,
                          ),
                        ),
                        if (phonetic.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            phonetic,
                            style: AppTypography.caption1.copyWith(
                              color: ColorTokens.accent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _isSaved ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: _isSaved ? Colors.amber : ColorTokens.getTextTertiary(isDark),
                      size: 28,
                    ),
                    onPressed: () async {
                      final vocabRepo = ref.read(vocabularyRepositoryProvider);
                      if (_existingVocab != null) {
                        final updated = _existingVocab!.copyWith(isStarred: !_isSaved);
                        await vocabRepo.saveVocabulary(updated);
                        setState(() {
                          _isSaved = !_isSaved;
                          _existingVocab = updated;
                        });
                      } else {
                        final newVocab = Vocabulary(
                          word: _currentWord,
                          meaning: definition,
                          context: 'Read in Article ID ${widget.documentId}',
                          documentId: widget.documentId,
                          queryCount: 1,
                          isStarred: true,
                        );
                        final id = await vocabRepo.saveVocabulary(newVocab);
                        setState(() {
                          _isSaved = true;
                          _existingVocab = newVocab.copyWith(id: id);
                        });
                      }
                      _loadRecentLookups();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: ColorTokens.accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      pos.toUpperCase(),
                      style: AppTypography.caption2.copyWith(
                        color: ColorTokens.accent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Queried $_queryCount times',
                    style: AppTypography.caption2.copyWith(
                      color: ColorTokens.getTextSecondary(isDark),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ColorTokens.getSurfaceSecondary(isDark),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  definition,
                  style: AppTypography.bodySans.copyWith(
                    color: ColorTokens.getTextPrimary(isDark),
                    height: 1.5,
                  ),
                ),
              ),
              if (_recentLookups.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  'Recent Lookups',
                  style: AppTypography.caption2.copyWith(
                    color: ColorTokens.getTextTertiary(isDark),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 38,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _recentLookups.length,
                    itemBuilder: (ctx, idx) {
                      final item = _recentLookups[idx];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          label: Text(
                            item.word,
                            style: AppTypography.caption1.copyWith(
                              color: ColorTokens.getTextPrimary(isDark),
                            ),
                          ),
                          backgroundColor: ColorTokens.getSurfaceSecondary(isDark),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          onPressed: () => _updateWord(item.word),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
