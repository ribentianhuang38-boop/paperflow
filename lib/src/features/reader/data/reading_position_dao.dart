import 'package:drift/drift.dart';
import '../../common/database/app_database.dart';
import '../../common/database/tables.dart';

part 'reading_position_dao.g.dart';

@DriftAccessor(tables: [ReadingPositions, Bookmarks, Highlights])
class ReadingPositionDao extends DatabaseAccessor<AppDatabase>
    with _$ReadingPositionDaoMixin {
  ReadingPositionDao(super.db);

  Future<ReadingPosition?> getPosition(int documentId) =>
      (select(readingPositions)
            ..where((t) => t.documentId.equals(documentId)))
          .getSingleOrNull();

  Future<void> savePosition(int documentId, String position) async {
    final existing = await getPosition(documentId);
    final now = DateTime.now().millisecondsSinceEpoch;
    if (existing != null) {
      (update(readingPositions)..where((t) => t.documentId.equals(documentId)))
          .write(ReadingPositionsCompanion(
              position: Value(position), updatedAt: Value(now)));
    } else {
      into(readingPositions).insert(ReadingPositionsCompanion(
          documentId: Value(documentId),
          position: Value(position),
          updatedAt: Value(now)));
    }
  }

  Future<List<Bookmark>> getBookmarks(int documentId) =>
      (select(bookmarks)
            ..where((t) => t.documentId.equals(documentId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  Future<int> addBookmark(BookmarksCompanion entry) =>
      into(bookmarks).insert(entry);

  Future<int> removeBookmark(int id) =>
      (delete(bookmarks)..where((t) => t.id.equals(id))).go();

  Future<List<Highlight>> getHighlights(int documentId) =>
      (select(highlights)
            ..where((t) => t.documentId.equals(documentId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  Future<int> addHighlight(HighlightsCompanion entry) =>
      into(highlights).insert(entry);

  Future<int> removeHighlight(int id) =>
      (delete(highlights)..where((t) => t.id.equals(id))).go();

  Future<void> updateHighlightNote(int id, String note) =>
      (update(highlights)..where((t) => t.id.equals(id)))
          .write(HighlightsCompanion(note: Value(note)));
}
