import 'package:flutter/services.dart' show rootBundle;

class BrowserService {
  static const String mobileChromeUserAgent =
      'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36';

  String? _readabilityCode;

  Future<String> get readabilityCode async {
    _readabilityCode ??= await rootBundle.loadString('assets/readability.js');
    return _readabilityCode!;
  }

  Future<String> getInjectScript() async {
    final code = await readabilityCode;
    final escaped = code
        .replaceAll('\\', '\\\\')
        .replaceAll('`', '\\`')
        .replaceAll('\$', '\\\$');
    return '''
(function() {
  if (typeof Readability !== 'undefined') return;
  var script = document.createElement('script');
  script.textContent = `$escaped`;
  document.head.appendChild(script);
})();
''';
  }

  String getExtractScript() {
    return '''
(function() {
  try {
    if (typeof Readability === 'undefined') {
      return JSON.stringify({error: 'Readability not loaded'});
    }
    var documentClone = document.cloneNode(true);
    var article = new Readability(documentClone).parse();
    if (article) {
      var paragraphs = [];
      if (article.content) {
        var parser = new DOMParser();
        var doc = parser.parseFromString(article.content, 'text/html');
        var blocks = doc.querySelectorAll('p, h1, h2, h3, h4, h5, h6, li, pre');
        for (var i = 0; i < blocks.length; i++) {
          var text = blocks[i].textContent.trim();
          if (text.length > 10) {
            paragraphs.push({
              tag: blocks[i].tagName.toLowerCase(),
              text: text
            });
          }
        }
      }
      
      if (paragraphs.length === 0 && article.textContent) {
        var lines = article.textContent.split('\\n');
        for (var j = 0; j < lines.length; j++) {
          var line = lines[j].trim();
          if (line.length > 10) {
            paragraphs.push({
              tag: 'p',
              text: line
            });
          }
        }
      }

      return JSON.stringify({
        title: article.title,
        byline: article.byline,
        siteName: article.siteName,
        paragraphs: paragraphs,
        textContent: article.textContent
      });
    } else {
      return JSON.stringify({error: 'Could not parse article'});
    }
  } catch(e) {
    return JSON.stringify({error: e.message});
  }
})();
''';
  }
}
