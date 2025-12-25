import 'package:hive_flutter/hive_flutter.dart';
import '../models/models.dart';

class SportRepository {
  static const String _boxName = 'sports';
  Box<Sport>? _box;

  Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      _box = await Hive.openBox<Sport>(_boxName);
    } else {
      _box = Hive.box<Sport>(_boxName);
    }
  }

  /// ذخیره یک رشته ورزشی جدید
  Future<void> saveSport(Sport sport) async {
    await init();
    await _box!.put(sport.id, sport);
  }

  /// دریافت یک رشته ورزشی با ID
  Future<Sport?> getSport(String id) async {
    await init();
    return _box!.get(id);
  }

  /// دریافت تمام رشته‌های ورزشی
  Future<List<Sport>> getAllSports() async {
    await init();
    return _box!.values.toList();
  }

  /// به‌روزرسانی یک رشته ورزشی
  Future<void> updateSport(Sport sport) async {
    await init();
    final updatedSport = sport.copyWith(updatedAt: DateTime.now());
    await _box!.put(updatedSport.id, updatedSport);
  }

  /// حذف یک رشته ورزشی
  Future<void> deleteSport(String id) async {
    await init();
    await _box!.delete(id);
  }

  /// بررسی وجود نام رشته ورزشی (case-insensitive)
  Future<bool> sportNameExists(String name, {String? excludeId}) async {
    await init();
    final sports = _box!.values.toList();
    return sports.any(
      (sport) =>
          sport.name.toLowerCase() == name.toLowerCase() &&
          sport.id != excludeId,
    );
  }

  /// اعتبارسنجی رشته ورزشی
  Future<String?> validateSport(Sport sport, {bool isUpdate = false}) async {
    // بررسی نام خالی
    if (sport.name.trim().isEmpty) {
      return 'نام نمی‌تواند خالی باشد';
    }

    // بررسی نام تکراری
    final nameExists = await sportNameExists(
      sport.name,
      excludeId: isUpdate ? sport.id : null,
    );
    if (nameExists) {
      return 'رشته ورزشی با این نام قبلاً وجود دارد';
    }

    // بررسی order های تکراری در levels
    final levelOrders = sport.levels.map((l) => l.order).toList();
    if (levelOrders.length != levelOrders.toSet().length) {
      return 'شماره ترتیب سطوح تکراری است';
    }

    // بررسی order های تکراری در techniques هر level
    for (final level in sport.levels) {
      final techniqueOrders = level.techniques.map((t) => t.order).toList();
      if (techniqueOrders.length != techniqueOrders.toSet().length) {
        return 'شماره ترتیب تکنیک‌ها در سطح "${level.name}" تکراری است';
      }
    }

    // بررسی order های تکراری در performance ratings
    final ratingOrders = sport.performanceRatings.map((r) => r.order).toList();
    if (ratingOrders.length != ratingOrders.toSet().length) {
      return 'شماره ترتیب سطوح عملکرد تکراری است';
    }

    return null; // هیچ خطایی وجود ندارد
  }

  /// دریافت رشته پیش‌فرض (شنا)
  Future<Sport?> getDefaultSport() async {
    await init();
    final sports = _box!.values.toList();
    try {
      return sports.firstWhere((sport) => sport.isDefault);
    } catch (e) {
      return null;
    }
  }

  /// بررسی وجود کارنامه برای یک رشته ورزشی
  Future<bool> hasReportCards(String sportId) async {
    // این متد باید با ReportCardRepository هماهنگ شود
    // فعلاً یک پیاده‌سازی ساده می‌نویسیم
    try {
      final reportCardBox = await Hive.openBox<ReportCard>('report_cards');
      final reportCards = reportCardBox.values.toList();
      return reportCards.any((rc) => rc.sportId == sportId);
    } catch (e) {
      return false;
    }
  }

  /// بستن box
  Future<void> close() async {
    if (_box?.isOpen ?? false) {
      await _box!.close();
    }
  }
}
