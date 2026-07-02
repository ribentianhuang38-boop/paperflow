import 'generic_adapter.dart';
import '../../../../models/article/article.dart';

class NatureAdapter extends GenericAdapter {
  @override
  Article adapt(Map<String, dynamic> json, String url) {
    final baseArticle = super.adapt(json, url);
    return baseArticle.copyWith(
      subtitle: 'Nature Portfolio',
      metadata: {...baseArticle.metadata, 'publisher': 'Nature Publishing Group'},
    );
  }
}
