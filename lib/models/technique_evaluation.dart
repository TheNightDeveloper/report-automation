import 'package:hive/hive.dart';
import 'performance_level.dart';

part 'technique_evaluation.g.dart';

@HiveType(typeId: 3)
class TechniqueEvaluation {
  @HiveField(0)
  final int? number; // ردیف - قدیمی، nullable برای سازگاری

  @HiveField(1)
  final String? techniqueName; // نام تکنیک - قدیمی، nullable برای سازگاری

  @HiveField(2)
  final String? performanceLevel; // عالی، خوب، متوسط - قدیمی

  @HiveField(3)
  final String? techniqueId; // جدید - reference to Technique

  @HiveField(4)
  final String? performanceRatingId; // جدید - reference to PerformanceRating

  TechniqueEvaluation({
    this.number,
    this.techniqueName,
    this.performanceLevel,
    this.techniqueId,
    this.performanceRatingId,
  });

  PerformanceLevel? get level {
    return PerformanceLevelExtension.fromString(performanceLevel);
  }

  TechniqueEvaluation copyWith({
    int? number,
    String? techniqueName,
    String? performanceLevel,
    String? techniqueId,
    String? performanceRatingId,
  }) {
    return TechniqueEvaluation(
      number: number ?? this.number,
      techniqueName: techniqueName ?? this.techniqueName,
      performanceLevel: performanceLevel ?? this.performanceLevel,
      techniqueId: techniqueId ?? this.techniqueId,
      performanceRatingId: performanceRatingId ?? this.performanceRatingId,
    );
  }

  TechniqueEvaluation withPerformanceLevel(PerformanceLevel? level) {
    return TechniqueEvaluation(
      number: number,
      techniqueName: techniqueName,
      performanceLevel: level?.name,
      techniqueId: techniqueId,
      performanceRatingId: performanceRatingId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (number != null) 'number': number,
      if (techniqueName != null) 'techniqueName': techniqueName,
      if (performanceLevel != null) 'performanceLevel': performanceLevel,
      if (techniqueId != null) 'techniqueId': techniqueId,
      if (performanceRatingId != null)
        'performanceRatingId': performanceRatingId,
    };
  }

  factory TechniqueEvaluation.fromJson(Map<String, dynamic> json) {
    return TechniqueEvaluation(
      number: json['number'] as int?,
      techniqueName: json['techniqueName'] as String?,
      performanceLevel: json['performanceLevel'] as String?,
      techniqueId: json['techniqueId'] as String?,
      performanceRatingId: json['performanceRatingId'] as String?,
    );
  }
}
