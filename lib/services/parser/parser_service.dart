import 'dart:io';
import 'package:epubx/epubx.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../../models/article/article.dart';
import '../../models/article/section.dart';
import '../../models/paragraph/paragraph.dart';

class ParserService {
  Future<Article> parseFile({
    required String filePath,
    required String fileType,
    required String title,
    String? author,
    String? subtitle,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('File not found at $filePath');
    }

    List<Section> sections = [];
    String textContent = '';

    switch (fileType.toLowerCase()) {
      case 'epub':
        try {
          final bytes = await file.readAsBytes();
          final book = await EpubReader.readBook(bytes).timeout(const Duration(seconds: 5));
          final buf = StringBuffer();
          for (final ch in book.Chapters ?? []) {
            if (ch.HtmlContent != null) {
              final cleanedHtml = _cleanHtml(ch.HtmlContent!);
              buf.writeln(cleanedHtml);
              buf.writeln('\n\n');
            }
          }
          textContent = buf.toString().replaceAll(RegExp(r'\n{3,}'), '\n\n');
        } catch (e) {
          textContent = 'Failed to parse EPUB: $e';
        }
        break;

      case 'html':
        final rawHtml = await file.readAsString();
        textContent = _cleanHtml(rawHtml);
        break;

      case 'md':
      case 'markdown':
        textContent = await file.readAsString();
        break;

      case 'pdf':
        try {
          final bytes = await file.readAsBytes();
          final PdfDocument document = PdfDocument(inputBytes: bytes);
          final PdfTextExtractor extractor = PdfTextExtractor(document);
          textContent = extractor.extractText();
          document.dispose();
        } catch (e) {
          textContent = 'Failed to parse PDF text: $e';
        }
        break;

      case 'txt':
      default:
        textContent = await file.readAsString();
        break;
    }

    if (textContent.isNotEmpty) {
      sections = _buildSectionsFromText(textContent);
    }

    return Article(
      title: title,
      subtitle: subtitle,
      author: author,
      importDate: DateTime.now().millisecondsSinceEpoch,
      filePath: filePath,
      fileType: fileType,
      sections: sections,
    );
  }

  String _cleanHtml(String html) {
    return html
        .replaceAll(RegExp(r'<style[^>]*>[\s\S]*?<\/style>'), ' ')
        .replaceAll(RegExp(r'</?(p|div|h[1-6]|li|br|hr)[^>]*>'), '\n\n')
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll(RegExp(r'[ \t\r\f]+'), ' ')
        .trim()
        .replaceAll(RegExp(r'\n{3,}'), '\n\n');
  }

  List<Section> _buildSectionsFromText(String text) {
    final List<Section> sections = [];
    final rawParagraphs = text.split(RegExp(r'\n{2,}'))
        .map((p) => p.trim())
        .where((p) => p.length > 50)
        .toList();

    if (rawParagraphs.isEmpty) {
      final lines = text.split('\n')
          .map((l) => l.trim())
          .where((l) => l.length > 50)
          .toList();
      rawParagraphs.addAll(lines);
    }

    if (rawParagraphs.isEmpty && text.trim().isNotEmpty) {
      rawParagraphs.add(text.trim());
    }

    final cappedParagraphs = rawParagraphs.take(50).toList();
    final List<Paragraph> paragraphsList = cappedParagraphs.map((p) => Paragraph(text: p)).toList();
    sections.add(Section(heading: 'Content', paragraphs: paragraphsList));
    return sections;
  }
}
