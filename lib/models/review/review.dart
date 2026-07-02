class ReviewSession {
  final int? id;
  final int documentId;
  final double? overallScore;
  final String? suggestions;
  final String? vocabImpact;
  final int createdAt;

  ReviewSession({
    this.id,
    required this.documentId,
    this.overallScore,
    this.suggestions,
    this.vocabImpact,
    required this.createdAt,
  });

  factory ReviewSession.fromMap(Map<String, dynamic> map) => ReviewSession(
        id: map['id'] as int?,
        documentId: map['documentId'] as int,
        overallScore: (map['overallScore'] as num?)?.toDouble(),
        suggestions: map['suggestions'] as String?,
        vocabImpact: map['vocabImpact'] as String?,
        createdAt: map['createdAt'] as int,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'documentId': documentId,
        'overallScore': overallScore,
        'suggestions': suggestions,
        'vocabImpact': vocabImpact,
        'createdAt': createdAt,
      };
}

class ReviewAnswer {
  final int? id;
  final int sessionId;
  final int paragraphIdx;
  final String paragraphText;
  final String userAnswer;
  final double? aiScore;
  final String? aiJudgment;
  final String? aiFeedback;

  ReviewAnswer({
    this.id,
    required this.sessionId,
    required this.paragraphIdx,
    required this.paragraphText,
    required this.userAnswer,
    this.aiScore,
    this.aiJudgment,
    this.aiFeedback,
  });

  factory ReviewAnswer.fromMap(Map<String, dynamic> map) => ReviewAnswer(
        id: map['id'] as int?,
        sessionId: map['sessionId'] as int,
        paragraphIdx: map['paragraphIdx'] as int,
        paragraphText: map['paragraphText'] as String? ?? '',
        userAnswer: map['userAnswer'] as String? ?? '',
        aiScore: (map['aiScore'] as num?)?.toDouble(),
        aiJudgment: map['aiJudgment'] as String?,
        aiFeedback: map['aiFeedback'] as String?,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'sessionId': sessionId,
        'paragraphIdx': paragraphIdx,
        'paragraphText': paragraphText,
        'userAnswer': userAnswer,
        'aiScore': aiScore,
        'aiJudgment': aiJudgment,
        'aiFeedback': aiFeedback,
      };
}
