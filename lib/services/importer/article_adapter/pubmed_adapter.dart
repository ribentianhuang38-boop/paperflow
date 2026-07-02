import 'generic_adapter.dart';
import '../../../../models/article/article.dart';

class PubmedAdapter extends GenericAdapter {
  @override
  Article adapt(Map<String, dynamic> json, String url) {
    final baseArticle = super.adapt(json, url);
    return baseArticle.copyWith(
      subtitle: 'PubMed / NCBI',
      metadata: {...baseArticle.metadata, 'sourceType': 'Medical / Life Sciences'},
    );
  }
}
