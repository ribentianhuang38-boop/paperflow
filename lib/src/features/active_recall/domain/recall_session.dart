import 'package:freezed_annotation/freezed_annotation.dart';

part 'recall_session.freezed.dart';
part 'recall_session.g.dart';

@freezed
class RecallSession with _$RecallSession {
  const factory RecallSession({
    required int id,
    required int documentId,
    required int createdAt,
    double? overallScore,
  }) = _RecallSession;

  factory RecallSession.fromJson(Map<String, dynamic> json) =>
      _$RecallSessionFromJson(json);
}
