import 'package:hive/hive.dart';
import '../models/models.dart';

part 'folder.g.dart';

@HiveType(typeId: 13)
class Folder {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final List<Student> students; // تغییر: حالا Student ها مستقیماً در پوشه ذخیره می‌شوند

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  final DateTime? updatedAt;

  Folder({
    required this.id,
    required this.name,
    List<Student>? students,
    DateTime? createdAt,
    this.updatedAt,
  }) : students = students ?? [],
       createdAt = createdAt ?? DateTime.now();

  Folder copyWith({
    String? id,
    String? name,
    List<Student>? students,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Folder(
      id: id ?? this.id,
      name: name ?? this.name,
      students: students ?? this.students,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'students': students.map((s) => s.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory Folder.fromJson(Map<String, dynamic> json) {
    return Folder(
      id: json['id'] as String,
      name: json['name'] as String,
      students:
          (json['students'] as List<dynamic>?)
              ?.map((e) => Student.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  int get studentCount => students.length;

  int get completedCount => students.where((s) => s.isCompleted).length;

  double get completionPercentage {
    if (students.isEmpty) return 0.0;
    return (completedCount / students.length) * 100;
  }
}
