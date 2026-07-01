import 'dart:convert';
import 'package:dio/dio.dart';

class AiClient {
  final Dio _dio;
  String _backendUrl;
  String _accessKey;
  String _model;

  AiClient({
    String backendUrl = 'https://backend-swart-three-sgl5999uxy.vercel.app',
    String accessKey = 'paperflow-s3cr3t-2026',
    String model = 'LongCat-2.0',
  })  : _backendUrl = backendUrl,
        _accessKey = accessKey,
        _model = model,
        _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 180),
        ));

  String get backendUrl => _backendUrl;
  String get accessKey => _accessKey;
  String get model => _model;

  void updateConfig({String? backendUrl, String? accessKey, String? model}) {
    if (backendUrl != null) _backendUrl = backendUrl;
    if (accessKey != null) _accessKey = accessKey;
    if (model != null) _model = model;
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

      // LongCat-2.0 is a reasoning model:
      // content = final answer, reasoning_content = thinking process
      final content = message['content'] as String? ?? '';
      final reasoning = message['reasoning_content'] as String? ?? '';

      // Return the content (final answer), fall back to reasoning if content is empty
      if (content.trim().isNotEmpty) return content.trim();
      if (reasoning.trim().isNotEmpty) return reasoning.trim();
      throw AiException(message: 'Empty response from model', statusCode: 200);
    } on DioException catch (e) {
      throw AiException(
        message: e.message ?? 'Unknown error',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<Map<String, dynamic>> chatJson(List<Map<String, String>> messages, {int maxTokens = 4096}) async {
    final response = await chat(messages, maxTokens: maxTokens);
    // Try to extract JSON from the response
    String jsonStr = response;

    // If response contains reasoning + JSON, extract just the JSON part
    final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response);
    if (jsonMatch != null) {
      jsonStr = jsonMatch.group(0)!;
    }

    try {
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      throw AiException(message: 'Failed to parse JSON response: $jsonStr', statusCode: 200);
    }
  }

  Future<bool> testConnection() async {
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

class AiException implements Exception {
  final String message;
  final int? statusCode;
  AiException({required this.message, this.statusCode});

  @override
  String toString() => 'AiException: $message (status: $statusCode)';
}
