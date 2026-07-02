import '../../services/ai/ai_service.dart';

class AiRepository {
  final AiService _aiService;

  AiRepository(this._aiService);

  Future<Map<String, dynamic>> evaluateRecall({
    required List<String> paragraphs,
    required List<String> answers,
    required List<String> savedVocabulary,
  }) {
    return _aiService.evaluateRecall(
      paragraphs: paragraphs,
      answers: answers,
      savedVocabulary: savedVocabulary,
    );
  }

  Future<bool> testConnection() {
    return _aiService.testConnection();
  }
}
