import 'package:flutter/services.dart';

class ReadabilityInjector {
  String? _js;

  Future<String> get js async {
    _js ??= await rootBundle.loadString('assets/readability.js');
    return _js!;
  }

  Future<String> getInjectScript() async {
    final code = await js;
    return '''
(function() {
  if (typeof Readability !== 'undefined') return;
  var script = document.createElement('script');
  script.textContent = ${_escapeJs(code)};
  document.head.appendChild(script);
})();
''';
  }

  String getExtractScript() {
    return '''
(function() {
  try {
    var documentClone = document.cloneNode(true);
    var article = new Readability(documentClone).parse();
    if (article) {
      window.flutter_inappwebview.callHandler('onArticleExtracted', JSON.stringify(article));
    } else {
      window.flutter_inappwebview.callHandler('onArticleExtracted', JSON.stringify({error: 'Could not parse article'}));
    }
  } catch(e) {
    window.flutter_inappwebview.callHandler('onArticleExtracted', JSON.stringify({error: e.message}));
  }
})();
''';
  }

  String _escapeJs(String js) {
    // Use jsonEncode to properly escape the JS string
    return "'${js.replaceAll("\\", "\\\\").replaceAll("'", "\\'").replaceAll("\n", "\\n").replaceAll("\r", "")}'";
  }
}
