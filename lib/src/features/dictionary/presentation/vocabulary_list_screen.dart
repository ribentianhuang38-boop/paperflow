import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/database/app_database.dart';
import '../data/vocabulary_dao.dart';
import '../../library/presentation/library_screen.dart';

final vocabularyDaoProvider = Provider<VocabularyDao>((ref) {
  return VocabularyDao(ref.watch(databaseProvider));
});

final vocabularyListProvider = FutureProvider<List<VocabularyData>>((ref) async {
  final dao = ref.watch(vocabularyDaoProvider);
  return dao.getAllVocabulary();
});

class VocabularyListScreen extends ConsumerWidget {
  const VocabularyListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vocabAsync = ref.watch(vocabularyListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vocabulary'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Export',
            onPressed: () => _exportVocabulary(context, ref),
          ),
        ],
      ),
      body: vocabAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bookmark_outline,
                      size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No vocabulary collected yet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Long press on words while reading to add them',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade500,
                        ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _VocabularyTile(item: item);
            },
          );
        },
      ),
    );
  }

  Future<void> _exportVocabulary(
      BuildContext context, WidgetRef ref) async {
    final dao = ref.read(vocabularyDaoProvider);
    final words = await dao.exportVocabulary();

    if (words.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No vocabulary to export')),
        );
      }
      return;
    }

    final text = words.join('\n');
    await Clipboard.setData(ClipboardData(text: text));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${words.length} words copied to clipboard')),
      );
    }
  }
}

class _VocabularyTile extends ConsumerWidget {
  final VocabularyData item;

  const _VocabularyTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Word'),
            content: Text('Remove "${item.word}" from vocabulary?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) {
        ref.read(vocabularyDaoProvider).deleteVocabulary(item.id);
        ref.invalidate(vocabularyListProvider);
      },
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: item.globalMastered
              ? Colors.green.shade100
              : Colors.grey.shade200,
          child: Icon(
            item.globalMastered ? Icons.check : Icons.bookmark_outline,
            color: item.globalMastered ? Colors.green : Colors.grey,
          ),
        ),
        title: Text(
          item.word,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.pos != null)
              Text(
                item.pos!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontStyle: FontStyle.italic,
                ),
              ),
            if (item.definition != null && item.definition!.isNotEmpty)
              Text(
                item.definition!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            if (item.cnDefinition != null && item.cnDefinition!.isNotEmpty)
              Text(
                item.cnDefinition!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade600),
              ),
          ],
        ),
        trailing: Text(
          'x${item.queryCount}',
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
