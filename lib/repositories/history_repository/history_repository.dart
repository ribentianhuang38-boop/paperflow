import '../../services/storage/storage_service.dart';
import '../../models/reading_history/reading_history.dart';

class HistoryRepository {
  final StorageService _storageService;

  HistoryRepository(this._storageService);

  Future<List<ReadingHistory>> getScoresByDocument(int documentId) async {
    final db = await _storageService.database;
    final list = await db.query(
      'mastery_scores',
      where: 'documentId = ?',
      whereArgs: [documentId],
      orderBy: 'createdAt ASC',
    );
    return list.map((item) => ReadingHistory.fromMap(item)).toList();
  }

  Future<List<ReadingHistory>> getAllScores() async {
    final db = await _storageService.database;
    final list = await db.query(
      'mastery_scores',
      orderBy: 'createdAt DESC',
    );
    return list.map((item) => ReadingHistory.fromMap(item)).toList();
  }

  Future<int> insertScore(int documentId, double score) async {
    final db = await _storageService.database;
    return db.insert('mastery_scores', {
      'documentId': documentId,
      'score': score,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<List<ReadingHistory>> getRecentHistory(int days) async {
    final db = await _storageService.database;
    final cutoff = DateTime.now().subtract(Duration(days: days)).millisecondsSinceEpoch;
    final list = await db.query(
      'mastery_scores',
      where: 'createdAt >= ?',
      whereArgs: [cutoff],
      orderBy: 'createdAt ASC',
    );
    return list.map((item) => ReadingHistory.fromMap(item)).toList();
  }
}
