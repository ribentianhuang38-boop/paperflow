import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../models/article/article.dart';
import '../parser/parser_service.dart';
import '../../repositories/article_repository/article_repository.dart';

class ImporterService {
  final ParserService _parserService;
  final ArticleRepository _articleRepository;

  ImporterService({
    required ParserService parserService,
    required ArticleRepository articleRepository,
  })  : _parserService = parserService,
        _articleRepository = articleRepository;

  Future<Article> importLocalFile({
    required String sourcePath,
    required String title,
    String? author,
    String? subtitle,
  }) async {
    final file = File(sourcePath);
    if (!await file.exists()) {
      throw Exception('Source file does not exist at $sourcePath');
    }

    final ext = p.extension(sourcePath).replaceAll('.', '').toLowerCase();
    
    final appDir = await getApplicationDocumentsDirectory();
    final localDocDir = Directory('${appDir.path}/documents');
    if (!await localDocDir.exists()) {
      await localDocDir.create(recursive: true);
    }
    
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${p.basename(sourcePath)}';
    final targetPath = '${localDocDir.path}/$fileName';
    await file.copy(targetPath);

    final article = await _parserService.parseFile(
      filePath: targetPath,
      fileType: ext,
      title: title,
      author: author,
      subtitle: subtitle,
    );

    final savedId = await _articleRepository.saveArticle(article);
    return article.copyWith(id: savedId);
  }

  Future<Article> importCapturedWeb({
    required String title,
    required String content,
    required String url,
    String? author,
  }) async {
    final appDir = await getApplicationDocumentsDirectory();
    final localDocDir = Directory('${appDir.path}/documents');
    if (!await localDocDir.exists()) {
      await localDocDir.create(recursive: true);
    }
    
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_captured.html';
    final targetPath = '${localDocDir.path}/$fileName';
    
    final htmlContent = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>$title</title>
</head>
<body>
  <h1>$title</h1>
  $content
</body>
</html>
''';
    
    await File(targetPath).writeAsString(htmlContent);

    final article = await _parserService.parseFile(
      filePath: targetPath,
      fileType: 'html',
      title: title,
      author: author,
      subtitle: url,
    );

    final savedId = await _articleRepository.saveArticle(article.copyWith(source: url));
    return article.copyWith(id: savedId, source: url);
  }
}
