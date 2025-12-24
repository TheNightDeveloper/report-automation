// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance_info.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AttendanceInfoAdapter extends TypeAdapter<AttendanceInfo> {
  @override
  final int typeId = 6;

  @override
  AttendanceInfo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AttendanceInfo(
      totalSessions: fields[0] as int?,
      attendedSessions: fields[1] as int?,
      performanceLevel: fields[2] as String?,
      sportField: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, AttendanceInfo obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.totalSessions)
      ..writeByte(1)
      ..write(obj.attendedSessions)
      ..writeByte(2)
      ..write(obj.performanceLevel)
      ..writeByte(3)
      ..write(obj.sportField);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttendanceInfoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
