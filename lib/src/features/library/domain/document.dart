import 'package:freezed_annotation/freezed_annotation.dart';

part 'document.freezed.dart';
part 'document.g.dart';

@freezed
class Document with _$Document {
  const factory Document({
    required int id,
    required String title,
    String? authors,
    String? journal,
    required String filePath,
    required String fileType,
    String? coverPath,
    required int importDate,
    int? lastReadTime,
    @Default(0.0) double progress,
    @Default(false) bool isFavorite,
  }) = _Document;

  factory Document.fromJson(Map<String, dynamic> json) =>
      _$DocumentFromJson(json);
}
