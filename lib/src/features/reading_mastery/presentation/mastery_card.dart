import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/database/app_database.dart';
import '../data/mastery_dao.dart';
import '../../library/presentation/library_screen.dart';

final masteryDaoProvider = Provider<MasteryDao>((ref) {
  return MasteryDao(ref.watch(databaseProvider));
});

class MasteryCard extends ConsumerWidget {
  final int documentId;

  const MasteryCard({super.key, required this.documentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latestAsync = ref.watch(latestMasteryProvider(documentId));

    return latestAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (latest) {
        if (latest == null) return const SizedBox.shrink();

        final score = latest.score;
        final color = score >= 80
            ? Colors.green
            : score >= 60
                ? Colors.orange
                : Colors.red;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 6,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reading Mastery',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                    ),
                    Text(
                      '${score.round()}%',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

final latestMasteryProvider =
    FutureProvider.family<MasteryScore?, int>((ref, documentId) async {
  final dao = ref.watch(masteryDaoProvider);
  return dao.getLatestScore(documentId);
});
