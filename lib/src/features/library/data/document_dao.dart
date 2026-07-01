import 'package:drift/drift.dart';
import 'app_database.dart';
import 'tables.dart';

part 'document_dao.g.dart';

@DriftAccessor(tables: [Documents])
class DocumentDao extends DatabaseAccessor<AppDatabase>
    with _$DocumentDaoMixin {
  DocumentDao(super.db);

  Future<List<Document>> getAllDocuments() =>
      (select(documents)..orderBy([(t) => OrderingTerm.desc(t.lastReadTime)]))
          .get();

  Future<List<Document>> getRecentDocuments({int limit = 10}) =>
      (select(documents)
            ..where((t) => t.lastReadTime.isNotNull())
            ..orderBy([(t) => OrderingTerm.desc(t.lastReadTime)])
            ..limit(limit))
          .get();

  Future<List<Document>> getContinueReading() =>
      (select(documents)
            ..where((t) =>
                t.progress.isBiggerThan(const Constant(0.0)) &
                t.progress.isSmallerThan(const Constant(1.0)))
            ..orderBy([(t) => OrderingTerm.desc(t.lastReadTime)]))
          .get();

  Future<List<Document>> searchDocuments(String query) =>
      (select(documents)
            ..where((t) =>
                t.title.like('%$query%') |
                t.authors.like('%$query%')))
          .get();

  Future<Document?> getDocumentById(int id) =>
      (select(documents)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> insertDocument(DocumentsCompanion entry) =>
      into(documents).insert(entry);

  Future<bool> updateDocument(DocumentsCompanion entry) =>
      update(documents).replace(entry);

  Future<int> deleteDocument(int id) =>
      (delete(documents)..where((t) => t.id.equals(id))).go();

  Future<void> updateProgress(int id, double progress) =>
      (update(documents)..where((t) => t.id.equals(id)))
          .write(DocumentsCompanion(progress: Value(progress)));

  Future<void> updateLastReadTime(int id) =>
      (update(documents)..where((t) => t.id.equals(id))).write(
          DocumentsCompanion(
              lastReadTime: Value(DateTime.now().millisecondsSinceEpoch)));

  Future<void> toggleFavorite(int id) async {
    final doc = await getDocumentById(id);
    if (doc != null) {
      (update(documents)..where((t) => t.id.equals(id))).write(
          DocumentsCompanion(isFavorite: Value(!doc.isFavorite)));
    }
  }
}
