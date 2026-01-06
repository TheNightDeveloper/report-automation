import 'package:hive/hive.dart';

part 'attendance_info.g.dart';

@HiveType(typeId: 6)
class AttendanceInfo {
  @HiveField(0)
  final int? totalSessions; // تعداد کل جلسات برگزار شده در سال تحصیلی

  @HiveField(1)
  final int? attendedSessions; // تعداد جلسات حضور

  @HiveField(2)
  final List<String> performanceLevels; // سطوح عملکرد (مولتی سلکت)

  @HiveField(3)
  final String? sportField; // رشته ورزشی

  AttendanceInfo({
    this.totalSessions,
    this.attendedSessions,
    List<String>? performanceLevels,
    this.sportField,
  }) : performanceLevels = performanceLevels ?? [];

  AttendanceInfo copyWith({
    int? totalSessions,
    int? attendedSessions,
    List<String>? performanceLevels,
    String? sportField,
  }) {
    return AttendanceInfo(
      totalSessions: totalSessions ?? this.totalSessions,
      attendedSessions: attendedSessions ?? this.attendedSessions,
      performanceLevels: performanceLevels ?? this.performanceLevels,
      sportField: sportField ?? this.sportField,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalSessions': totalSessions,
      'attendedSessions': attendedSessions,
      'performanceLevels': performanceLevels,
      'sportField': sportField,
    };
  }

  factory AttendanceInfo.fromJson(Map<String, dynamic> json) {
    return AttendanceInfo(
      totalSessions: json['totalSessions'] as int?,
      attendedSessions: json['attendedSessions'] as int?,
      performanceLevels: json['performanceLevels'] != null
          ? List<String>.from(json['performanceLevels'] as List)
          : (json['performanceLevel'] != null
                ? [
                    json['performanceLevel'] as String,
                  ] // migration از فیلد قدیمی
                : null),
      sportField: json['sportField'] as String?,
    );
  }
}
