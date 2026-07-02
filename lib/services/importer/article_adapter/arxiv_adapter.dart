import 'generic_adapter.dart';
import '../../../../models/article/article.dart';

class ArxivAdapter extends GenericAdapter {
  @override
  Article adapt(Map<String, dynamic> json, String url) {
    final baseArticle = super.adapt(json, url);
    
    // Extract arXiv ID from URL if possible
    String? arxivId;
    final match = RegExp(r'abs/(\d+\.\d+)').firstMatch(url);
    if (match != null) {
      arxivId = match.group(1);
    }

    return baseArticle.copyWith(
      subtitle: 'arXiv e-print',
      metadata: {
        ...baseArticle.metadata,
        'arxivId': arxivId,
        'category': 'Computer Science / Physics / Math'
      },
    );
  }
}
