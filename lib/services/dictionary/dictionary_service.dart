import 'package:dio/dio.dart';

class DictionaryService {
  final Dio _dio;

  DictionaryService(this._dio);

  Future<Map<String, dynamic>?> lookupWord(String word) async {
    try {
      final response = await _dio.get('https://api.dictionaryapi.dev/api/v2/entries/en/$word')
          .timeout(const Duration(seconds: 3));
      if (response.statusCode == 200 && response.data is List && (response.data as List).isNotEmpty) {
        final entry = (response.data as List).first;
        final wordText = entry['word'] ?? word;
        final phonetic = entry['phonetic'] ?? '';
        final meanings = entry['meanings'] as List?;
        
        String definition = '';
        String pos = '';
        
        if (meanings != null && meanings.isNotEmpty) {
          final firstMeaning = meanings.first;
          pos = firstMeaning['partOfSpeech'] ?? '';
          final definitions = firstMeaning['definitions'] as List?;
          if (definitions != null && definitions.isNotEmpty) {
            definition = definitions.first['definition'] ?? '';
          }
        }
        
        return {
          'word': wordText,
          'phonetic': phonetic,
          'pos': pos,
          'definition': definition,
        };
      }
    } catch (_) {}
    return null;
  }
}
