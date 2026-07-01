import 'package:sqflite/sqflite.dart';
import '../../../common/database/app_database.dart';

class MasteryDao {
  final AppDatabase _db;

  MasteryDao(this._db);

  Future<List<Map<String, dynamic>>> getScoresByDocument(
      int documentId) async {
    final db = await _db.database;
    return db.query('mastery_scores',
        where: 'documentId = ?', whereArgs: [documentId], orderBy: 'createdAt DESC');
  }

  Future<Map<String, dynamic>?> getLatestScore(int documentId) async {
    final db = await _db.database;
    final maps = await db.query('mastery_scores',
        where: 'documentId = ?', whereArgs: [documentId],
        orderBy: 'createdAt DESC', limit: 1);
    if (maps.isEmpty) return null;
    return maps.first;
  }

  Future<int> insertScore(int documentId, double score) async {
    final db = await _db.database;
    return db.insert('mastery_scores', {
      'documentId': documentId,
      'score': score,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<List<Map<String, dynamic>>> getAllRecentScores(int days) async {
    final db = await _db.database;
    final startTimestamp =
        DateTime.now().subtract(Duration(days: days)).millisecondsSinceEpoch;
    return db.query('mastery_scores',
        where: 'createdAt > ?', whereArgs: [startTimestamp],
        orderBy: 'createdAt ASC');
  }
}
