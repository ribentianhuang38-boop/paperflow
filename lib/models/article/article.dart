import 'dart:convert';
import 'section.dart';

class Article {
  final int? id;
  final String title;
  final String? subtitle;
  final String? author;
  final int importDate;
  final String? coverImage;
  final String filePath;
  final String fileType;
  final double progress;
  final bool isFavorite;
  final int? lastReadTime;
  final Map<String, dynamic> metadata;
  final List<Section> sections;
  final List<String> references;
  final String? source;

  Article({
    this.id,
    required this.title,
    this.subtitle,
    this.author,
    required this.importDate,
    this.coverImage,
    required this.filePath,
    required this.fileType,
    this.progress = 0.0,
    this.isFavorite = false,
    this.lastReadTime,
    this.metadata = const {},
    this.sections = const [],
    this.references = const [],
    this.source,
  });

  factory Article.fromMap(Map<String, dynamic> map) {
    List<Section> parsedSections = [];
    List<String> parsedReferences = [];
    Map<String, dynamic> parsedMetadata = {};
    if (map['content'] != null && (map['content'] as String).isNotEmpty) {
      try {
        final contentMap = jsonDecode(map['content'] as String) as Map<String, dynamic>;
        parsedSections = (contentMap['sections'] as List? ?? [])
            .map((s) => Section.fromJson(s as Map<String, dynamic>))
            .toList();
        parsedReferences = List<String>.from(contentMap['references'] as List? ?? []);
        parsedMetadata = Map<String, dynamic>.from(contentMap['metadata'] as Map? ?? {});
      } catch (_) {}
    }

    return Article(
      id: map['id'] as int?,
      title: map['title'] as String,
      subtitle: map['journal'] as String?,
      author: map['authors'] as String?,
      importDate: map['importDate'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      coverImage: map['coverPath'] as String?,
      filePath: map['filePath'] as String? ?? '',
      fileType: map['fileType'] as String? ?? 'txt',
      progress: (map['progress'] as num?)?.toDouble() ?? 0.0,
      isFavorite: (map['isFavorite'] as int?) == 1,
      lastReadTime: map['lastReadTime'] as int?,
      metadata: parsedMetadata,
      sections: parsedSections,
      references: parsedReferences,
      source: map['source'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    final contentMap = {
      'sections': sections.map((s) => s.toJson()).toList(),
      'references': references,
      'metadata': metadata,
    };
    return {
      if (id != null) 'id': id,
      'title': title,
      'journal': subtitle,
      'authors': author,
      'importDate': importDate,
      'coverPath': coverImage,
      'filePath': filePath,
      'fileType': fileType,
      'progress': progress,
      'isFavorite': isFavorite ? 1 : 0,
      'lastReadTime': lastReadTime,
      'source': source,
      'content': jsonEncode(contentMap),
    };
  }

  Article copyWith({
    int? id,
    String? title,
    String? subtitle,
    String? author,
    int? importDate,
    String? coverImage,
    String? filePath,
    String? fileType,
    double? progress,
    bool? isFavorite,
    int? lastReadTime,
    Map<String, dynamic>? metadata,
    List<Section>? sections,
    List<String>? references,
    String? source,
  }) {
    return Article(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      author: author ?? this.author,
      importDate: importDate ?? this.importDate,
      coverImage: coverImage ?? this.coverImage,
      filePath: filePath ?? this.filePath,
      fileType: fileType ?? this.fileType,
      progress: progress ?? this.progress,
      isFavorite: isFavorite ?? this.isFavorite,
      lastReadTime: lastReadTime ?? this.lastReadTime,
      metadata: metadata ?? this.metadata,
      sections: sections ?? this.sections,
      references: references ?? this.references,
      source: source ?? this.source,
    );
  }
}
