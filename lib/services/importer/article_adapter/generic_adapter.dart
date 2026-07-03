import '../../../../models/article/article.dart';
import '../../../../models/article/section.dart';
import '../../../../models/paragraph/paragraph.dart';

abstract class BaseArticleAdapter {
  Article adapt(Map<String, dynamic> rawJson, String url);
}

class GenericAdapter implements BaseArticleAdapter {
  @override
  Article adapt(Map<String, dynamic> json, String url) {
    final title = json['title'] as String? ?? 'Untitled Web Capture';
    final author = json['byline'] as String? ?? json['siteName'] as String?;
    final textContent = json['textContent'] as String? ?? '';

    List<Section> sections = [];
    if (json.containsKey('paragraphs') && json['paragraphs'] is List) {
      final list = json['paragraphs'] as List;
      final List<Paragraph> plist = [];
      for (final item in list) {
        if (item is Map) {
          final text = item['text'] as String? ?? '';
          if (text.trim().isNotEmpty) {
            plist.add(Paragraph(text: text.trim()));
          }
        }
      }
      if (plist.isNotEmpty) {
        sections.add(Section(heading: 'Content', paragraphs: plist));
      }
    }

    if (sections.isEmpty && textContent.isNotEmpty) {
      final rawParagraphs = textContent
          .split(RegExp(r'\n{2,}'))
          .map((p) => p.trim())
          .where((p) => p.length > 50)
          .toList();

      if (rawParagraphs.isEmpty) {
        final lines = textContent
            .split('\n')
            .map((l) => l.trim())
            .where((l) => l.length > 50)
            .toList();
        rawParagraphs.addAll(lines);
      }

      if (rawParagraphs.isEmpty && textContent.trim().isNotEmpty) {
        rawParagraphs.add(textContent.trim());
      }

      final cappedParagraphs = rawParagraphs.take(50).toList();
      final paragraphs = cappedParagraphs.map((p) => Paragraph(text: p)).toList();
      sections.add(Section(heading: 'Content', paragraphs: paragraphs));
    }

    return Article(
      title: title,
      author: author,
      subtitle: json['siteName'] as String?,
      importDate: DateTime.now().millisecondsSinceEpoch,
      filePath: '',
      fileType: 'html',
      sections: sections,
      source: url,
    );
  }
}
