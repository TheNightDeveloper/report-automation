import 'package:hive/hive.dart';
import 'technique_evaluation.dart';

part 'level_evaluation.g.dart';

@HiveType(typeId: 12)
class LevelEvaluation {
  @HiveField(0)
  final String levelId;

  @HiveField(1)
  final Map<String, TechniqueEvaluation> techniqueEvaluations;

  LevelEvaluation({required this.levelId, required this.techniqueEvaluations});

  LevelEvaluation copyWith({
    String? levelId,
    Map<String, TechniqueEvaluation>? techniqueEvaluations,
  }) {
    return LevelEvaluation(
      levelId: levelId ?? this.levelId,
      techniqueEvaluations: techniqueEvaluations ?? this.techniqueEvaluations,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'levelId': levelId,
      'techniqueEvaluations': techniqueEvaluations.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
    };
  }

  factory LevelEvaluation.fromJson(Map<String, dynamic> json) {
    return LevelEvaluation(
      levelId: json['levelId'] as String,
      techniqueEvaluations:
          (json['techniqueEvaluations'] as Map<String, dynamic>).map(
            (key, value) => MapEntry(
              key,
              TechniqueEvaluation.fromJson(value as Map<String, dynamic>),
            ),
          ),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LevelEvaluation && other.levelId == levelId;
  }

  @override
  int get hashCode {
    return levelId.hashCode;
  }
}
