import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../common/database/app_database.dart';
import '../data/document_repository.dart';
import 'library_screen.dart';

class DocumentCard extends ConsumerWidget {
  final Document document;
  final bool compact;

  const DocumentCard({
    super.key,
    required this.document,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (compact) return _buildCompact(context, ref);
    return _buildFull(context, ref);
  }

  Widget _buildCompact(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: InkWell(
        onTap: () => _openReader(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _fileTypeIcon,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const Spacer(),
                  if (document.isFavorite)
                    Icon(Icons.favorite,
                        size: 16, color: Colors.red.shade400),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                document.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const Spacer(),
              if (document.progress > 0)
                LinearProgressIndicator(
                  value: document.progress,
                  borderRadius: BorderRadius.circular(2),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFull(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () => _openReader(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _fileTypeIcon,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            document.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w500),
                          ),
                        ),
                        if (document.isFavorite)
                          Icon(Icons.favorite,
                              size: 18, color: Colors.red.shade400),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (document.authors != null)
                      Text(
                        document.authors!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (document.journal != null) ...[
                          Text(
                            document.journal!,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey.shade500,
                                    ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          _formatDate(document.lastReadTime ?? document.importDate),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey.shade500,
                                  ),
                        ),
                      ],
                    ),
                    if (document.progress > 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: LinearProgressIndicator(
                              value: document.progress,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${(document.progress * 100).round()}%',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) => _handleMenuAction(context, ref, value),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'favorite',
                    child: Row(
                      children: [
                        Icon(document.isFavorite
                            ? Icons.favorite_border
                            : Icons.favorite),
                        const SizedBox(width: 8),
                        Text(document.isFavorite ? 'Unfavorite' : 'Favorite'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'recall',
                    child: Row(
                      children: [
                        Icon(Icons.quiz_outlined),
                        SizedBox(width: 8),
                        Text('Start Review'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'mastery',
                    child: Row(
                      children: [
                        Icon(Icons.trending_up),
                        SizedBox(width: 8),
                        Text('Reading Mastery'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData get _fileTypeIcon {
    switch (document.fileType) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'epub':
        return Icons.menu_book;
      case 'md':
      case 'html':
        return Icons.code;
      case 'txt':
        return Icons.text_snippet;
      default:
        return Icons.description;
    }
  }

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) return DateFormat.Hm().format(date);
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return DateFormat.E().format(date);
    return DateFormat.yMd().format(date);
  }

  void _openReader(BuildContext context) {
    context.push('/reader/${document.id}');
  }

  void _handleMenuAction(
      BuildContext context, WidgetRef ref, String action) {
    final repo = ref.read(documentRepositoryProvider);
    switch (action) {
      case 'favorite':
        repo.toggleFavorite(document.id);
        ref.invalidate(documentsProvider);
        break;
      case 'recall':
        context.push('/recall/${document.id}');
        break;
      case 'mastery':
        context.push('/mastery/${document.id}');
        break;
      case 'delete':
        _confirmDelete(context, ref);
        break;
    }
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document'),
        content: Text('Delete "${document.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(documentRepositoryProvider).deleteDocument(document.id);
              ref.invalidate(documentsProvider);
              ref.invalidate(continueReadingProvider);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
