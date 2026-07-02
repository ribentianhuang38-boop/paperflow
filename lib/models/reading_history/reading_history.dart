class ReadingHistory {
  final int? id;
  final int documentId;
  final double score;
  final int createdAt;

  ReadingHistory({
    this.id,
    required this.documentId,
    required this.score,
    required this.createdAt,
  });

  factory ReadingHistory.fromMap(Map<String, dynamic> map) => ReadingHistory(
        id: map['id'] as int?,
        documentId: map['documentId'] as int,
        score: (map['score'] as num?)?.toDouble() ?? 0.0,
        createdAt: map['createdAt'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'documentId': documentId,
        'score': score,
        'createdAt': createdAt,
      };
}
