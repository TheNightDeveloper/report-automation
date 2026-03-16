import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';

/// State برای نگه‌داری اطلاعات navigation بین دانش‌آموزان
class NavigationState {
  final String? currentFolderId;
  final List<Student> students;
  final int currentIndex;

  NavigationState({
    this.currentFolderId,
    this.students = const [],
    this.currentIndex = -1,
  });

  NavigationState copyWith({
    String? currentFolderId,
    List<Student>? students,
    int? currentIndex,
    bool clearFolder = false,
  }) {
    return NavigationState(
      currentFolderId: clearFolder
          ? null
          : (currentFolderId ?? this.currentFolderId),
      students: students ?? this.students,
      currentIndex: currentIndex ?? this.currentIndex,
    );
  }

  bool get hasNext => currentIndex >= 0 && currentIndex < students.length - 1;
  bool get hasPrevious => currentIndex > 0;

  Student? get currentStudent {
    if (currentIndex >= 0 && currentIndex < students.length) {
      return students[currentIndex];
    }
    return null;
  }

  Student? get nextStudent {
    if (hasNext) {
      return students[currentIndex + 1];
    }
    return null;
  }

  Student? get previousStudent {
    if (hasPrevious) {
      return students[currentIndex - 1];
    }
    return null;
  }
}

/// Notifier برای مدیریت navigation
class NavigationNotifier extends Notifier<NavigationState> {
  @override
  NavigationState build() {
    return NavigationState();
  }

  /// تنظیم لیست دانش‌آموزان و index فعلی
  void setStudents({
    required String folderId,
    required List<Student> students,
    required String currentStudentId,
  }) {
    final index = students.indexWhere((s) => s.id == currentStudentId);
    state = state.copyWith(
      currentFolderId: folderId,
      students: students,
      currentIndex: index,
    );
  }

  /// رفتن به دانش‌آموز بعدی
  void goToNext() {
    if (state.hasNext) {
      state = state.copyWith(currentIndex: state.currentIndex + 1);
    }
  }

  /// رفتن به دانش‌آموز قبلی
  void goToPrevious() {
    if (state.hasPrevious) {
      state = state.copyWith(currentIndex: state.currentIndex - 1);
    }
  }

  /// پاک کردن navigation state
  void clear() {
    state = NavigationState();
  }
}

/// Provider اصلی
final navigationProvider =
    NotifierProvider<NavigationNotifier, NavigationState>(
      NavigationNotifier.new,
    );
