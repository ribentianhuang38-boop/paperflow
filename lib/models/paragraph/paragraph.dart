class Paragraph {
  final String text;
  final List<String> images;
  final List<String> tables;
  final List<String> quotes;
  final List<String> equations;

  Paragraph({
    required this.text,
    this.images = const [],
    this.tables = const [],
    this.quotes = const [],
    this.equations = const [],
  });

  Map<String, dynamic> toJson() => {
        'text': text,
        'images': images,
        'tables': tables,
        'quotes': quotes,
        'equations': equations,
      };

  factory Paragraph.fromJson(Map<String, dynamic> json) => Paragraph(
        text: json['text'] as String? ?? '',
        images: List<String>.from(json['images'] as List? ?? []),
        tables: List<String>.from(json['tables'] as List? ?? []),
        quotes: List<String>.from(json['quotes'] as List? ?? []),
        equations: List<String>.from(json['equations'] as List? ?? []),
      );
}
