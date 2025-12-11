import 'package:hive/hive.dart';
import 'technique_evaluation.dart';

part 'section_evaluation.g.dart';

@HiveType(typeId: 4)
class SectionEvaluation {
  @HiveField(0)
  final String sectionName; // نام بخش (مثلاً "مخصوص دانش‌آموزان پیش دبستانی")

  @HiveField(1)
  final List<TechniqueEvaluation> techniques;

  SectionEvaluation({required this.sectionName, required this.techniques});

  SectionEvaluation copyWith({
    String? sectionName,
    List<TechniqueEvaluation>? techniques,
  }) {
    return SectionEvaluation(
      sectionName: sectionName ?? this.sectionName,
      techniques: techniques ?? this.techniques,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sectionName': sectionName,
      'techniques': techniques.map((t) => t.toJson()).toList(),
    };
  }

  factory SectionEvaluation.fromJson(Map<String, dynamic> json) {
    return SectionEvaluation(
      sectionName: json['sectionName'] as String,
      techniques: (json['techniques'] as List)
          .map((t) => TechniqueEvaluation.fromJson(t as Map<String, dynamic>))
          .toList(),
    );
  }
}
