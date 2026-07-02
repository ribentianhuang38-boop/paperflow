class Note {
  final int? id;
  final int articleId;
  final int paragraphId;
  final String content;
  final int createdAt;
  final int updatedAt;

  Note({
    this.id,
    required this.articleId,
    required this.paragraphId,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'articleId': articleId,
      'paragraphId': paragraphId,
      'content': content,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] as int?,
      articleId: map['articleId'] as int,
      paragraphId: map['paragraphId'] as int,
      content: map['content'] as String,
      createdAt: map['createdAt'] as int,
      updatedAt: map['updatedAt'] as int,
    );
  }
}
