// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sport.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SportAdapter extends TypeAdapter<Sport> {
  @override
  final int typeId = 8;

  @override
  Sport read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Sport(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String?,
      levels: (fields[3] as List).cast<Level>(),
      performanceRatings: (fields[4] as List).cast<PerformanceRating>(),
      createdAt: fields[5] as DateTime,
      updatedAt: fields[6] as DateTime,
      isDefault: fields[7] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Sport obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.levels)
      ..writeByte(4)
      ..write(obj.performanceRatings)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.updatedAt)
      ..writeByte(7)
      ..write(obj.isDefault);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SportAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
