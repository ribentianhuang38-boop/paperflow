import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:paperflow/src/common/providers.dart';
import '../../../common/theme/colors.dart';
import '../../../common/theme/typography.dart';

class WordPopup extends ConsumerStatefulWidget {
  final String word;
  final int documentId;
  const WordPopup({super.key, required this.word, required this.documentId});

  @override
  ConsumerState<WordPopup> createState() => _WordPopupState();
}

class _WordPopupState extends ConsumerState<WordPopup> {
  bool _isLoading = true;
  bool _isCollected = false;
  String _definition = '';
  String _cnDefinition = '';
  String _pos = '';

  @override
  void initState() {
    super.initState();
    _lookup();
  }

  Future<void> _lookup() async {
    final dao = await ref.read(vocabularyDaoProvider.future);
    final existing = await dao.getVocabularyByWord(widget.word);
    if (mounted) {
      setState(() {
        _isLoading = false;
        _isCollected = existing != null;
        if (existing != null) {
          _definition = existing['definition'] as String? ?? '';
          _cnDefinition = existing['cnDefinition'] as String? ?? '';
          _pos = existing['pos'] as String? ?? '';
        } else {
          _definition = 'Tap the bookmark to save this word.';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Text(widget.word,
                    style: AppTypography.title1.copyWith(
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    )),
              ),
              GestureDetector(
                onTap: _toggle,
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: _isCollected
                        ? AppColors.accent.withOpacity(0.12)
                        : (isDark ? AppColors.darkSurfaceSecondary : AppColors.surfaceSecondary),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    _isCollected ? Icons.bookmark : Icons.bookmark_outline,
                    color: _isCollected ? AppColors.accent : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                  ),
                ),
              ),
            ],
          ),
          if (_pos.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(_pos, style: AppTypography.footnote.copyWith(
              color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
              fontStyle: FontStyle.italic,
            )),
          ],
          const SizedBox(height: 20),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else ...[
            if (_definition.isNotEmpty) ...[
              Text('Definition', style: AppTypography.caption2.copyWith(
                color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
              )),
              const SizedBox(height: 4),
              Text(_definition, style: AppTypography.bodySans.copyWith(
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              )),
            ],
            if (_cnDefinition.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('中文释义', style: AppTypography.caption2.copyWith(
                color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
              )),
              const SizedBox(height: 4),
              Text(_cnDefinition, style: AppTypography.bodySans.copyWith(
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              )),
            ],
          ],
        ],
      ),
    );
  }

  Future<void> _toggle() async {
    final dao = await ref.read(vocabularyDaoProvider.future);
    if (_isCollected) {
      final existing = await dao.getVocabularyByWord(widget.word);
      if (existing != null) await dao.deleteVocabulary(existing['id'] as int);
    } else {
      await dao.addWord(
        word: widget.word,
        definition: _definition.isNotEmpty ? _definition : null,
        cnDefinition: _cnDefinition.isNotEmpty ? _cnDefinition : null,
        pos: _pos.isNotEmpty ? _pos : null,
        documentId: widget.documentId,
      );
    }
    if (mounted) setState(() => _isCollected = !_isCollected);
  }
}
