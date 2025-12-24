import 'package:hive/hive.dart';

part 'student_info.g.dart';

@HiveType(typeId: 7)
class StudentInfo {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final String? grade; // مقطع

  @HiveField(2)
  final String? level; // پایه

  @HiveField(3)
  final String? school; // آموزشگاه

  @HiveField(4)
  final String? headCoach; // سرمربی

  @HiveField(5)
  final String? sportField; // رشته ورزشی

  StudentInfo({
    required this.name,
    this.grade,
    this.level,
    this.school,
    this.headCoach,
    this.sportField,
  });

  StudentInfo copyWith({
    String? name,
    String? grade,
    String? level,
    String? school,
    String? headCoach,
    String? sportField,
  }) {
    return StudentInfo(
      name: name ?? this.name,
      grade: grade ?? this.grade,
      level: level ?? this.level,
      school: school ?? this.school,
      headCoach: headCoach ?? this.headCoach,
      sportField: sportField ?? this.sportField,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'grade': grade,
      'level': level,
      'school': school,
      'headCoach': headCoach,
      'sportField': sportField,
    };
  }

  factory StudentInfo.fromJson(Map<String, dynamic> json) {
    return StudentInfo(
      name: json['name'] as String,
      grade: json['grade'] as String?,
      level: json['level'] as String?,
      school: json['school'] as String?,
      headCoach: json['headCoach'] as String?,
      sportField: json['sportField'] as String?,
    );
  }
}
