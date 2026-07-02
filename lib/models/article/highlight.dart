class Highlight {
  final int? id;
  final int articleId;
  final int paragraphId;
  final int offset;
  final int length;
  final String color;
  final int createdAt;

  Highlight({
    this.id,
    required this.articleId,
    required this.paragraphId,
    required this.offset,
    required this.length,
    required this.color,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'articleId': articleId,
      'paragraphId': paragraphId,
      'offset': offset,
      'length': length,
      'color': color,
      'createdAt': createdAt,
    };
  }

  factory Highlight.fromMap(Map<String, dynamic> map) {
    return Highlight(
      id: map['id'] as int?,
      articleId: map['articleId'] as int,
      paragraphId: map['paragraphId'] as int,
      offset: map['offset'] as int,
      length: map['length'] as int,
      color: map['color'] as String,
      createdAt: map['createdAt'] as int,
    );
  }
}
