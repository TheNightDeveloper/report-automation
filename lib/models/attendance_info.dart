import 'package:hive/hive.dart';

part 'attendance_info.g.dart';

@HiveType(typeId: 2)
class AttendanceInfo {
  @HiveField(0)
  final int? totalSessions; // تعداد کل جلسات برگزار شده در سال تحصیلی

  @HiveField(1)
  final int? attendedSessions; // تعداد جلسات حضور

  @HiveField(2)
  final int? performanceRank; // ردیف عملکرد

  AttendanceInfo({
    this.totalSessions,
    this.attendedSessions,
    this.performanceRank,
  });

  AttendanceInfo copyWith({
    int? totalSessions,
    int? attendedSessions,
    int? performanceRank,
  }) {
    return AttendanceInfo(
      totalSessions: totalSessions ?? this.totalSessions,
      attendedSessions: attendedSessions ?? this.attendedSessions,
      performanceRank: performanceRank ?? this.performanceRank,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalSessions': totalSessions,
      'attendedSessions': attendedSessions,
      'performanceRank': performanceRank,
    };
  }

  factory AttendanceInfo.fromJson(Map<String, dynamic> json) {
    return AttendanceInfo(
      totalSessions: json['totalSessions'] as int?,
      attendedSessions: json['attendedSessions'] as int?,
      performanceRank: json['performanceRank'] as int?,
    );
  }
}
