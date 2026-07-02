import 'package:sqflite/sqflite.dart';
import '../../services/storage/storage_service.dart';
import '../../models/article/article.dart';
import '../../models/article/highlight.dart';
import '../../models/article/note.dart';

class ArticleRepository {
  final StorageService _storageService;

  ArticleRepository(this._storageService);

  Future<List<Article>> getArticles() async {
    final db = await _storageService.database;
    final list = await db.query('documents', orderBy: 'lastReadTime DESC, importDate DESC');
    return list.map((item) => Article.fromMap(item)).toList();
  }

  Future<Article?> getArticleById(int id) async {
    final db = await _storageService.database;
    final list = await db.query('documents', where: 'id = ?', whereArgs: [id]);
    if (list.isEmpty) return null;
    return Article.fromMap(list.first);
  }

  Future<int> saveArticle(Article article) async {
    final db = await _storageService.database;
    return db.insert('documents', article.toMap());
  }

  Future<void> updateProgress(int articleId, double progress) async {
    final db = await _storageService.database;
    await db.update(
      'documents',
      {'progress': progress},
      where: 'id = ?',
      whereArgs: [articleId],
    );
  }

  Future<void> updateFavorite(int articleId, bool isFavorite) async {
    final db = await _storageService.database;
    await db.update(
      'documents',
      {'isFavorite': isFavorite ? 1 : 0},
      where: 'id = ?',
      whereArgs: [articleId],
    );
  }

  Future<void> updateLastRead(int articleId) async {
    final db = await _storageService.database;
    await db.update(
      'documents',
      {'lastReadTime': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [articleId],
    );
  }

  Future<void> deleteArticle(int articleId) async {
    final db = await _storageService.database;
    await db.delete('documents', where: 'id = ?', whereArgs: [articleId]);
  }

  Future<void> saveReadingPosition(int articleId, String position) async {
    final db = await _storageService.database;
    await db.insert(
      'reading_positions',
      {
        'documentId': articleId,
        'position': position,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getReadingPosition(int articleId) async {
    final db = await _storageService.database;
    final list = await db.query(
      'reading_positions',
      where: 'documentId = ?',
      whereArgs: [articleId],
    );
    if (list.isEmpty) return null;
    return list.first['position'] as String?;
  }

  // --- Highlights ---
  Future<List<Highlight>> getHighlightsForArticle(int articleId) async {
    final db = await _storageService.database;
    final list = await db.query('article_highlights', where: 'articleId = ?', whereArgs: [articleId]);
    return list.map((item) => Highlight.fromMap(item)).toList();
  }

  Future<int> addHighlight(Highlight highlight) async {
    final db = await _storageService.database;
    return db.insert('article_highlights', highlight.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteHighlight(int id) async {
    final db = await _storageService.database;
    await db.delete('article_highlights', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteHighlightByPosition(int articleId, int paragraphId, int offset) async {
    final db = await _storageService.database;
    await db.delete(
      'article_highlights',
      where: 'articleId = ? AND paragraphId = ? AND offset = ?',
      whereArgs: [articleId, paragraphId, offset],
    );
  }

  // --- Notes ---
  Future<List<Note>> getNotesForArticle(int articleId) async {
    final db = await _storageService.database;
    final list = await db.query('article_notes', where: 'articleId = ?', whereArgs: [articleId]);
    return list.map((item) => Note.fromMap(item)).toList();
  }

  Future<Note?> getNoteForParagraph(int articleId, int paragraphId) async {
    final db = await _storageService.database;
    final list = await db.query(
      'article_notes',
      where: 'articleId = ? AND paragraphId = ?',
      whereArgs: [articleId, paragraphId],
    );
    if (list.isEmpty) return null;
    return Note.fromMap(list.first);
  }

  Future<int> saveNote(Note note) async {
    final db = await _storageService.database;
    return db.insert('article_notes', note.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteNote(int id) async {
    final db = await _storageService.database;
    await db.delete('article_notes', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteNoteByPosition(int articleId, int paragraphId) async {
    final db = await _storageService.database;
    await db.delete(
      'article_notes',
      where: 'articleId = ? AND paragraphId = ?',
      whereArgs: [articleId, paragraphId],
    );
  }

  // --- Statistics ---
  Future<Map<String, int>> getReadingStats() async {
    final db = await _storageService.database;
    final papersCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM documents')) ?? 0;
    
    int totalWords = 0;
    final wordsResult = await db.rawQuery('SELECT content FROM documents');
    for (final row in wordsResult) {
      final content = row['content'] as String?;
      if (content != null && content.isNotEmpty) {
        totalWords += content.split(RegExp(r'\s+')).length;
      }
    }
    
    final highlightsCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM article_highlights')) ?? 0;
    final notesCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM article_notes')) ?? 0;
    final vocabCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM vocabulary')) ?? 0;
    
    return {
      'papers': papersCount,
      'words': totalWords,
      'highlights': highlightsCount,
      'notes': notesCount,
      'vocab': vocabCount,
    };
  }
}
