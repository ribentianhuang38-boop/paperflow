import 'package:drift/drift.dart';

class Documents extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get authors => text().nullable()();
  TextColumn get journal => text().nullable()();
  TextColumn get filePath => text()();
  TextColumn get fileType => text()();
  TextColumn get coverPath => text().nullable()();
  IntColumn get importDate => integer()();
  IntColumn get lastReadTime => integer().nullable()();
  RealColumn get progress => real().withDefault(const Constant(0.0))();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
}

class Bookmarks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get documentId => integer().references(Documents, #id)();
  TextColumn get position => text()();
  TextColumn get title => text().nullable()();
  IntColumn get createdAt => integer()();
}

class Highlights extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get documentId => integer().references(Documents, #id)();
  TextColumn get startPos => text()();
  TextColumn get endPos => text()();
  IntColumn get color => integer().withDefault(const Constant(0xFFFFEB3B))();
  TextColumn get note => text().nullable()();
  IntColumn get createdAt => integer()();
}

class ReadingPositions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get documentId => integer().unique().references(Documents, #id)();
  TextColumn get position => text()();
  IntColumn get updatedAt => integer()();
}

class Vocabulary extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get word => text()();
  TextColumn get definition => text().nullable()();
  TextColumn get cnDefinition => text().nullable()();
  TextColumn get pos => text().nullable()();
  TextColumn get context => text().nullable()();
  IntColumn get documentId => integer().references(Documents, #id)();
  IntColumn get createdAt => integer()();
  IntColumn get lastQueriedAt => integer()();
  IntColumn get queryCount => integer().withDefault(const Constant(1))();
  BoolColumn get contextMastered => boolean().withDefault(const Constant(false))();
  BoolColumn get globalMastered => boolean().withDefault(const Constant(false))();
}

class RecallSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get documentId => integer().references(Documents, #id)();
  IntColumn get createdAt => integer()();
  RealColumn get overallScore => real().nullable()();
}

class RecallAnswers extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sessionId => integer().references(RecallSessions, #id)();
  IntColumn get paragraphIdx => integer()();
  TextColumn get paragraphText => text()();
  TextColumn get userAnswer => text()();
  RealColumn get aiScore => real().nullable()();
  TextColumn get aiJudgment => text().nullable()();
  TextColumn get aiFeedback => text().nullable()();
}

class MasteryScores extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get documentId => integer().references(Documents, #id)();
  RealColumn get score => real()();
  IntColumn get createdAt => integer()();
}
