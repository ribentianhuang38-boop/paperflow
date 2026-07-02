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
      return JSON.stringify(article);
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
