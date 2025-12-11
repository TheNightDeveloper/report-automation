import 'package:hive/hive.dart';
import 'performance_level.dart';

part 'technique_evaluation.g.dart';

@HiveType(typeId: 3)
class TechniqueEvaluation {
  @HiveField(0)
  final int number; // ردیف

  @HiveField(1)
  final String techniqueName; // نام تکنیک

  @HiveField(2)
  final String? performanceLevel; // عالی، خوب، متوسط (stored as string)

  TechniqueEvaluation({
    required this.number,
    required this.techniqueName,
    this.performanceLevel,
  });

  PerformanceLevel? get level {
    return PerformanceLevelExtension.fromString(performanceLevel);
  }

  TechniqueEvaluation copyWith({
    int? number,
    String? techniqueName,
    String? performanceLevel,
  }) {
    return TechniqueEvaluation(
      number: number ?? this.number,
      techniqueName: techniqueName ?? this.techniqueName,
      performanceLevel: performanceLevel ?? this.performanceLevel,
    );
  }

  TechniqueEvaluation withPerformanceLevel(PerformanceLevel? level) {
    return TechniqueEvaluation(
      number: number,
      techniqueName: techniqueName,
      performanceLevel: level?.name,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'techniqueName': techniqueName,
      'performanceLevel': performanceLevel,
    };
  }

  factory TechniqueEvaluation.fromJson(Map<String, dynamic> json) {
    return TechniqueEvaluation(
      number: json['number'] as int,
      techniqueName: json['techniqueName'] as String,
      performanceLevel: json['performanceLevel'] as String?,
    );
  }
}
