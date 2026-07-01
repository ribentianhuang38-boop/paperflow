class Document {
  final int id;
  final String title;
  final String? authors;
  final String? journal;
  final String filePath;
  final String fileType;
  final String? coverPath;
  final int importDate;
  final int? lastReadTime;
  final double progress;
  final bool isFavorite;

  Document({
    required this.id,
    required this.title,
    this.authors,
    this.journal,
    required this.filePath,
    required this.fileType,
    this.coverPath,
    required this.importDate,
    this.lastReadTime,
    this.progress = 0.0,
    this.isFavorite = false,
  });

  factory Document.fromMap(Map<String, dynamic> map) => Document(
        id: map['id'] as int,
        title: map['title'] as String,
        authors: map['authors'] as String?,
        journal: map['journal'] as String?,
        filePath: map['filePath'] as String,
        fileType: map['fileType'] as String,
        coverPath: map['coverPath'] as String?,
        importDate: map['importDate'] as int,
        lastReadTime: map['lastReadTime'] as int?,
        progress: (map['progress'] as num?)?.toDouble() ?? 0.0,
        isFavorite: (map['isFavorite'] as int?) == 1,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'authors': authors,
        'journal': journal,
        'filePath': filePath,
        'fileType': fileType,
        'coverPath': coverPath,
        'importDate': importDate,
        'lastReadTime': lastReadTime,
        'progress': progress,
        'isFavorite': isFavorite ? 1 : 0,
      };
}
