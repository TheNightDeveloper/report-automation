import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

// State class برای مدیریت داده‌های برنامه
class AppDataState {
  final List<String> grades;
  final List<String> levels;
  final List<String> schools;
  final List<String> headCoaches;
  final bool isLoading;

  AppDataState({
    required this.grades,
    required this.levels,
    required this.schools,
    required this.headCoaches,
    this.isLoading = false,
  });

  AppDataState copyWith({
    List<String>? grades,
    List<String>? levels,
    List<String>? schools,
    List<String>? headCoaches,
    bool? isLoading,
  }) {
    return AppDataState(
      grades: grades ?? this.grades,
      levels: levels ?? this.levels,
      schools: schools ?? this.schools,
      headCoaches: headCoaches ?? this.headCoaches,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// Notifier برای مدیریت داده‌های برنامه
class AppDataNotifier extends Notifier<AppDataState> {
  static const String _boxName = 'app_data';
  Box? _box;

  @override
  AppDataState build() {
    // بارگذاری داده‌ها از کش
    _initializeBox();
    return AppDataState(
      grades: _getDefaultGrades(),
      levels: _getDefaultLevels(),
      schools: _getDefaultSchools(),
      headCoaches: _getDefaultHeadCoaches(),
    );
  }

  Future<void> _initializeBox() async {
    try {
      _box = await Hive.openBox(_boxName);
      await loadFromCache();
    } catch (e) {
      // در صورت خطا، از داده‌های پیش‌فرض استفاده می‌شود
    }
  }

  // داده‌های پیش‌فرض مقاطع
  List<String> _getDefaultGrades() {
    return ['پیش دبستانی', 'دبستان', 'دبیرستان', 'هنرستان'];
  }

  // داده‌های پیش‌فرض پایه‌ها
  List<String> _getDefaultLevels() {
    return [
      'پیش دبستانی',
      'پایه اول',
      'پایه دوم',
      'پایه سوم',
      'پایه چهارم',
      'پایه پنجم',
      'پایه ششم',
      'پایه هفتم',
      'پایه هشتم',
      'پایه نهم',
      'پایه دهم',
      'پایه یازدهم',
      'پایه دوازدهم',
    ];
  }

  // داده‌های پیش‌فرض آموزشگاه‌ها
  List<String> _getDefaultSchools() {
    return [
      'دبستان دولتی المهدی',
      'دبستان غیر دولتی المهدی نوین',
      'هنرستان المهدی',
      'دبیرستان المهدی',
      'سایر',
    ];
  }

  // داده‌های پیش‌فرض سرمربیان
  List<String> _getDefaultHeadCoaches() {
    return [
      'مربی مریم جاقوری ',
      'مربی سمیه صفائی',
      'مربی مژگان تقوی ',
      'مربی منیره ساربان',
      'سایر',
    ];
  }

  // افزودن مقطع جدید
  void addGrade(String grade) {
    if (grade.trim().isEmpty || state.grades.contains(grade)) return;
    state = state.copyWith(grades: [...state.grades, grade]);
    _saveToCache();
  }

  // حذف مقطع
  void removeGrade(String grade) {
    state = state.copyWith(
      grades: state.grades.where((g) => g != grade).toList(),
    );
    _saveToCache();
  }

  // افزودن پایه جدید
  void addLevel(String level) {
    if (level.trim().isEmpty || state.levels.contains(level)) return;
    state = state.copyWith(levels: [...state.levels, level]);
    _saveToCache();
  }

  // حذف پایه
  void removeLevel(String level) {
    state = state.copyWith(
      levels: state.levels.where((l) => l != level).toList(),
    );
    _saveToCache();
  }

  // افزودن آموزشگاه جدید
  void addSchool(String school) {
    if (school.trim().isEmpty || state.schools.contains(school)) return;
    state = state.copyWith(schools: [...state.schools, school]);
    _saveToCache();
  }

  // حذف آموزشگاه
  void removeSchool(String school) {
    state = state.copyWith(
      schools: state.schools.where((s) => s != school).toList(),
    );
    _saveToCache();
  }

  // افزودن سرمربی جدید
  void addHeadCoach(String headCoach) {
    if (headCoach.trim().isEmpty || state.headCoaches.contains(headCoach)) {
      return;
    }
    state = state.copyWith(headCoaches: [...state.headCoaches, headCoach]);
    _saveToCache();
  }

  // حذف سرمربی
  void removeHeadCoach(String headCoach) {
    state = state.copyWith(
      headCoaches: state.headCoaches.where((h) => h != headCoach).toList(),
    );
    _saveToCache();
  }

  // ذخیره در کش
  Future<void> _saveToCache() async {
    if (_box == null) return;
    try {
      await _box!.put('grades', state.grades);
      await _box!.put('levels', state.levels);
      await _box!.put('schools', state.schools);
      await _box!.put('headCoaches', state.headCoaches);
    } catch (e) {
      // خطا در ذخیره‌سازی
    }
  }

  // بارگذاری از کش
  Future<void> loadFromCache() async {
    if (_box == null) return;
    try {
      state = state.copyWith(isLoading: true);

      final grades = _box!.get('grades', defaultValue: _getDefaultGrades());
      final levels = _box!.get('levels', defaultValue: _getDefaultLevels());
      final schools = _box!.get('schools', defaultValue: _getDefaultSchools());
      final headCoaches = _box!.get(
        'headCoaches',
        defaultValue: _getDefaultHeadCoaches(),
      );

      state = state.copyWith(
        grades: List<String>.from(grades),
        levels: List<String>.from(levels),
        schools: List<String>.from(schools),
        headCoaches: List<String>.from(headCoaches),
        isLoading: false,
      );
    } catch (e) {
      // در صورت خطا، از داده‌های پیش‌فرض استفاده می‌شود
      state = state.copyWith(isLoading: false);
    }
  }

  // بازنشانی به داده‌های پیش‌فرض
  void resetToDefaults() {
    state = AppDataState(
      grades: _getDefaultGrades(),
      levels: _getDefaultLevels(),
      schools: _getDefaultSchools(),
      headCoaches: _getDefaultHeadCoaches(),
    );
    _saveToCache();
  }
}

// Provider اصلی
final appDataProvider = NotifierProvider<AppDataNotifier, AppDataState>(
  AppDataNotifier.new,
);
