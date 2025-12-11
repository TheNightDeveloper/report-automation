import 'package:hive_flutter/hive_flutter.dart';
import '../models/models.dart';

class StudentRepository {
  static const String _boxName = 'students';
  Box<Student>? _box;

  Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      _box = await Hive.openBox<Student>(_boxName);
    } else {
      _box = Hive.box<Student>(_boxName);
    }
  }

  Future<void> saveStudents(List<Student> students) async {
    await init();
    final Map<String, Student> studentMap = {
      for (var student in students) student.id: student,
    };
    await _box!.putAll(studentMap);
  }

  Future<List<Student>> loadStudents() async {
    await init();
    return _box!.values.toList();
  }

  Future<void> updateStudent(Student student) async {
    await init();
    await _box!.put(student.id, student);
  }

  Future<Student?> getStudent(String id) async {
    await init();
    return _box!.get(id);
  }

  Future<void> deleteStudent(String id) async {
    await init();
    await _box!.delete(id);
  }

  Future<void> deleteAllStudents() async {
    await init();
    await _box!.clear();
  }

  Future<int> getStudentCount() async {
    await init();
    return _box!.length;
  }

  Future<void> close() async {
    if (_box?.isOpen ?? false) {
      await _box!.close();
    }
  }
}
