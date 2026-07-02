class Figure {
  final String id;
  final String url;
  final String caption;

  Figure({
    required this.id,
    required this.url,
    required this.caption,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'url': url,
        'caption': caption,
      };

  factory Figure.fromJson(Map<String, dynamic> json) => Figure(
        id: json['id'] as String? ?? '',
        url: json['url'] as String? ?? '',
        caption: json['caption'] as String? ?? '',
      );
}
