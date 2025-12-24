import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../repositories/student_repository.dart';
import '../services/excel_import_service.dart';

// State class برای مدیریت لیست دانش‌آموزان
class StudentState {
  final List<Student> students;
  final int? selectedIndex;
  final bool isLoading;
  final String? errorMessage;

  StudentState({
    this.students = const [],
    this.selectedIndex,
    this.isLoading = false,
    this.errorMessage,
  });

  StudentState copyWith({
    List<Student>? students,
    int? selectedIndex,
    bool? isLoading,
    String? errorMessage,
  }) {
    return StudentState(
      students: students ?? this.students,
      selectedIndex: selectedIndex ?? this.selectedIndex,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  Student? get selectedStudent {
    if (selectedIndex != null &&
        selectedIndex! >= 0 &&
        selectedIndex! < students.length) {
      return students[selectedIndex!];
    }
    return null;
  }

  int get completedCount {
    return students.where((s) => s.isCompleted).length;
  }

  double get completionPercentage {
    if (students.isEmpty) return 0.0;
    return (completedCount / students.length) * 100;
  }
}

// Notifier برای مدیریت state دانش‌آموزان
class StudentNotifier extends Notifier<StudentState> {
  late final StudentRepository _repository;
  late final ExcelImportService _excelService;

  @override
  StudentState build() {
    _repository = StudentRepository();
    _excelService = ExcelImportService();
    return StudentState();
  }

  // بارگذاری لیست دانش‌آموزان
  Future<void> loadStudents() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final students = await _repository.loadStudents();
      state = state.copyWith(students: students, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'خطا در بارگذاری لیست دانش‌آموزان: ${e.toString()}',
      );
    }
  }

  // import از فایل Excel (جایگزینی)
  Future<void> importFromExcel(String filePath, {bool append = false}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final newStudents = await _excelService.importStudentsFromExcel(filePath);

      List<Student> finalStudents;
      if (append) {
        // اضافه کردن به لیست موجود (بدون تکراری)
        final existingIds = state.students.map((s) => s.id).toSet();
        final uniqueNewStudents = newStudents
            .where((s) => !existingIds.contains(s.id))
            .toList();
        finalStudents = [...state.students, ...uniqueNewStudents];
      } else {
        // جایگزینی کامل
        finalStudents = newStudents;
      }

      await _repository.saveStudents(finalStudents);
      state = state.copyWith(
        students: finalStudents,
        isLoading: false,
        selectedIndex: finalStudents.isNotEmpty ? 0 : null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'خطا در import فایل Excel: ${e.toString()}',
      );
    }
  }

  // انتخاب دانش‌آموز
  void selectStudent(int index) {
    if (index >= 0 && index < state.students.length) {
      state = state.copyWith(selectedIndex: index);
    }
  }

  // انتخاب دانش‌آموز بعدی
  void selectNextStudent() {
    if (state.selectedIndex != null &&
        state.selectedIndex! < state.students.length - 1) {
      state = state.copyWith(selectedIndex: state.selectedIndex! + 1);
    }
  }

  // انتخاب دانش‌آموز قبلی
  void selectPreviousStudent() {
    if (state.selectedIndex != null && state.selectedIndex! > 0) {
      state = state.copyWith(selectedIndex: state.selectedIndex! - 1);
    }
  }

  // به‌روزرسانی وضعیت تکمیل دانش‌آموز
  Future<void> updateStudentCompletion(
    String studentId,
    bool isCompleted,
  ) async {
    try {
      final updatedStudents = state.students.map((student) {
        if (student.id == studentId) {
          return student.copyWith(isCompleted: isCompleted);
        }
        return student;
      }).toList();

      await _repository.saveStudents(updatedStudents);
      state = state.copyWith(students: updatedStudents);
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'خطا در به‌روزرسانی وضعیت دانش‌آموز: ${e.toString()}',
      );
    }
  }

  // حذف همه دانش‌آموزان
  Future<void> deleteAllStudents() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.deleteAllStudents();
      state = StudentState();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'خطا در حذف دانش‌آموزان: ${e.toString()}',
      );
    }
  }

  // پاک کردن پیام خطا
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

// Provider اصلی
final studentProvider = NotifierProvider<StudentNotifier, StudentState>(
  StudentNotifier.new,
);
