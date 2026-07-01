import 'package:freezed_annotation/freezed_annotation.dart';

part 'ai_review_result.freezed.dart';
part 'ai_review_result.g.dart';

@freezed
class AiReviewResult with _$AiReviewResult {
  const factory AiReviewResult({
    required int overallUnderstanding,
    required Map<String, int> sectionScores,
    required List<MisunderstoodParagraph> misunderstoodParagraphs,
    required VocabularyImpact vocabularyImpact,
    required List<String> suggestions,
  }) = _AiReviewResult;

  factory AiReviewResult.fromJson(Map<String, dynamic> json) =>
      _$AiReviewResultFromJson(json);
}

@freezed
class MisunderstoodParagraph with _$MisunderstoodParagraph {
  const factory MisunderstoodParagraph({
    required int index,
    required String reason,
  }) = _MisunderstoodParagraph;

  factory MisunderstoodParagraph.fromJson(Map<String, dynamic> json) =>
      _$MisunderstoodParagraphFromJson(json);
}

@freezed
class VocabularyImpact with _$VocabularyImpact {
  const factory VocabularyImpact({
    required int total,
    required int affected,
    required List<String> words,
  }) = _VocabularyImpact;

  factory VocabularyImpact.fromJson(Map<String, dynamic> json) =>
      _$VocabularyImpactFromJson(json);
}
