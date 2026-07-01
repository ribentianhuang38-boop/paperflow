import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:paperflow/src/common/providers.dart';

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
    _lookupWord();
  }

  Future<void> _lookupWord() async {
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
          _definition = 'Tap "Add to Vocabulary" to save this word';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(widget.word,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600)),
          ),
          IconButton(
            icon: Icon(_isCollected ? Icons.bookmark : Icons.bookmark_outline,
                color: _isCollected ? Theme.of(context).colorScheme.primary : null),
            onPressed: _toggleVocabulary,
          ),
        ]),
        if (_pos.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(_pos, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600, fontStyle: FontStyle.italic)),
        ],
        const SizedBox(height: 16),
        if (_isLoading) const Center(child: CircularProgressIndicator())
        else if (_definition.isNotEmpty) ...[
          Text('Definition', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          Text(_definition, style: Theme.of(context).textTheme.bodyLarge),
        ],
        if (_cnDefinition.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('中文释义', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          Text(_cnDefinition, style: Theme.of(context).textTheme.bodyLarge),
        ],
        const SizedBox(height: 24),
      ]),
    );
  }

  Future<void> _toggleVocabulary() async {
    final dao = await ref.read(vocabularyDaoProvider.future);
    if (_isCollected) {
      final existing = await dao.getVocabularyByWord(widget.word);
      if (existing != null) await dao.deleteVocabulary(existing['id'] as int);
    } else {
      await dao.addWord(
        word: widget.word, definition: _definition.isNotEmpty ? _definition : null,
        cnDefinition: _cnDefinition.isNotEmpty ? _cnDefinition : null,
        pos: _pos.isNotEmpty ? _pos : null, documentId: widget.documentId,
      );
    }
    if (mounted) setState(() => _isCollected = !_isCollected);
  }
}
