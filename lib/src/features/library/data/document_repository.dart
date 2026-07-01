import 'package:drift/drift.dart';
import '../../common/database/app_database.dart';
import '../../common/database/tables.dart';

class DocumentRepository {
  final AppDatabase _db;

  DocumentRepository(this._db);

  Future<List<Document>> getAllDocuments() =>
      _db.select(_db.documents).get();

  Future<List<Document>> getRecentDocuments({int limit = 10}) =>
      (_db.select(_db.documents)
            ..where((t) => t.lastReadTime.isNotNull())
            ..orderBy([(t) => OrderingTerm.desc(t.lastReadTime)])
            ..limit(limit))
          .get();

  Future<List<Document>> getContinueReading() =>
      (_db.select(_db.documents)
            ..where((t) =>
                t.progress.isBiggerThan(const Constant(0.0)) &
                t.progress.isSmallerThan(const Constant(1.0)))
            ..orderBy([(t) => OrderingTerm.desc(t.lastReadTime)]))
          .get();

  Future<List<Document>> searchDocuments(String query) =>
      (_db.select(_db.documents)
            ..where((t) =>
                t.title.like('%$query%') |
                t.authors.like('%$query%')))
          .get();

  Future<Document?> getDocumentById(int id) =>
      (_db.select(_db.documents)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  Future<void> updateProgress(int id, double progress) =>
      (_db.update(_db.documents)..where((t) => t.id.equals(id)))
          .write(DocumentsCompanion(progress: Value(progress)));

  Future<void> updateLastReadTime(int id) =>
      (_db.update(_db.documents)..where((t) => t.id.equals(id))).write(
          DocumentsCompanion(
              lastReadTime: Value(DateTime.now().millisecondsSinceEpoch)));

  Future<void> toggleFavorite(int id) async {
    final doc = await getDocumentById(id);
    if (doc != null) {
      (_db.update(_db.documents)..where((t) => t.id.equals(id))).write(
          DocumentsCompanion(isFavorite: Value(!doc.isFavorite)));
    }
  }

  Future<void> deleteDocument(int id) async {
    final doc = await getDocumentById(id);
    if (doc != null) {
      await (_db.delete(_db.documents)..where((t) => t.id.equals(id))).go();
      try {
        await _db.customStatement(
          'DELETE FROM bookmarks WHERE documentId = ?', [id],
        );
        await _db.customStatement(
          'DELETE FROM highlights WHERE documentId = ?', [id],
        );
        await _db.customStatement(
          'DELETE FROM reading_positions WHERE documentId = ?', [id],
        );
      } catch (_) {}
    }
  }

  Future<void> renameDocument(int id, String newTitle) =>
      (_db.update(_db.documents)..where((t) => t.id.equals(id)))
          .write(DocumentsCompanion(title: Value(newTitle)));
}
