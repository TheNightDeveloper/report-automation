import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  @override
  AppDataState build() {
    // بارگذاری داده‌های پیش‌فرض
    return AppDataState(
      grades: _getDefaultGrades(),
      levels: _getDefaultLevels(),
      schools: _getDefaultSchools(),
      headCoaches: _getDefaultHeadCoaches(),
    );
  }

  // داده‌های پیش‌فرض مقاطع
  List<String> _getDefaultGrades() {
    return ['پیش دبستانی', 'ابتدایی', 'متوسطه اول', 'متوسطه دوم'];
  }

  // داده‌های پیش‌فرض پایه‌ها
  List<String> _getDefaultLevels() {
    return [
      'سال اول',
      'سال دوم',
      'سال سوم',
      'سال چهارم',
      'سال پنجم',
      'سال ششم',
    ];
  }

  // داده‌های پیش‌فرض آموزشگاه‌ها
  List<String> _getDefaultSchools() {
    return [
      'آموزشگاه شنا ایدا',
      'آموزشگاه شنا دلفین',
      'آموزشگاه شنا آزادی',
      'آموزشگاه شنا انقلاب',
      'سایر',
    ];
  }

  // داده‌های پیش‌فرض سرمربیان
  List<String> _getDefaultHeadCoaches() {
    return [
      'مربی احمدی',
      'مربی محمدی',
      'مربی رضایی',
      'مربی کریمی',
      'مربی حسینی',
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

  // ذخیره در کش (برای آینده)
  Future<void> _saveToCache() async {
    // TODO: پیاده‌سازی ذخیره‌سازی در Hive یا SharedPreferences
    // این متد در آینده برای ذخیره دائمی داده‌ها استفاده می‌شود
  }

  // بارگذاری از کش (برای آینده)
  Future<void> loadFromCache() async {
    // TODO: پیاده‌سازی بارگذاری از Hive یا SharedPreferences
    state = state.copyWith(isLoading: true);
    // بارگذاری داده‌ها
    state = state.copyWith(isLoading: false);
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
