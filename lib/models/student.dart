import 'package:hive/hive.dart';

part 'student.g.dart';

@HiveType(typeId: 0)
class Student {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final bool isCompleted;

  Student({required this.id, required this.name, this.isCompleted = false});

  Student copyWith({String? id, String? name, bool? isCompleted}) {
    return Student(
      id: id ?? this.id,
      name: name ?? this.name,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'isCompleted': isCompleted};
  }

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] as String,
      name: json['name'] as String,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }
}
