// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'technique_evaluation.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TechniqueEvaluationAdapter extends TypeAdapter<TechniqueEvaluation> {
  @override
  final int typeId = 3;

  @override
  TechniqueEvaluation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TechniqueEvaluation(
      number: fields[0] as int,
      techniqueName: fields[1] as String,
      performanceLevel: fields[2] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, TechniqueEvaluation obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.number)
      ..writeByte(1)
      ..write(obj.techniqueName)
      ..writeByte(2)
      ..write(obj.performanceLevel);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TechniqueEvaluationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
