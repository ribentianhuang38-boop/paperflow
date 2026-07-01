import 'package:drift/drift.dart';
import '../../common/database/app_database.dart';
import '../../common/database/tables.dart';

part 'recall_session_dao.g.dart';

@DriftAccessor(tables: [RecallSessions, RecallAnswers])
class RecallSessionDao extends DatabaseAccessor<AppDatabase>
    with _$RecallSessionDaoMixin {
  RecallSessionDao(super.db);

  Future<List<RecallSession>> getSessionsByDocument(int documentId) =>
      (select(recallSessions)
            ..where((t) => t.documentId.equals(documentId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  Future<RecallSession?> getLatestSession(int documentId) =>
      (select(recallSessions)
            ..where((t) => t.documentId.equals(documentId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
            ..limit(1))
          .getSingleOrNull();

  Future<int> createSession(RecallSessionsCompanion entry) =>
      into(recallSessions).insert(entry);

  Future<void> updateSessionScore(int sessionId, double score) =>
      (update(recallSessions)..where((t) => t.id.equals(sessionId)))
          .write(RecallSessionsCompanion(overallScore: Value(score)));

  Future<int> insertAnswer(RecallAnswersCompanion entry) =>
      into(recallAnswers).insert(entry);

  Future<List<RecallAnswer>> getAnswersBySession(int sessionId) =>
      (select(recallAnswers)
            ..where((t) => t.sessionId.equals(sessionId))
            ..orderBy([(t) => OrderingTerm.asc(t.paragraphIdx)]))
          .get();

  Future<void> updateAnswer(
          int answerId, double score, String judgment, String feedback) =>
      (update(recallAnswers)..where((t) => t.id.equals(answerId))).write(
          RecallAnswersCompanion(
            aiScore: Value(score),
            aiJudgment: Value(judgment),
            aiFeedback: Value(feedback),
          ));
}
