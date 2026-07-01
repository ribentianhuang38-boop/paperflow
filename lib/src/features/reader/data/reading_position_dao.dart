import 'package:sqflite/sqflite.dart';
import '../../../common/database/app_database.dart';

class ReadingPositionDao {
  final AppDatabase _db;

  ReadingPositionDao(this._db);

  Future<Map<String, dynamic>?> getPosition(int documentId) async {
    final db = await _db.database;
    final maps = await db.query('reading_positions',
        where: 'documentId = ?', whereArgs: [documentId]);
    if (maps.isEmpty) return null;
    return maps.first;
  }

  Future<void> savePosition(int documentId, String position) async {
    final db = await _db.database;
    final existing = await getPosition(documentId);
    final now = DateTime.now().millisecondsSinceEpoch;
    if (existing != null) {
      await db.update(
          'reading_positions', {'position': position, 'updatedAt': now},
          where: 'documentId = ?', whereArgs: [documentId]);
    } else {
      await db.insert('reading_positions',
          {'documentId': documentId, 'position': position, 'updatedAt': now});
    }
  }

  Future<List<Map<String, dynamic>>> getBookmarks(int documentId) async {
    final db = await _db.database;
    return db.query('bookmarks',
        where: 'documentId = ?', whereArgs: [documentId], orderBy: 'createdAt DESC');
  }

  Future<int> addBookmark(int documentId, String position, String? title) async {
    final db = await _db.database;
    return db.insert('bookmarks', {
      'documentId': documentId,
      'position': position,
      'title': title,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<int> removeBookmark(int id) async {
    final db = await _db.database;
    return db.delete('bookmarks', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getHighlights(int documentId) async {
    final db = await _db.database;
    return db.query('highlights',
        where: 'documentId = ?', whereArgs: [documentId], orderBy: 'createdAt DESC');
  }

  Future<int> addHighlight(
      int documentId, String startPos, String endPos, int color) async {
    final db = await _db.database;
    return db.insert('highlights', {
      'documentId': documentId,
      'startPos': startPos,
      'endPos': endPos,
      'color': color,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<int> removeHighlight(int id) async {
    final db = await _db.database;
    return db.delete('highlights', where: 'id = ?', whereArgs: [id]);
  }
}
