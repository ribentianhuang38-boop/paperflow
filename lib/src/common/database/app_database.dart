import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class AppDatabase {
  static AppDatabase? _instance;
  static Database? _database;

  AppDatabase._();

  static Future<AppDatabase> getInstance() async {
    _instance ??= AppDatabase._();
    return _instance!;
  }

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, 'paperflow.sqlite');
    return openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          try {
            await db.execute('ALTER TABLE recall_sessions ADD COLUMN suggestions TEXT');
            await db.execute('ALTER TABLE recall_sessions ADD COLUMN vocabImpact TEXT');
          } catch (e) {
            // Column might already exist
          }
        }
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE documents (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        authors TEXT,
        journal TEXT,
        filePath TEXT NOT NULL,
        fileType TEXT NOT NULL,
        coverPath TEXT,
        importDate INTEGER NOT NULL,
        lastReadTime INTEGER,
        progress REAL DEFAULT 0.0,
        isFavorite INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE bookmarks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        documentId INTEGER NOT NULL,
        position TEXT NOT NULL,
        title TEXT,
        createdAt INTEGER NOT NULL,
        FOREIGN KEY (documentId) REFERENCES documents(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE highlights (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        documentId INTEGER NOT NULL,
        startPos TEXT NOT NULL,
        endPos TEXT NOT NULL,
        color INTEGER DEFAULT 16776963,
        note TEXT,
        createdAt INTEGER NOT NULL,
        FOREIGN KEY (documentId) REFERENCES documents(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE reading_positions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        documentId INTEGER UNIQUE NOT NULL,
        position TEXT NOT NULL,
        updatedAt INTEGER NOT NULL,
        FOREIGN KEY (documentId) REFERENCES documents(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE vocabulary (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        word TEXT NOT NULL,
        definition TEXT,
        cnDefinition TEXT,
        pos TEXT,
        context TEXT,
        documentId INTEGER NOT NULL,
        createdAt INTEGER NOT NULL,
        lastQueriedAt INTEGER NOT NULL,
        queryCount INTEGER DEFAULT 1,
        contextMastered INTEGER DEFAULT 0,
        globalMastered INTEGER DEFAULT 0,
        FOREIGN KEY (documentId) REFERENCES documents(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE recall_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        documentId INTEGER NOT NULL,
        createdAt INTEGER NOT NULL,
        overallScore REAL,
        suggestions TEXT,
        vocabImpact TEXT,
        FOREIGN KEY (documentId) REFERENCES documents(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE recall_answers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sessionId INTEGER NOT NULL,
        paragraphIdx INTEGER NOT NULL,
        paragraphText TEXT NOT NULL,
        userAnswer TEXT NOT NULL,
        aiScore REAL,
        aiJudgment TEXT,
        aiFeedback TEXT,
        FOREIGN KEY (sessionId) REFERENCES recall_sessions(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE mastery_scores (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        documentId INTEGER NOT NULL,
        score REAL NOT NULL,
        createdAt INTEGER NOT NULL,
        FOREIGN KEY (documentId) REFERENCES documents(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
