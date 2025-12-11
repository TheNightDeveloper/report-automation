import 'package:hive/hive.dart';
import 'student_info.dart';
import 'attendance_info.dart';
import 'section_evaluation.dart';

part 'report_card.g.dart';

@HiveType(typeId: 5)
class ReportCard {
  @HiveField(0)
  final String studentId;

  @HiveField(1)
  final StudentInfo studentInfo;

  @HiveField(2)
  final AttendanceInfo attendanceInfo;

  @HiveField(3)
  final Map<String, SectionEvaluation> sections;

  ReportCard({
    required this.studentId,
    required this.studentInfo,
    required this.attendanceInfo,
    required this.sections,
  });

  ReportCard copyWith({
    String? studentId,
    StudentInfo? studentInfo,
    AttendanceInfo? attendanceInfo,
    Map<String, SectionEvaluation>? sections,
  }) {
    return ReportCard(
      studentId: studentId ?? this.studentId,
      studentInfo: studentInfo ?? this.studentInfo,
      attendanceInfo: attendanceInfo ?? this.attendanceInfo,
      sections: sections ?? this.sections,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'studentInfo': studentInfo.toJson(),
      'attendanceInfo': attendanceInfo.toJson(),
      'sections': sections.map((key, value) => MapEntry(key, value.toJson())),
    };
  }

  factory ReportCard.fromJson(Map<String, dynamic> json) {
    return ReportCard(
      studentId: json['studentId'] as String,
      studentInfo: StudentInfo.fromJson(
        json['studentInfo'] as Map<String, dynamic>,
      ),
      attendanceInfo: AttendanceInfo.fromJson(
        json['attendanceInfo'] as Map<String, dynamic>,
      ),
      sections: (json['sections'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(
          key,
          SectionEvaluation.fromJson(value as Map<String, dynamic>),
        ),
      ),
    );
  }
}
