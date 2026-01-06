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

    // Migration: تبدیل performanceLevel قدیمی به performanceLevels جدید
    List<String>? performanceLevels;
    if (fields[2] is List) {
      performanceLevels = (fields[2] as List).cast<String>();
    } else if (fields[2] is String && (fields[2] as String).isNotEmpty) {
      performanceLevels = [fields[2] as String];
    }

    return AttendanceInfo(
      totalSessions: fields[0] as int?,
      attendedSessions: fields[1] as int?,
      performanceLevels: performanceLevels,
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
      ..write(obj.performanceLevels)
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
