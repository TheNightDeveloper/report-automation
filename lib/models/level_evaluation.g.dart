// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'level_evaluation.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LevelEvaluationAdapter extends TypeAdapter<LevelEvaluation> {
  @override
  final int typeId = 12;

  @override
  LevelEvaluation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LevelEvaluation(
      levelId: fields[0] as String,
      techniqueEvaluations:
          (fields[1] as Map).cast<String, TechniqueEvaluation>(),
    );
  }

  @override
  void write(BinaryWriter writer, LevelEvaluation obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.levelId)
      ..writeByte(1)
      ..write(obj.techniqueEvaluations);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LevelEvaluationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
