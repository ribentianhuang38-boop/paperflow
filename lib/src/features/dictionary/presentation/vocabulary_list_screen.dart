import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:paperflow/src/common/providers.dart';

class VocabularyListScreen extends ConsumerWidget {
  const VocabularyListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _loadVocabulary(ref),
        builder: (ctx, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final items = snap.data!;
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bookmark_outline, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('No vocabulary collected yet',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey.shade600)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: items.length,
            itemBuilder: (ctx, i) => _VocabularyTile(item: items[i]),
          );
        },
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _loadVocabulary(WidgetRef ref) async {
    final dao = await ref.read(vocabularyDaoProvider.future);
    return dao.getAllVocabulary();
  }

  Future<void> _exportVocabulary(BuildContext context, WidgetRef ref) async {
    final dao = await ref.read(vocabularyDaoProvider.future);
    final words = await dao.exportVocabulary();
    if (words.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No vocabulary to export')));
      }
      return;
    }
    await Clipboard.setData(ClipboardData(text: words.join('\n')));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${words.length} words copied')));
    }
  }
}

class _VocabularyTile extends StatelessWidget {
  final Map<String, dynamic> item;
  const _VocabularyTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final mastered = (item['globalMastered'] as int?) == 1;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: mastered ? Colors.green.shade100 : Colors.grey.shade200,
        child: Icon(mastered ? Icons.check : Icons.bookmark_outline,
            color: mastered ? Colors.green : Colors.grey),
      ),
      title: Text(item['word'] as String, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item['pos'] != null)
            Text(item['pos'] as String,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontStyle: FontStyle.italic)),
          if (item['definition'] != null)
            Text(item['definition'] as String, maxLines: 1, overflow: TextOverflow.ellipsis),
          if (item['cnDefinition'] != null)
            Text(item['cnDefinition'] as String,
                maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
      trailing: Text('x${item['queryCount']}', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
    );
  }
}
