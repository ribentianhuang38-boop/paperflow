import 'package:sqflite/sqflite.dart';
import '../../../common/database/app_database.dart';

class VocabularyDao {
  final AppDatabase _db;

  VocabularyDao(this._db);

  Future<List<Map<String, dynamic>>> getAllVocabulary() async {
    final db = await _db.database;
    return db.query('vocabulary', orderBy: 'createdAt DESC');
  }

  Future<List<Map<String, dynamic>>> getVocabularyByDocument(
      int documentId) async {
    final db = await _db.database;
    return db.query('vocabulary',
        where: 'documentId = ?', whereArgs: [documentId], orderBy: 'createdAt DESC');
  }

  Future<Map<String, dynamic>?> getVocabularyByWord(String word) async {
    final db = await _db.database;
    final maps = await db.query('vocabulary',
        where: 'word = ?', whereArgs: [word.toLowerCase()]);
    if (maps.isEmpty) return null;
    return maps.first;
  }

  Future<int> addWord({
    required String word,
    String? definition,
    String? cnDefinition,
    String? pos,
    String? context,
    required int documentId,
  }) async {
    final db = await _db.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    return db.insert('vocabulary', {
      'word': word.toLowerCase(),
      'definition': definition,
      'cnDefinition': cnDefinition,
      'pos': pos,
      'context': context,
      'documentId': documentId,
      'createdAt': now,
      'lastQueriedAt': now,
    });
  }

  Future<void> updateQueryInfo(int id) async {
    final db = await _db.database;
    final maps =
        await db.query('vocabulary', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      final item = maps.first;
      await db.update(
        'vocabulary',
        {
          'lastQueriedAt': DateTime.now().millisecondsSinceEpoch,
          'queryCount': (item['queryCount'] as int) + 1,
          'contextMastered': 0,
          'globalMastered': 0,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  Future<void> markContextMastered(int id) async {
    final db = await _db.database;
    await db.update('vocabulary', {'contextMastered': 1},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> checkGlobalMastered() async {
    final db = await _db.database;
    final twoWeeksAgo =
        DateTime.now().subtract(const Duration(days: 14)).millisecondsSinceEpoch;
    await db.update(
      'vocabulary',
      {'globalMastered': 1 },
      where: 'lastQueriedAt < ? AND globalMastered = 0',
      whereArgs: [twoWeeksAgo],
    );
  }

  Future<int> getMasteredCount() async {
    final db = await _db.database;
    final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM vocabulary WHERE globalMastered = 1');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getTotalCount() async {
    final db = await _db.database;
    final result =
        await db.rawQuery('SELECT COUNT(*) as count FROM vocabulary');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> deleteVocabulary(int id) async {
    final db = await _db.database;
    return db.delete('vocabulary', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<String>> exportVocabulary() async {
    final items = await getAllVocabulary();
    return items.map((item) => item['word'] as String).toList();
  }
}
