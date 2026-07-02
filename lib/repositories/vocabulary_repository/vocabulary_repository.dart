import 'package:sqflite/sqflite.dart';
import '../../services/storage/storage_service.dart';
import '../../models/vocabulary/vocabulary.dart';

class VocabularyRepository {
  final StorageService _storageService;

  VocabularyRepository(this._storageService);

  Future<List<Vocabulary>> getVocabularyByDocument(int documentId) async {
    final db = await _storageService.database;
    final list = await db.query(
      'vocabulary',
      where: 'documentId = ?',
      whereArgs: [documentId],
      orderBy: 'createdAt DESC',
    );
    return list.map((item) => Vocabulary.fromMap(item)).toList();
  }

  Future<List<Vocabulary>> getAllVocabulary() async {
    final db = await _storageService.database;
    final list = await db.query('vocabulary', orderBy: 'queryCount DESC, createdAt DESC');
    return list.map((item) => Vocabulary.fromMap(item)).toList();
  }

  Future<Vocabulary?> getVocabularyByWord(String word) async {
    final db = await _storageService.database;
    final list = await db.query(
      'vocabulary',
      where: 'word = ?',
      whereArgs: [word.toLowerCase().trim()],
    );
    if (list.isEmpty) return null;
    return Vocabulary.fromMap(list.first);
  }

  Future<int> saveVocabulary(Vocabulary vocab) async {
    final db = await _storageService.database;
    final map = vocab.toMap();
    map['createdAt'] = DateTime.now().millisecondsSinceEpoch;
    map['lastQueriedAt'] = DateTime.now().millisecondsSinceEpoch;
    return db.insert('vocabulary', map, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateQueryInfo(int id) async {
    final db = await _storageService.database;
    await db.rawUpdate('''
      UPDATE vocabulary 
      SET queryCount = queryCount + 1, lastQueriedAt = ? 
      WHERE id = ?
    ''', [DateTime.now().millisecondsSinceEpoch, id]);
  }

  Future<void> deleteVocabulary(int id) async {
    final db = await _storageService.database;
    await db.delete('vocabulary', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Vocabulary>> getRecentLookups(int limit) async {
    final db = await _storageService.database;
    final list = await db.query(
      'vocabulary',
      orderBy: 'lastQueriedAt DESC',
      limit: limit,
    );
    return list.map((item) => Vocabulary.fromMap(item)).toList();
  }
}
