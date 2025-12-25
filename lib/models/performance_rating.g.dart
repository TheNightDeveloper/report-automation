// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'performance_rating.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PerformanceRatingAdapter extends TypeAdapter<PerformanceRating> {
  @override
  final int typeId = 11;

  @override
  PerformanceRating read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PerformanceRating(
      id: fields[0] as String,
      name: fields[1] as String,
      order: fields[2] as int,
      color: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, PerformanceRating obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.order)
      ..writeByte(3)
      ..write(obj.color);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PerformanceRatingAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
