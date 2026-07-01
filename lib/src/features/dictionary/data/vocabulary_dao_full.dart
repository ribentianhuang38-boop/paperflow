import 'package:drift/drift.dart';
import '../../../common/database/app_database.dart';
import '../../../common/database/tables.dart';

part 'vocabulary_dao.g.dart';

@DriftAccessor(tables: [Vocabulary])
class VocabularyDao extends DatabaseAccessor<AppDatabase>
    with _$VocabularyDaoMixin {
  VocabularyDao(super.db);

  Future<List<VocabularyData>> getAllVocabulary() =>
      (select(vocabulary)..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  Future<List<VocabularyData>> getVocabularyByDocument(int documentId) =>
      (select(vocabulary)
            ..where((t) => t.documentId.equals(documentId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  Future<VocabularyData?> getVocabularyByWord(String word) =>
      (select(vocabulary)..where((t) => t.word.equals(word.toLowerCase())))
          .getSingleOrNull();

  Future<int> addWord({
    required String word,
    String? definition,
    String? cnDefinition,
    String? pos,
    String? context,
    required int documentId,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    return into(vocabulary).insert(VocabularyCompanion(
      word: Value(word.toLowerCase()),
      definition: Value(definition),
      cnDefinition: Value(cnDefinition),
      pos: Value(pos),
      context: Value(context),
      documentId: Value(documentId),
      createdAt: Value(now),
      lastQueriedAt: Value(now),
    ));
  }

  Future<void> updateQueryInfo(int id) async {
    final item = await (select(vocabulary)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (item != null) {
      (update(vocabulary)..where((t) => t.id.equals(id))).write(
          VocabularyCompanion(
            lastQueriedAt: Value(DateTime.now().millisecondsSinceEpoch),
            queryCount: Value(item.queryCount + 1),
            contextMastered: const Value(false),
            globalMastered: const Value(false),
          ));
    }
  }

  Future<void> markContextMastered(int id) =>
      (update(vocabulary)..where((t) => t.id.equals(id)))
          .write(const VocabularyCompanion(contextMastered: Value(true)));

  Future<void> checkGlobalMastered() async {
    final twoWeeksAgo = DateTime.now()
        .subtract(const Duration(days: 14))
        .millisecondsSinceEpoch;
    await (update(vocabulary)
          ..where((t) =>
              t.lastQueriedAt.isSmallerThanValue(twoWeeksAgo) &
              t.globalMastered.equals(false)))
        .write(const VocabularyCompanion(globalMastered: Value(true)));
  }

  Future<int> getMasteredCount() async {
    final results =
        await (select(vocabulary)..where((t) => t.globalMastered.equals(true)))
            .get();
    return results.length;
  }

  Future<int> getTotalCount() async {
    final results = await select(vocabulary).get();
    return results.length;
  }

  Future<int> deleteVocabulary(int id) =>
      (delete(vocabulary)..where((t) => t.id.equals(id))).go();

  Future<List<String>> exportVocabulary() async {
    final items = await getAllVocabulary();
    return items.map((item) => item.word).toList();
  }
}
