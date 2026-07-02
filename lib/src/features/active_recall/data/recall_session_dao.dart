import 'package:sqflite/sqflite.dart';
import '../../../common/database/app_database.dart';

class RecallSessionDao {
  final AppDatabase _db;

  RecallSessionDao(this._db);

  Future<List<Map<String, dynamic>>> getSessionsByDocument(
      int documentId) async {
    final db = await _db.database;
    return db.query('recall_sessions',
        where: 'documentId = ?', whereArgs: [documentId], orderBy: 'createdAt DESC');
  }

  Future<int> createSession(int documentId) async {
    final db = await _db.database;
    return db.insert('recall_sessions', {
      'documentId': documentId,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> updateSessionScore({
    required int sessionId,
    required double score,
    String? suggestions,
    String? vocabImpact,
  }) async {
    final db = await _db.database;
    await db.update(
      'recall_sessions',
      {
        'overallScore': score,
        if (suggestions != null) 'suggestions': suggestions,
        if (vocabImpact != null) 'vocabImpact': vocabImpact,
      },
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  Future<int> insertAnswer({
    required int sessionId,
    required int paragraphIdx,
    required String paragraphText,
    required String userAnswer,
  }) async {
    final db = await _db.database;
    return db.insert('recall_answers', {
      'sessionId': sessionId,
      'paragraphIdx': paragraphIdx,
      'paragraphText': paragraphText,
      'userAnswer': userAnswer,
    });
  }

  Future<List<Map<String, dynamic>>> getAnswersBySession(
      int sessionId) async {
    final db = await _db.database;
    return db.query('recall_answers',
        where: 'sessionId = ?', whereArgs: [sessionId], orderBy: 'paragraphIdx ASC');
  }

  Future<void> updateAnswer(
      int answerId, double score, String judgment, String feedback) async {
    final db = await _db.database;
    await db.update(
      'recall_answers',
      {'aiScore': score, 'aiJudgment': judgment, 'aiFeedback': feedback},
      where: 'id = ?',
      whereArgs: [answerId],
    );
  }

  Future<Map<String, dynamic>?> getSessionById(int sessionId) async {
    final db = await _db.database;
    final maps = await db.query('recall_sessions',
        where: 'id = ?', whereArgs: [sessionId]);
    if (maps.isEmpty) return null;
    return maps.first;
  }

  Future<Map<String, dynamic>?> getLatestDraftSession(int documentId) async {
    final db = await _db.database;
    final maps = await db.query(
      'recall_sessions',
      where: 'documentId = ? AND overallScore IS NULL',
      whereArgs: [documentId],
      orderBy: 'createdAt DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return maps.first;
  }

  Future<void> updateUserAnswer({
    required int sessionId,
    required int paragraphIdx,
    required String userAnswer,
  }) async {
    final db = await _db.database;
    await db.update(
      'recall_answers',
      {'userAnswer': userAnswer},
      where: 'sessionId = ? AND paragraphIdx = ?',
      whereArgs: [sessionId, paragraphIdx],
    );
  }
}
