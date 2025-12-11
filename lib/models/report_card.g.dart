// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report_card.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ReportCardAdapter extends TypeAdapter<ReportCard> {
  @override
  final int typeId = 5;

  @override
  ReportCard read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ReportCard(
      studentId: fields[0] as String,
      studentInfo: fields[1] as StudentInfo,
      attendanceInfo: fields[2] as AttendanceInfo,
      sections: (fields[3] as Map).cast<String, SectionEvaluation>(),
    );
  }

  @override
  void write(BinaryWriter writer, ReportCard obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.studentId)
      ..writeByte(1)
      ..write(obj.studentInfo)
      ..writeByte(2)
      ..write(obj.attendanceInfo)
      ..writeByte(3)
      ..write(obj.sections);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReportCardAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
