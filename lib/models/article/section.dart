import '../paragraph/paragraph.dart';

class Section {
  final String heading;
  final List<Paragraph> paragraphs;

  Section({
    required this.heading,
    required this.paragraphs,
  });

  Map<String, dynamic> toJson() => {
        'heading': heading,
        'paragraphs': paragraphs.map((p) => p.toJson()).toList(),
      };

  factory Section.fromJson(Map<String, dynamic> json) => Section(
        heading: json['heading'] as String? ?? '',
        paragraphs: (json['paragraphs'] as List? ?? [])
            .map((p) => Paragraph.fromJson(p as Map<String, dynamic>))
            .toList(),
      );
}
