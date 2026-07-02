import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:dio/dio.dart';

class AiService {
  final Dio _dio;
  String _backendUrl;
  String _accessKey;
  String _model;

  AiService({
    required Dio dio,
    String backendUrl = 'https://api.xiaomimimo.com',
    String accessKey = 'sk-cqumxtso5suztny5h5r01ar3g23cbp2phz3tuwkgo6lcjzoh',
    String model = 'mimo-v2.5',
  })  : _dio = dio,
        _backendUrl = backendUrl,
        _accessKey = accessKey,
        _model = model;

  void updateConfig({String? backendUrl, String? accessKey, String? model}) {
    if (backendUrl != null) _backendUrl = backendUrl;
    if (accessKey != null) _accessKey = accessKey;
    if (model != null) _model = model;
  }

  String get backendUrl => _backendUrl;
  String get accessKey => _accessKey;
  String get model => _model;

  Future<String> _loadPrompt(String name) async {
    try {
      return await rootBundle.loadString('assets/prompts/$name.md');
    } catch (_) {
      if (name == 'connection_test') {
        return 'Verify connection. Reply with JSON:\n{\n  "status": "connected"\n}';
      }
      return '';
    }
  }

  Future<String> chat(List<Map<String, String>> messages, {int maxTokens = 4096}) async {
    try {
      final response = await _dio.post(
        '$_backendUrl/v1/chat/completions',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_accessKey',
          },
        ),
        data: {
          'model': _model,
          'messages': messages,
          'max_tokens': maxTokens,
          'temperature': 0.0,
        },
      );

      final choice = response.data['choices'][0];
      final message = choice['message'];

      final content = message['content'] as String? ?? '';
      final reasoning = message['reasoning_content'] as String? ?? '';

      if (content.trim().isNotEmpty) return content.trim();
      if (reasoning.trim().isNotEmpty) return reasoning.trim();
      throw Exception('Empty response from model');
    } on DioException catch (e) {
      throw Exception('AI Request failed: ${e.message} (status: ${e.response?.statusCode})');
    }
  }

  Future<Map<String, dynamic>> chatJson(List<Map<String, String>> messages, {int maxTokens = 4096}) async {
    final response = await chat(messages, maxTokens: maxTokens);
    String jsonStr = response;

    final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response);
    if (jsonMatch != null) {
      jsonStr = jsonMatch.group(0)!;
    }

    try {
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to parse JSON response: $jsonStr');
    }
  }

  Future<Map<String, dynamic>> evaluateRecall({
    required List<String> paragraphs,
    required List<String> answers,
    required List<String> savedVocabulary,
  }) async {
    final systemPrompt = await _loadPrompt('review_system');
    final userPromptTemplate = await _loadPrompt('review_user');

    final paragraphsBuf = StringBuffer();
    for (int i = 0; i < paragraphs.length; i++) {
      paragraphsBuf.writeln('[Paragraph ${i + 1}]');
      paragraphsBuf.writeln('Original: ${paragraphs[i]}');
      paragraphsBuf.writeln('User recall: ${answers.length > i ? answers[i] : ""}\n');
    }

    final vocabSection = savedVocabulary.isNotEmpty
        ? 'Saved Vocabulary list during reading this paper: ${savedVocabulary.join(", ")}\nIdentify which of these saved words directly impacted understanding of misunderstood paragraphs.'
        : '';

    final userPrompt = userPromptTemplate
        .replaceAll('{paragraphs}', paragraphsBuf.toString())
        .replaceAll('{vocabulary_section}', vocabSection);

    return chatJson([
      {'role': 'system', 'content': systemPrompt},
      {'role': 'user', 'content': userPrompt},
    ], maxTokens: 4096);
  }

  Future<bool> testConnection() async {
    try {
      final response = await _dio.get(
        '$_backendUrl/v1/models',
        options: Options(
          headers: {'Authorization': 'Bearer $_accessKey'},
        ),
      );
      return response.statusCode == 200;
    } catch (_) {
      try {
        final response = await _dio.get(
          '$_backendUrl/health',
          options: Options(
            headers: {'Authorization': 'Bearer $_accessKey'},
          ),
        );
        return response.statusCode == 200;
      } catch (_) {
        return false;
      }
    }
  }
}
