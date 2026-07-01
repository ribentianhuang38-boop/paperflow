import 'dart:convert';
import 'package:dio/dio.dart';

class AiClient {
  final Dio _dio;
  String _baseUrl;
  String _apiKey;
  String _model;

  AiClient({
    String baseUrl = 'https://api.openai.com/v1',
    String apiKey = '',
    String model = 'longcat',
  })  : _baseUrl = baseUrl,
        _apiKey = apiKey,
        _model = model,
        _dio = Dio();

  String get baseUrl => _baseUrl;
  String get apiKey => _apiKey;
  String get model => _model;

  void updateConfig({
    String? baseUrl,
    String? apiKey,
    String? model,
  }) {
    if (baseUrl != null) _baseUrl = baseUrl;
    if (apiKey != null) _apiKey = apiKey;
    if (model != null) _model = model;
  }

  Future<String> chat(List<Map<String, String>> messages) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/chat/completions',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            if (_apiKey.isNotEmpty) 'Authorization': 'Bearer $_apiKey',
          },
        ),
        data: {
          'model': _model,
          'messages': messages,
          'temperature': 0.0,
          'response_format': {'type': 'json_object'},
        },
      );

      return response.data['choices'][0]['message']['content'] as String;
    } on DioException catch (e) {
      throw AiException(
        message: e.message ?? 'Unknown error',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<Map<String, dynamic>> chatJson(List<Map<String, String>> messages) async {
    final response = await chat(messages);
    return jsonDecode(response) as Map<String, dynamic>;
  }
}

class AiException implements Exception {
  final String message;
  final int? statusCode;

  AiException({required this.message, this.statusCode});

  @override
  String toString() => 'AiException: $message (status: $statusCode)';
}
