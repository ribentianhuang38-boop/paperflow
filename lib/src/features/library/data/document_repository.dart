import 'package:sqflite/sqflite.dart';
import '../../../common/database/app_database.dart';
import '../domain/document.dart';

class DocumentRepository {
  final AppDatabase _db;

  DocumentRepository(this._db);

  Future<List<Document>> getAllDocuments() async {
    final db = await _db.database;
    final maps = await db.query('documents', orderBy: 'lastReadTime DESC');
    return maps.map(Document.fromMap).toList();
  }

  Future<List<Document>> getRecentDocuments({int limit = 10}) async {
    final db = await _db.database;
    final maps = await db.query(
      'documents',
      where: 'lastReadTime IS NOT NULL',
      orderBy: 'lastReadTime DESC',
      limit: limit,
    );
    return maps.map(Document.fromMap).toList();
  }

  Future<List<Document>> getContinueReading() async {
    final db = await _db.database;
    final maps = await db.query(
      'documents',
      where: 'progress > 0.0 AND progress < 1.0',
      orderBy: 'lastReadTime DESC',
    );
    return maps.map(Document.fromMap).toList();
  }

  Future<List<Document>> searchDocuments(String query) async {
    final db = await _db.database;
    final maps = await db.query(
      'documents',
      where: 'title LIKE ? OR authors LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
    );
    return maps.map(Document.fromMap).toList();
  }

  Future<Document?> getDocumentById(int id) async {
    final db = await _db.database;
    final maps = await db.query('documents', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Document.fromMap(maps.first);
  }

  Future<int> insertDocument(Map<String, dynamic> data) async {
    final db = await _db.database;
    return db.insert('documents', data);
  }

  Future<void> updateProgress(int id, double progress) async {
    final db = await _db.database;
    await db.update('documents', {'progress': progress},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateLastReadTime(int id) async {
    final db = await _db.database;
    await db.update(
        'documents', {'lastReadTime': DateTime.now().millisecondsSinceEpoch},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> toggleFavorite(int id) async {
    final db = await _db.database;
    final doc = await getDocumentById(id);
    if (doc != null) {
      await db.update('documents', {'isFavorite': doc.isFavorite ? 0 : 1},
          where: 'id = ?', whereArgs: [id]);
    }
  }

  Future<void> deleteDocument(int id) async {
    final db = await _db.database;
    await db.delete('documents', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> renameDocument(int id, String newTitle) async {
    final db = await _db.database;
    await db.update('documents', {'title': newTitle},
        where: 'id = ?', whereArgs: [id]);
  }
}
