import 'generic_adapter.dart';
import '../../../../models/article/article.dart';

class CellAdapter extends GenericAdapter {
  @override
  Article adapt(Map<String, dynamic> json, String url) {
    final baseArticle = super.adapt(json, url);
    return baseArticle.copyWith(
      subtitle: 'Cell Press',
      metadata: {...baseArticle.metadata, 'publisher': 'Elsevier'},
    );
  }
}
