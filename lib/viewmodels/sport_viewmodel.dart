import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../repositories/sport_repository.dart';

// State class برای مدیریت رشته‌های ورزشی
class SportState {
  final List<Sport> sports;
  final Sport? selectedSport;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final String? successMessage;

  SportState({
    this.sports = const [],
    this.selectedSport,
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.successMessage,
  });

  SportState copyWith({
    List<Sport>? sports,
    Sport? selectedSport,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    String? successMessage,
  }) {
    return SportState(
      sports: sports ?? this.sports,
      selectedSport: selectedSport ?? this.selectedSport,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }

  Sport? get defaultSport {
    try {
      return sports.firstWhere((sport) => sport.isDefault);
    } catch (e) {
      return null;
    }
  }
}

// Notifier برای مدیریت رشته‌های ورزشی
class SportNotifier extends Notifier<SportState> {
  late final SportRepository _repository;

  @override
  SportState build() {
    _repository = SportRepository();
    return SportState();
  }

  /// بارگذاری لیست رشته‌های ورزشی
  Future<void> loadSports() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final sports = await _repository.getAllSports();
      // مرتب‌سازی: رشته پیش‌فرض اول، بقیه به ترتیب نام
      sports.sort((a, b) {
        if (a.isDefault && !b.isDefault) return -1;
        if (!a.isDefault && b.isDefault) return 1;
        return a.name.compareTo(b.name);
      });
      state = state.copyWith(sports: sports, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'خطا در بارگذاری رشته‌های ورزشی: ${e.toString()}',
      );
    }
  }

  /// ایجاد رشته ورزشی جدید
  Future<bool> createSport({
    required String name,
    String? description,
    List<Level>? levels,
    List<PerformanceRating>? performanceRatings,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // ایجاد Sport جدید
      final sport = Sport(
        id: 'sport_${DateTime.now().millisecondsSinceEpoch}',
        name: name.trim(),
        description: description?.trim(),
        levels: levels ?? [],
        performanceRatings:
            performanceRatings ?? _getDefaultPerformanceRatings(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isDefault: false,
      );

      // اعتبارسنجی
      final validationError = await _repository.validateSport(sport);
      if (validationError != null) {
        state = state.copyWith(isLoading: false, errorMessage: validationError);
        return false;
      }

      // ذخیره
      await _repository.saveSport(sport);

      // به‌روزرسانی لیست
      await loadSports();

      // به‌روزرسانی selectedSport به رشته جدید ایجاد شده
      state = state.copyWith(
        selectedSport: sport,
        successMessage: 'رشته ورزشی با موفقیت ایجاد شد',
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'خطا در ایجاد رشته ورزشی: ${e.toString()}',
      );
      return false;
    }
  }

  /// به‌روزرسانی رشته ورزشی
  Future<bool> updateSport(Sport sport) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // اعتبارسنجی
      final validationError = await _repository.validateSport(
        sport,
        isUpdate: true,
      );
      if (validationError != null) {
        state = state.copyWith(isLoading: false, errorMessage: validationError);
        return false;
      }

      // به‌روزرسانی
      await _repository.updateSport(sport);

      // به‌روزرسانی لیست
      await loadSports();

      // به‌روزرسانی selectedSport اگر همان sport بود
      if (state.selectedSport?.id == sport.id) {
        state = state.copyWith(selectedSport: sport);
      }

      state = state.copyWith(
        successMessage: 'رشته ورزشی با موفقیت به‌روزرسانی شد',
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'خطا در به‌روزرسانی رشته ورزشی: ${e.toString()}',
      );
      return false;
    }
  }

  /// حذف رشته ورزشی
  Future<bool> deleteSport(String id) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // بررسی وجود کارنامه
      final hasReportCards = await _repository.hasReportCards(id);
      if (hasReportCards) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'این رشته دارای کارنامه است و نمی‌توان آن را حذف کرد',
        );
        return false;
      }

      // حذف
      await _repository.deleteSport(id);

      // به‌روزرسانی لیست
      await loadSports();

      // پاک کردن selectedSport اگر همان sport بود
      if (state.selectedSport?.id == id) {
        state = state.copyWith(selectedSport: null);
      }

      state = state.copyWith(successMessage: 'رشته ورزشی با موفقیت حذف شد');

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'خطا در حذف رشته ورزشی: ${e.toString()}',
      );
      return false;
    }
  }

  /// انتخاب یک رشته ورزشی
  void selectSport(Sport? sport) {
    state = state.copyWith(selectedSport: sport);
  }

  /// دریافت سطوح عملکرد پیش‌فرض
  List<PerformanceRating> _getDefaultPerformanceRatings() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return [
      PerformanceRating(
        id: 'rating_excellent_$timestamp',
        name: 'عالی',
        order: 1,
        color: '#4CAF50',
      ),
      PerformanceRating(
        id: 'rating_good_$timestamp',
        name: 'خوب',
        order: 2,
        color: '#2196F3',
      ),
      PerformanceRating(
        id: 'rating_average_$timestamp',
        name: 'متوسط',
        order: 3,
        color: '#FF9800',
      ),
    ];
  }

  /// پاک کردن پیام‌ها
  void clearMessages() {
    state = state.copyWith(errorMessage: null, successMessage: null);
  }

  /// بررسی وجود کارنامه برای رشته
  Future<bool> checkHasReportCards(String sportId) async {
    return await _repository.hasReportCards(sportId);
  }

  /// ایجاد رشته جدید خالی برای فرم
  void createNewSport() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final newSport = Sport(
      id: 'sport_$timestamp',
      name: '',
      description: null,
      levels: [],
      performanceRatings: _getDefaultPerformanceRatings(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isDefault: false,
    );
    state = state.copyWith(selectedSport: newSport);
  }

  /// به‌روزرسانی اطلاعات پایه رشته
  Future<bool> updateSportBasicInfo({
    required String name,
    String? description,
  }) async {
    if (state.selectedSport == null) return false;

    final updatedSport = state.selectedSport!.copyWith(
      name: name.trim(),
      description: description?.trim(),
      updatedAt: DateTime.now(),
    );

    // اگر رشته جدید است (نام خالی بود)، ایجاد کن
    if (state.selectedSport!.name.isEmpty) {
      return await createSport(
        name: name,
        description: description,
        levels: updatedSport.levels,
        performanceRatings: updatedSport.performanceRatings,
      );
    }

    // در غیر این صورت به‌روزرسانی کن
    return await updateSport(updatedSport);
  }

  // ========== مدیریت سطوح ==========

  /// افزودن سطح جدید
  Future<bool> addLevel(String name) async {
    if (state.selectedSport == null) return false;

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final newLevel = Level(
        id: 'level_$timestamp',
        name: name.trim(),
        order: state.selectedSport!.levels.length + 1,
        techniques: [],
      );

      final updatedLevels = [...state.selectedSport!.levels, newLevel];
      final updatedSport = state.selectedSport!.copyWith(
        levels: updatedLevels,
        updatedAt: DateTime.now(),
      );

      state = state.copyWith(selectedSport: updatedSport);
      await updateSport(updatedSport);

      state = state.copyWith(successMessage: 'سطح با موفقیت اضافه شد');
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'خطا در افزودن سطح: ${e.toString()}',
      );
      return false;
    }
  }

  /// به‌روزرسانی سطح
  Future<bool> updateLevel(String levelId, String name) async {
    if (state.selectedSport == null) return false;

    try {
      final updatedLevels = state.selectedSport!.levels.map((level) {
        if (level.id == levelId) {
          return level.copyWith(name: name.trim());
        }
        return level;
      }).toList();

      final updatedSport = state.selectedSport!.copyWith(
        levels: updatedLevels,
        updatedAt: DateTime.now(),
      );

      state = state.copyWith(selectedSport: updatedSport);
      await updateSport(updatedSport);

      state = state.copyWith(successMessage: 'سطح با موفقیت به‌روزرسانی شد');
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'خطا در به‌روزرسانی سطح: ${e.toString()}',
      );
      return false;
    }
  }

  /// حذف سطح
  Future<bool> deleteLevel(String levelId) async {
    if (state.selectedSport == null) return false;

    try {
      final updatedLevels = state.selectedSport!.levels
          .where((level) => level.id != levelId)
          .toList();

      // به‌روزرسانی order سطوح
      for (int i = 0; i < updatedLevels.length; i++) {
        updatedLevels[i] = updatedLevels[i].copyWith(order: i + 1);
      }

      final updatedSport = state.selectedSport!.copyWith(
        levels: updatedLevels,
        updatedAt: DateTime.now(),
      );

      state = state.copyWith(selectedSport: updatedSport);
      await updateSport(updatedSport);

      state = state.copyWith(successMessage: 'سطح با موفقیت حذف شد');
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'خطا در حذف سطح: ${e.toString()}');
      return false;
    }
  }

  /// تغییر ترتیب سطوح
  Future<bool> reorderLevels(int oldIndex, int newIndex) async {
    if (state.selectedSport == null) return false;

    try {
      final levels = List<Level>.from(state.selectedSport!.levels);

      if (newIndex > oldIndex) {
        newIndex -= 1;
      }

      final level = levels.removeAt(oldIndex);
      levels.insert(newIndex, level);

      // به‌روزرسانی order
      for (int i = 0; i < levels.length; i++) {
        levels[i] = levels[i].copyWith(order: i + 1);
      }

      final updatedSport = state.selectedSport!.copyWith(
        levels: levels,
        updatedAt: DateTime.now(),
      );

      state = state.copyWith(selectedSport: updatedSport);
      await updateSport(updatedSport);

      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'خطا در تغییر ترتیب سطوح: ${e.toString()}',
      );
      return false;
    }
  }

  // ========== مدیریت تکنیک‌ها ==========

  /// افزودن تکنیک جدید
  Future<bool> addTechnique(String levelId, String name) async {
    if (state.selectedSport == null) return false;

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      final updatedLevels = state.selectedSport!.levels.map((level) {
        if (level.id == levelId) {
          final newTechnique = Technique(
            id: 'technique_$timestamp',
            name: name.trim(),
            order: level.techniques.length + 1,
          );
          return level.copyWith(
            techniques: [...level.techniques, newTechnique],
          );
        }
        return level;
      }).toList();

      final updatedSport = state.selectedSport!.copyWith(
        levels: updatedLevels,
        updatedAt: DateTime.now(),
      );

      state = state.copyWith(selectedSport: updatedSport);
      await updateSport(updatedSport);

      state = state.copyWith(successMessage: 'تکنیک با موفقیت اضافه شد');
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'خطا در افزودن تکنیک: ${e.toString()}',
      );
      return false;
    }
  }

  /// به‌روزرسانی تکنیک
  Future<bool> updateTechnique(
    String levelId,
    String techniqueId,
    String name,
  ) async {
    if (state.selectedSport == null) return false;

    try {
      final updatedLevels = state.selectedSport!.levels.map((level) {
        if (level.id == levelId) {
          final updatedTechniques = level.techniques.map((technique) {
            if (technique.id == techniqueId) {
              return technique.copyWith(name: name.trim());
            }
            return technique;
          }).toList();
          return level.copyWith(techniques: updatedTechniques);
        }
        return level;
      }).toList();

      final updatedSport = state.selectedSport!.copyWith(
        levels: updatedLevels,
        updatedAt: DateTime.now(),
      );

      state = state.copyWith(selectedSport: updatedSport);
      await updateSport(updatedSport);

      state = state.copyWith(successMessage: 'تکنیک با موفقیت به‌روزرسانی شد');
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'خطا در به‌روزرسانی تکنیک: ${e.toString()}',
      );
      return false;
    }
  }

  /// حذف تکنیک
  Future<bool> deleteTechnique(String levelId, String techniqueId) async {
    if (state.selectedSport == null) return false;

    try {
      final updatedLevels = state.selectedSport!.levels.map((level) {
        if (level.id == levelId) {
          final updatedTechniques = level.techniques
              .where((technique) => technique.id != techniqueId)
              .toList();

          // به‌روزرسانی order تکنیک‌ها
          for (int i = 0; i < updatedTechniques.length; i++) {
            updatedTechniques[i] = updatedTechniques[i].copyWith(order: i + 1);
          }

          return level.copyWith(techniques: updatedTechniques);
        }
        return level;
      }).toList();

      final updatedSport = state.selectedSport!.copyWith(
        levels: updatedLevels,
        updatedAt: DateTime.now(),
      );

      state = state.copyWith(selectedSport: updatedSport);
      await updateSport(updatedSport);

      state = state.copyWith(successMessage: 'تکنیک با موفقیت حذف شد');
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'خطا در حذف تکنیک: ${e.toString()}');
      return false;
    }
  }

  // ========== مدیریت سطوح عملکرد ==========

  /// افزودن سطح عملکرد جدید
  Future<bool> addPerformanceRating(String name) async {
    if (state.selectedSport == null) return false;

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final newRating = PerformanceRating(
        id: 'rating_$timestamp',
        name: name.trim(),
        order: state.selectedSport!.performanceRatings.length + 1,
        color: '#9E9E9E',
      );

      final updatedRatings = [
        ...state.selectedSport!.performanceRatings,
        newRating,
      ];
      final updatedSport = state.selectedSport!.copyWith(
        performanceRatings: updatedRatings,
        updatedAt: DateTime.now(),
      );

      state = state.copyWith(selectedSport: updatedSport);
      await updateSport(updatedSport);

      state = state.copyWith(successMessage: 'سطح عملکرد با موفقیت اضافه شد');
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'خطا در افزودن سطح عملکرد: ${e.toString()}',
      );
      return false;
    }
  }

  /// به‌روزرسانی سطح عملکرد
  Future<bool> updatePerformanceRating(String ratingId, String name) async {
    if (state.selectedSport == null) return false;

    try {
      final updatedRatings = state.selectedSport!.performanceRatings.map((
        rating,
      ) {
        if (rating.id == ratingId) {
          return rating.copyWith(name: name.trim());
        }
        return rating;
      }).toList();

      final updatedSport = state.selectedSport!.copyWith(
        performanceRatings: updatedRatings,
        updatedAt: DateTime.now(),
      );

      state = state.copyWith(selectedSport: updatedSport);
      await updateSport(updatedSport);

      state = state.copyWith(
        successMessage: 'سطح عملکرد با موفقیت به‌روزرسانی شد',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'خطا در به‌روزرسانی سطح عملکرد: ${e.toString()}',
      );
      return false;
    }
  }

  /// حذف سطح عملکرد
  Future<bool> deletePerformanceRating(String ratingId) async {
    if (state.selectedSport == null) return false;

    try {
      final updatedRatings = state.selectedSport!.performanceRatings
          .where((rating) => rating.id != ratingId)
          .toList();

      // به‌روزرسانی order
      for (int i = 0; i < updatedRatings.length; i++) {
        updatedRatings[i] = updatedRatings[i].copyWith(order: i + 1);
      }

      final updatedSport = state.selectedSport!.copyWith(
        performanceRatings: updatedRatings,
        updatedAt: DateTime.now(),
      );

      state = state.copyWith(selectedSport: updatedSport);
      await updateSport(updatedSport);

      state = state.copyWith(successMessage: 'سطح عملکرد با موفقیت حذف شد');
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'خطا در حذف سطح عملکرد: ${e.toString()}',
      );
      return false;
    }
  }

  /// تغییر ترتیب سطوح عملکرد
  Future<bool> reorderPerformanceRatings(int oldIndex, int newIndex) async {
    if (state.selectedSport == null) return false;

    try {
      final ratings = List<PerformanceRating>.from(
        state.selectedSport!.performanceRatings,
      );

      if (newIndex > oldIndex) {
        newIndex -= 1;
      }

      final rating = ratings.removeAt(oldIndex);
      ratings.insert(newIndex, rating);

      // به‌روزرسانی order
      for (int i = 0; i < ratings.length; i++) {
        ratings[i] = ratings[i].copyWith(order: i + 1);
      }

      final updatedSport = state.selectedSport!.copyWith(
        performanceRatings: ratings,
        updatedAt: DateTime.now(),
      );

      state = state.copyWith(selectedSport: updatedSport);
      await updateSport(updatedSport);

      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'خطا در تغییر ترتیب سطوح عملکرد: ${e.toString()}',
      );
      return false;
    }
  }
}

// Provider اصلی
final sportProvider = NotifierProvider<SportNotifier, SportState>(
  SportNotifier.new,
);
