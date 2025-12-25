import 'package:hive/hive.dart';
import 'student_info.dart';
import 'attendance_info.dart';
import 'section_evaluation.dart';
import 'level_evaluation.dart';

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
  final Map<String, SectionEvaluation>? sections; // قدیمی - برای migration

  @HiveField(4)
  final String? comments; // توضیحات

  @HiveField(5)
  final String? signatureImagePath; // مسیر تصویر امضای مدیریت

  @HiveField(6)
  final String? sportId; // جدید - reference to Sport

  @HiveField(7)
  final Map<String, LevelEvaluation>? levelEvaluations; // جدید - ساختار جدید

  ReportCard({
    required this.studentId,
    required this.studentInfo,
    required this.attendanceInfo,
    this.sections, // nullable برای سازگاری
    this.comments,
    this.signatureImagePath,
    this.sportId,
    this.levelEvaluations,
  });

  ReportCard copyWith({
    String? studentId,
    StudentInfo? studentInfo,
    AttendanceInfo? attendanceInfo,
    Map<String, SectionEvaluation>? sections,
    String? comments,
    String? signatureImagePath,
    String? sportId,
    Map<String, LevelEvaluation>? levelEvaluations,
  }) {
    return ReportCard(
      studentId: studentId ?? this.studentId,
      studentInfo: studentInfo ?? this.studentInfo,
      attendanceInfo: attendanceInfo ?? this.attendanceInfo,
      sections: sections ?? this.sections,
      comments: comments ?? this.comments,
      signatureImagePath: signatureImagePath ?? this.signatureImagePath,
      sportId: sportId ?? this.sportId,
      levelEvaluations: levelEvaluations ?? this.levelEvaluations,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'studentInfo': studentInfo.toJson(),
      'attendanceInfo': attendanceInfo.toJson(),
      if (sections != null)
        'sections': sections!.map(
          (key, value) => MapEntry(key, value.toJson()),
        ),
      'comments': comments,
      'signatureImagePath': signatureImagePath,
      'sportId': sportId,
      if (levelEvaluations != null)
        'levelEvaluations': levelEvaluations!.map(
          (key, value) => MapEntry(key, value.toJson()),
        ),
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
      sections: json['sections'] != null
          ? (json['sections'] as Map<String, dynamic>).map(
              (key, value) => MapEntry(
                key,
                SectionEvaluation.fromJson(value as Map<String, dynamic>),
              ),
            )
          : null,
      comments: json['comments'] as String?,
      signatureImagePath: json['signatureImagePath'] as String?,
      sportId: json['sportId'] as String?,
      levelEvaluations: json['levelEvaluations'] != null
          ? (json['levelEvaluations'] as Map<String, dynamic>).map(
              (key, value) => MapEntry(
                key,
                LevelEvaluation.fromJson(value as Map<String, dynamic>),
              ),
            )
          : null,
    );
  }
}
