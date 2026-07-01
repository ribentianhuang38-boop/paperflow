import 'package:freezed_annotation/freezed_annotation.dart';

part 'vocabulary_item.freezed.dart';
part 'vocabulary_item.g.dart';

@freezed
class VocabularyItem with _$VocabularyItem {
  const factory VocabularyItem({
    required int id,
    required String word,
    String? definition,
    String? cnDefinition,
    String? pos,
    String? context,
    required int documentId,
    required int createdAt,
    required int lastQueriedAt,
    @Default(1) int queryCount,
    @Default(false) bool contextMastered,
    @Default(false) bool globalMastered,
  }) = _VocabularyItem;

  factory VocabularyItem.fromJson(Map<String, dynamic> json) =>
      _$VocabularyItemFromJson(json);
}
