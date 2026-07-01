import 'dart:convert';
import 'package:flutter/services.dart';

class ReadabilityInjector {
  String? _js;

  Future<String> get js async {
    _js ??= await rootBundle.loadString('assets/readability.js');
    return _js!;
  }

  Future<String> getInjectScript() async {
    final code = await js;
    // Escape the JS code for embedding in a string literal
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
