class Vocabulary {
  final int? id;
  final String word;
  final String meaning;
  final String context;
  final int documentId;
  final int queryCount;
  final bool isStarred;

  Vocabulary({
    this.id,
    required this.word,
    required this.meaning,
    required this.context,
    required this.documentId,
    this.queryCount = 1,
    this.isStarred = false,
  });

  factory Vocabulary.fromMap(Map<String, dynamic> map) => Vocabulary(
        id: map['id'] as int?,
        word: map['word'] as String,
        meaning: map['meaning'] as String? ?? '',
        context: map['context'] as String? ?? '',
        documentId: map['documentId'] as int? ?? 0,
        queryCount: map['queryCount'] as int? ?? 1,
        isStarred: (map['isStarred'] as int?) == 1,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'word': word,
        'meaning': meaning,
        'context': context,
        'documentId': documentId,
        'queryCount': queryCount,
        'isStarred': isStarred ? 1 : 0,
      };

  Vocabulary copyWith({
    int? id,
    String? word,
    String? meaning,
    String? context,
    int? documentId,
    int? queryCount,
    bool? isStarred,
  }) {
    return Vocabulary(
      id: id ?? this.id,
      word: word ?? this.word,
      meaning: meaning ?? this.meaning,
      context: context ?? this.context,
      documentId: documentId ?? this.documentId,
      queryCount: queryCount ?? this.queryCount,
      isStarred: isStarred ?? this.isStarred,
    );
  }
}
