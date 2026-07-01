import 'package:drift/drift.dart';
import '../../common/database/app_database.dart';
import '../../common/database/tables.dart';

part 'mastery_dao.g.dart';

@DriftAccessor(tables: [MasteryScores])
class MasteryDao extends DatabaseAccessor<AppDatabase>
    with _$MasteryDaoMixin {
  MasteryDao(super.db);

  Future<List<MasteryScore>> getScoresByDocument(int documentId) =>
      (select(masteryScores)
            ..where((t) => t.documentId.equals(documentId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  Future<MasteryScore?> getLatestScore(int documentId) =>
      (select(masteryScores)
            ..where((t) => t.documentId.equals(documentId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
            ..limit(1))
          .getSingleOrNull();

  Future<int> insertScore(MasteryScoresCompanion entry) =>
      into(masteryScores).insert(entry);

  Future<List<MasteryScore>> getScoresInRange(
      int documentId, int startTimestamp) =>
      (select(masteryScores)
            ..where((t) =>
                t.documentId.equals(documentId) &
                t.createdAt.isBiggerThanValue(startTimestamp))
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .get();

  Future<List<MasteryScore>> getAllRecentScores(int days) {
    final startTimestamp = DateTime.now()
        .subtract(Duration(days: days))
        .millisecondsSinceEpoch;
    return (select(masteryScores)
          ..where((t) => t.createdAt.isBiggerThanValue(startTimestamp))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }
}
