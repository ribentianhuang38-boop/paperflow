import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/design_system/color_tokens.dart';
import '../../../core/design_system/typography.dart';
import '../../../models/article/article.dart';

class ShareCardCapture {
  static final GlobalKey boundaryKey = GlobalKey();

  static Future<void> captureAndShare({
    required BuildContext context,
    required Article article,
    required double overallScore,
    required double paragraphScore,
    required double conceptScore,
    required double logicScore,
    required double vocabularyScore,
    required int durationSec,
    required int vocabCount,
    required int highlightsCount,
    required int notesCount,
    required bool isStoryRatio,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                const SizedBox(width: 16),
                Text('Generating Share Card...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      await Future.delayed(const Duration(milliseconds: 500)); // Allow layout settling
      final RenderRepaintBoundary? boundary =
          boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      
      if (boundary == null) {
        throw Exception('RepaintBoundary render object not found');
      }

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData == null) {
        throw Exception('Failed to convert image to bytes');
      }

      final Uint8List pngBytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/paperflow_share_card.png');
      await tempFile.writeAsBytes(pngBytes);

      if (context.mounted) {
        Navigator.pop(context); // Dismiss dialog
      }

      await Share.shareXFiles(
        [XFile(tempFile.path)],
        text: 'My Active Reading Summary: "${article.title}" on PaperFlow',
      );
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Dismiss dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate card: $e'), backgroundColor: ColorTokens.error),
        );
      }
    }
  }
}

class ShareSummaryCardWidget extends StatelessWidget {
  final Article article;
  final double overallScore;
  final double paragraphScore;
  final double conceptScore;
  final double logicScore;
  final double vocabularyScore;
  final int durationSec;
  final int vocabCount;
  final int highlightsCount;
  final int notesCount;
  final bool isStoryRatio;

  const ShareSummaryCardWidget({
    super.key,
    required this.article,
    required this.overallScore,
    required this.paragraphScore,
    required this.conceptScore,
    required this.logicScore,
    required this.vocabularyScore,
    required this.durationSec,
    required this.vocabCount,
    required this.highlightsCount,
    required this.notesCount,
    required this.isStoryRatio,
  });

  @override
  Widget build(BuildContext context) {
    // 360 wide, height 450 (1080x1350) or 640 (1080x1920)
    final height = isStoryRatio ? 640.0 : 450.0;
    final formattedDuration = '${(durationSec / 60).toStringAsFixed(1)} mins';
    final dateStr = DateFormat('yyyy.MM.dd').format(DateTime.now());

    return Container(
      width: 360,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1.5),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Header Logo & Date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PaperFlow',
                style: AppTypography.title3.copyWith(
                  color: Colors.white,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                dateStr,
                style: AppTypography.caption2.copyWith(
                  color: Colors.white.withOpacity(0.5),
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),

          // Main Info
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: ColorTokens.accent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  article.fileType.toUpperCase(),
                  style: AppTypography.caption2.copyWith(
                    color: ColorTokens.accent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                article.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.title2.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),
              if (article.author != null) ...[
                const SizedBox(height: 6),
                Text(
                  article.author!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption1.copyWith(
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ],
            ],
          ),

          // Score Indicator
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Understanding',
                    style: AppTypography.caption1.copyWith(
                      color: Colors.white.withOpacity(0.4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${overallScore.round()}%',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 64,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -2,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Mini radar/grid values
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _miniScoreBar('Paragraph', paragraphScore),
                  _miniScoreBar('Concept', conceptScore),
                  _miniScoreBar('Logic', logicScore),
                  _miniScoreBar('Vocabulary', vocabularyScore),
                ],
              ),
            ],
          ),

          // Statistics metrics
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statNode('Duration', formattedDuration),
                _statNode('Vocabs', '$vocabCount'),
                _statNode('Highlights', '$highlightsCount'),
                _statNode('Notes', '$notesCount'),
              ],
            ),
          ),

          // Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Read • Recall • Review',
                style: AppTypography.caption2.copyWith(
                  color: Colors.white.withOpacity(0.3),
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniScoreBar(String label, double score) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
          ),
          Container(
            width: 50,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Stack(
              children: [
                Container(
                  width: 50 * (score / 100).clamp(0.0, 1.0),
                  decoration: BoxDecoration(
                    color: ColorTokens.accent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${score.round()}',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statNode(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 9,
            color: Colors.white.withOpacity(0.4),
          ),
        ),
      ],
    );
  }
}
