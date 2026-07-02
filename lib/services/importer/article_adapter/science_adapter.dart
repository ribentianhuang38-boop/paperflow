import 'generic_adapter.dart';
import '../../../../models/article/article.dart';

class ScienceAdapter extends GenericAdapter {
  @override
  Article adapt(Map<String, dynamic> json, String url) {
    final baseArticle = super.adapt(json, url);
    return baseArticle.copyWith(
      subtitle: 'Science Journal',
      metadata: {...baseArticle.metadata, 'publisher': 'AAAS'},
    );
  }
}
