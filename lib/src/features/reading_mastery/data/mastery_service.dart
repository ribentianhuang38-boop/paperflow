import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/database/app_database.dart';
import '../data/mastery_dao.dart';
import '../../dictionary/data/vocabulary_dao.dart';
import '../../active_recall/presentation/recall_screen.dart';

class MasteryService {
  final MasteryDao _masteryDao;
  final VocabularyDao _vocabularyDao;

  MasteryService(this._masteryDao, this._vocabularyDao);

  Future<MasteryData> calculateMastery(int documentId) async {
    final latestScore = await _masteryDao.getLatestScore(documentId);
    final vocabTotal = await _vocabularyDao.getTotalCount();
    final vocabMastered = await _vocabularyDao.getMasteredCount();

    final aiScore = latestScore?.score ?? 0.0;
    final vocabMastery = vocabTotal > 0
        ? (vocabMastered / vocabTotal * 100).clamp(0, 100).toDouble()
        : 0.0;

    return MasteryData(
      overallScore: aiScore,
      aiComponent: aiScore,
      vocabComponent: vocabMastery,
      totalVocabulary: vocabTotal,
      masteredVocabulary: vocabMastered,
    );
  }
}

class MasteryData {
  final double overallScore;
  final double aiComponent;
  final double vocabComponent;
  final int totalVocabulary;
  final int masteredVocabulary;

  MasteryData({
    required this.overallScore,
    required this.aiComponent,
    required this.vocabComponent,
    required this.totalVocabulary,
    required this.masteredVocabulary,
  });
}
