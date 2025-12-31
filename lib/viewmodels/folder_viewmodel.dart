import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../repositories/folder_repository.dart';

// State class برای مدیریت پوشه‌ها
class FolderState {
  final List<Folder> folders;
  final String? selectedFolderId;
  final bool isLoading;
  final String? errorMessage;

  FolderState({
    this.folders = const [],
    this.selectedFolderId,
    this.isLoading = false,
    this.errorMessage,
  });

  FolderState copyWith({
    List<Folder>? folders,
    String? selectedFolderId,
    bool? isLoading,
    String? errorMessage,
    bool clearSelectedFolder = false,
  }) {
    return FolderState(
      folders: folders ?? this.folders,
      selectedFolderId: clearSelectedFolder
          ? null
          : (selectedFolderId ?? this.selectedFolderId),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  Folder? get selectedFolder {
    if (selectedFolderId != null) {
      try {
        return folders.firstWhere((f) => f.id == selectedFolderId);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  int get totalStudents =>
      folders.fold(0, (sum, folder) => sum + folder.studentCount);
}

// Notifier برای مدیریت state پوشه‌ها
class FolderNotifier extends Notifier<FolderState> {
  late final FolderRepository _repository;

  @override
  FolderState build() {
    _repository = FolderRepository();
    return FolderState();
  }

  /// بارگذاری لیست پوشه‌ها
  Future<void> loadFolders() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final folders = await _repository.loadFolders();
      state = state.copyWith(folders: folders, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'خطا در بارگذاری پوشه‌ها: ${e.toString()}',
      );
    }
  }

  /// ایجاد پوشه جدید
  Future<String?> createFolder(
    String name, {
    List<Student>? initialStudents,
  }) async {
    if (name.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'نام پوشه نمی‌تواند خالی باشد');
      return null;
    }

    // بررسی تکراری بودن نام
    if (state.folders.any((f) => f.name == name.trim())) {
      state = state.copyWith(errorMessage: 'پوشه‌ای با این نام وجود دارد');
      return null;
    }

    try {
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final newFolder = Folder(
        id: id,
        name: name.trim(),
        students: initialStudents ?? [],
      );

      await _repository.saveFolder(newFolder);

      final updatedFolders = [...state.folders, newFolder];
      state = state.copyWith(folders: updatedFolders, selectedFolderId: id);

      return id;
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'خطا در ایجاد پوشه: ${e.toString()}',
      );
      return null;
    }
  }

  /// حذف پوشه
  Future<void> deleteFolder(String folderId) async {
    try {
      await _repository.deleteFolder(folderId);

      final updatedFolders = state.folders
          .where((f) => f.id != folderId)
          .toList();

      String? newSelectedId;
      if (state.selectedFolderId == folderId && updatedFolders.isNotEmpty) {
        newSelectedId = updatedFolders.first.id;
      }

      state = state.copyWith(
        folders: updatedFolders,
        selectedFolderId: newSelectedId,
        clearSelectedFolder:
            state.selectedFolderId == folderId && updatedFolders.isEmpty,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'خطا در حذف پوشه: ${e.toString()}');
    }
  }

  /// تغییر نام پوشه
  Future<void> renameFolder(String folderId, String newName) async {
    if (newName.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'نام پوشه نمی‌تواند خالی باشد');
      return;
    }

    // بررسی تکراری بودن نام
    if (state.folders.any(
      (f) => f.name == newName.trim() && f.id != folderId,
    )) {
      state = state.copyWith(errorMessage: 'پوشه‌ای با این نام وجود دارد');
      return;
    }

    try {
      final folder = state.folders.firstWhere((f) => f.id == folderId);
      final updatedFolder = folder.copyWith(
        name: newName.trim(),
        updatedAt: DateTime.now(),
      );

      await _repository.saveFolder(updatedFolder);

      final updatedFolders = state.folders.map((f) {
        return f.id == folderId ? updatedFolder : f;
      }).toList();

      state = state.copyWith(folders: updatedFolders);
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'خطا در تغییر نام پوشه: ${e.toString()}',
      );
    }
  }

  /// اضافه کردن دانش‌آموز به پوشه
  Future<void> addStudentToFolder(String folderId, Student student) async {
    try {
      final folder = state.folders.firstWhere((f) => f.id == folderId);

      // بررسی تکراری بودن
      if (folder.students.any((s) => s.id == student.id)) {
        state = state.copyWith(
          errorMessage: 'این دانش‌آموز قبلاً در این پوشه است',
        );
        return;
      }

      final updatedStudents = [...folder.students, student];
      final updatedFolder = folder.copyWith(
        students: updatedStudents,
        updatedAt: DateTime.now(),
      );

      await _repository.saveFolder(updatedFolder);

      final updatedFolders = state.folders.map((f) {
        return f.id == folderId ? updatedFolder : f;
      }).toList();

      state = state.copyWith(folders: updatedFolders);
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'خطا در اضافه کردن دانش‌آموز: ${e.toString()}',
      );
    }
  }

  /// اضافه کردن چند دانش‌آموز به پوشه
  Future<void> addStudentsToFolder(
    String folderId,
    List<Student> students,
  ) async {
    try {
      final folder = state.folders.firstWhere((f) => f.id == folderId);

      // فقط دانش‌آموزانی که قبلاً در پوشه نیستند
      final existingIds = folder.students.map((s) => s.id).toSet();
      final newStudents = students
          .where((s) => !existingIds.contains(s.id))
          .toList();

      if (newStudents.isEmpty) {
        state = state.copyWith(
          errorMessage: 'همه دانش‌آموزان قبلاً در این پوشه هستند',
        );
        return;
      }

      final updatedStudents = [...folder.students, ...newStudents];
      final updatedFolder = folder.copyWith(
        students: updatedStudents,
        updatedAt: DateTime.now(),
      );

      await _repository.saveFolder(updatedFolder);

      final updatedFolders = state.folders.map((f) {
        return f.id == folderId ? updatedFolder : f;
      }).toList();

      state = state.copyWith(folders: updatedFolders);
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'خطا در اضافه کردن دانش‌آموزان: ${e.toString()}',
      );
    }
  }

  /// حذف دانش‌آموز از پوشه
  Future<void> removeStudentFromFolder(
    String folderId,
    String studentId,
  ) async {
    try {
      final folder = state.folders.firstWhere((f) => f.id == folderId);
      final updatedStudents = folder.students
          .where((s) => s.id != studentId)
          .toList();

      final updatedFolder = folder.copyWith(
        students: updatedStudents,
        updatedAt: DateTime.now(),
      );

      await _repository.saveFolder(updatedFolder);

      final updatedFolders = state.folders.map((f) {
        return f.id == folderId ? updatedFolder : f;
      }).toList();

      state = state.copyWith(folders: updatedFolders);
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'خطا در حذف دانش‌آموز: ${e.toString()}',
      );
    }
  }

  /// به‌روزرسانی وضعیت تکمیل دانش‌آموز
  Future<void> updateStudentCompletion(
    String folderId,
    String studentId,
    bool isCompleted,
  ) async {
    try {
      final folder = state.folders.firstWhere((f) => f.id == folderId);
      final updatedStudents = folder.students.map((s) {
        if (s.id == studentId) {
          return s.copyWith(isCompleted: isCompleted);
        }
        return s;
      }).toList();

      final updatedFolder = folder.copyWith(
        students: updatedStudents,
        updatedAt: DateTime.now(),
      );

      await _repository.saveFolder(updatedFolder);

      final updatedFolders = state.folders.map((f) {
        return f.id == folderId ? updatedFolder : f;
      }).toList();

      state = state.copyWith(folders: updatedFolders);
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'خطا در به‌روزرسانی وضعیت: ${e.toString()}',
      );
    }
  }

  /// انتخاب پوشه
  void selectFolder(String? folderId) {
    state = state.copyWith(
      selectedFolderId: folderId,
      clearSelectedFolder: folderId == null,
    );
  }

  /// پاک کردن پیام خطا
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// دریافت همه دانش‌آموزان از همه پوشه‌ها
  List<Student> getAllStudents() {
    final allStudents = <Student>[];
    for (final folder in state.folders) {
      allStudents.addAll(folder.students);
    }
    return allStudents;
  }
}

// Provider اصلی
final folderProvider = NotifierProvider<FolderNotifier, FolderState>(
  FolderNotifier.new,
);
