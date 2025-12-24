import 'package:hive/hive.dart';

part 'attendance_info.g.dart';

@HiveType(typeId: 6)
class AttendanceInfo {
  @HiveField(0)
  final int? totalSessions; // تعداد کل جلسات برگزار شده در سال تحصیلی

  @HiveField(1)
  final int? attendedSessions; // تعداد جلسات حضور

  @HiveField(2)
  final String? performanceLevel; // سطح عملکرد

  @HiveField(3)
  final String? sportField; // رشته ورزشی

  AttendanceInfo({
    this.totalSessions,
    this.attendedSessions,
    this.performanceLevel,
    this.sportField,
  });

  AttendanceInfo copyWith({
    int? totalSessions,
    int? attendedSessions,
    String? performanceLevel,
    String? sportField,
  }) {
    return AttendanceInfo(
      totalSessions: totalSessions ?? this.totalSessions,
      attendedSessions: attendedSessions ?? this.attendedSessions,
      performanceLevel: performanceLevel ?? this.performanceLevel,
      sportField: sportField ?? this.sportField,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalSessions': totalSessions,
      'attendedSessions': attendedSessions,
      'performanceLevel': performanceLevel,
      'sportField': sportField,
    };
  }

  factory AttendanceInfo.fromJson(Map<String, dynamic> json) {
    return AttendanceInfo(
      totalSessions: json['totalSessions'] as int?,
      attendedSessions: json['attendedSessions'] as int?,
      performanceLevel: json['performanceLevel'] as String?,
      sportField: json['sportField'] as String?,
    );
  }
}
