class Article {
  final String title;
  final String? author;
  final String? siteName;
  final String? url;
  final String? excerpt;
  final String? textContent;
  final String? htmlContent;
  final List<ArticleSection> sections;
  final DateTime? publishedAt;

  Article({
    required this.title,
    this.author,
    this.siteName,
    this.url,
    this.excerpt,
    this.textContent,
    this.htmlContent,
    this.sections = const [],
    this.publishedAt,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      title: json['title'] as String? ?? 'Untitled',
      author: json['byline'] as String?,
      siteName: json['siteName'] as String?,
      url: json['url'] as String?,
      excerpt: json['excerpt'] as String?,
      textContent: json['textContent'] as String?,
      htmlContent: json['content'] as String?,
      sections: _parseSections(json),
    );
  }

  static List<ArticleSection> _parseSections(Map<String, dynamic> json) {
    final content = json['textContent'] as String? ?? '';
    if (content.isEmpty) return [];

    final paragraphs = content.split(RegExp(r'\n{2,}'))
        .where((p) => p.trim().isNotEmpty)
        .toList();

    return paragraphs.map((p) => ArticleSection(
      type: SectionType.paragraph,
      content: p.trim(),
    )).toList();
  }
}

enum SectionType {
  heading,
  paragraph,
  image,
  figure,
  caption,
  list,
  quote,
  codeBlock,
  table,
  math,
}

class ArticleSection {
  final SectionType type;
  final String content;
  final String? imageUrl;
  final int? level; // for headings
  final List<String>? items; // for lists

  ArticleSection({
    required this.type,
    required this.content,
    this.imageUrl,
    this.level,
    this.items,
  });
}
