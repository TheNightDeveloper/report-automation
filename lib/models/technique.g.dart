// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'technique.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TechniqueAdapter extends TypeAdapter<Technique> {
  @override
  final int typeId = 10;

  @override
  Technique read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Technique(
      id: fields[0] as String,
      name: fields[1] as String,
      order: fields[2] as int,
      description: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Technique obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.order)
      ..writeByte(3)
      ..write(obj.description);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TechniqueAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
