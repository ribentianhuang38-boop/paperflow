import '../../services/storage/storage_service.dart';
import '../../models/review/review.dart';

class ReviewRepository {
  final StorageService _storageService;

  ReviewRepository(this._storageService);

  Future<List<ReviewSession>> getSessionsByDocument(int documentId) async {
    final db = await _storageService.database;
    final list = await db.query(
      'recall_sessions',
      where: 'documentId = ?',
      whereArgs: [documentId],
      orderBy: 'createdAt DESC',
    );
    return list.map((item) => ReviewSession.fromMap(item)).toList();
  }

  Future<int> createSession(int documentId) async {
    final db = await _storageService.database;
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
    final db = await _storageService.database;
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

  Future<int> insertAnswer(ReviewAnswer answer) async {
    final db = await _storageService.database;
    return db.insert('recall_answers', answer.toMap());
  }

  Future<List<ReviewAnswer>> getAnswersBySession(int sessionId) async {
    final db = await _storageService.database;
    final list = await db.query(
      'recall_answers',
      where: 'sessionId = ?',
      whereArgs: [sessionId],
      orderBy: 'paragraphIdx ASC',
    );
    return list.map((item) => ReviewAnswer.fromMap(item)).toList();
  }

  Future<void> updateAnswerFeedback(int answerId, double score, String judgment, String feedback) async {
    final db = await _storageService.database;
    await db.update(
      'recall_answers',
      {'aiScore': score, 'aiJudgment': judgment, 'aiFeedback': feedback},
      where: 'id = ?',
      whereArgs: [answerId],
    );
  }

  Future<ReviewSession?> getSessionById(int sessionId) async {
    final db = await _storageService.database;
    final list = await db.query('recall_sessions', where: 'id = ?', whereArgs: [sessionId]);
    if (list.isEmpty) return null;
    return ReviewSession.fromMap(list.first);
  }

  Future<ReviewSession?> getLatestDraftSession(int documentId) async {
    final db = await _storageService.database;
    final maps = await db.query(
      'recall_sessions',
      where: 'documentId = ? AND overallScore IS NULL',
      whereArgs: [documentId],
      orderBy: 'createdAt DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return ReviewSession.fromMap(maps.first);
  }

  Future<void> updateUserAnswer({
    required int sessionId,
    required int paragraphIdx,
    required String userAnswer,
  }) async {
    final db = await _storageService.database;
    await db.update(
      'recall_answers',
      {'userAnswer': userAnswer},
      where: 'sessionId = ? AND paragraphIdx = ?',
      whereArgs: [sessionId, paragraphIdx],
    );
  }
}
