import 'package:freezed_annotation/freezed_annotation.dart';

part 'recall_answer.freezed.dart';
part 'recall_answer.g.dart';

@freezed
class RecallAnswer with _$RecallAnswer {
  const factory RecallAnswer({
    required int id,
    required int sessionId,
    required int paragraphIdx,
    required String paragraphText,
    required String userAnswer,
    double? aiScore,
    String? aiJudgment,
    String? aiFeedback,
  }) = _RecallAnswer;

  factory RecallAnswer.fromJson(Map<String, dynamic> json) =>
      _$RecallAnswerFromJson(json);
}
