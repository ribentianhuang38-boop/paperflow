import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/app/providers.dart';
import '../../../../core/design_system/color_tokens.dart';
import '../../../../core/design_system/typography.dart';
import '../../../../models/article/highlight.dart';
import '../../../../models/article/note.dart';

class HighlightOptionsSheet extends ConsumerWidget {
  final int articleId;
  final int paragraphId;
  final int offset;
  final int length;
  final String text;
  final VoidCallback onReload;

  const HighlightOptionsSheet({
    super.key,
    required this.articleId,
    required this.paragraphId,
    required this.offset,
    required this.length,
    required this.text,
    required this.onReload,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          Text('Selected Text', style: AppTypography.caption2.copyWith(
            color: ColorTokens.getTextTertiary(isDark),
            fontWeight: FontWeight.bold,
          )),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ColorTokens.getSurfaceSecondary(isDark),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              text,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySans.copyWith(
                color: ColorTokens.getTextPrimary(isDark),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Highlight Color', style: AppTypography.caption2.copyWith(
            color: ColorTokens.getTextTertiary(isDark),
            fontWeight: FontWeight.bold,
          )),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _colorCircle(context, ref, 'yellow', Colors.amber),
              _colorCircle(context, ref, 'green', Colors.green),
              _colorCircle(context, ref, 'blue', Colors.blue),
              _colorCircle(context, ref, 'pink', Colors.pink),
            ],
          ),
        ],
      ),
    );
  }

  Widget _colorCircle(BuildContext context, WidgetRef ref, String colorName, Color color) {
    return GestureDetector(
      onTap: () async {
        final repo = ref.read(articleRepositoryProvider);
        await repo.addHighlight(Highlight(
          articleId: articleId,
          paragraphId: paragraphId,
          offset: offset,
          length: length,
          color: colorName,
          createdAt: DateTime.now().millisecondsSinceEpoch,
        ));
        Navigator.pop(context);
        onReload();
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color.withOpacity(0.35),
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2),
        ),
      ),
    );
  }
}

class ModifyHighlightSheet extends ConsumerWidget {
  final int highlightId;
  final VoidCallback onReload;

  const ModifyHighlightSheet({
    super.key,
    required this.highlightId,
    required this.onReload,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          ListTile(
            leading: const Icon(Icons.delete_outline, color: ColorTokens.error),
            title: const Text('Delete Highlight', style: TextStyle(color: ColorTokens.error)),
            onTap: () async {
              final repo = ref.read(articleRepositoryProvider);
              await repo.deleteHighlight(highlightId);
              Navigator.pop(context);
              onReload();
            },
          ),
        ],
      ),
    );
  }
}

class NoteEditorSheet extends ConsumerStatefulWidget {
  final int articleId;
  final int paragraphId;
  final String paragraphText;
  final VoidCallback onReload;

  const NoteEditorSheet({
    super.key,
    required this.articleId,
    required this.paragraphId,
    required this.paragraphText,
    required this.onReload,
  });

  @override
  ConsumerState<NoteEditorSheet> createState() => _NoteEditorSheetState();
}

class _NoteEditorSheetState extends ConsumerState<NoteEditorSheet> {
  final TextEditingController _controller = TextEditingController();
  Note? _existingNote;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNote();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadNote() async {
    final repo = ref.read(articleRepositoryProvider);
    final note = await repo.getNoteForParagraph(widget.articleId, widget.paragraphId);
    if (note != null) {
      _controller.text = note.content;
      _existingNote = note;
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 40),
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
          Text('Paragraph Context', style: AppTypography.caption2.copyWith(
            color: ColorTokens.getTextTertiary(isDark),
            fontWeight: FontWeight.bold,
          )),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ColorTokens.getSurfaceSecondary(isDark),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              widget.paragraphText,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption1.copyWith(
                color: ColorTokens.getTextSecondary(isDark),
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _controller,
            maxLines: 4,
            autofocus: true,
            style: AppTypography.bodySans.copyWith(color: ColorTokens.getTextPrimary(isDark)),
            decoration: const InputDecoration(
              hintText: 'Type your notes here...',
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_existingNote != null)
                TextButton(
                  onPressed: () async {
                    final repo = ref.read(articleRepositoryProvider);
                    await repo.deleteNote(_existingNote!.id!);
                    Navigator.pop(context);
                    widget.onReload();
                  },
                  child: const Text('Delete', style: TextStyle(color: ColorTokens.error)),
                )
              else
                const SizedBox.shrink(),
              FilledButton(
                onPressed: () async {
                  final text = _controller.text.trim();
                  if (text.isEmpty) return;
                  final repo = ref.read(articleRepositoryProvider);
                  await repo.saveNote(Note(
                    id: _existingNote?.id,
                    articleId: widget.articleId,
                    paragraphId: widget.paragraphId,
                    content: text,
                    createdAt: _existingNote?.createdAt ?? DateTime.now().millisecondsSinceEpoch,
                    updatedAt: DateTime.now().millisecondsSinceEpoch,
                  ));
                  Navigator.pop(context);
                  widget.onReload();
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
