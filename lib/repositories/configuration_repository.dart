import 'dart:convert';
import '../models/models.dart';
import 'sport_repository.dart';

class ConfigurationRepository {
  final SportRepository _sportRepository;

  ConfigurationRepository(this._sportRepository);

  /// صادرات تنظیمات یک رشته ورزشی به JSON
  Future<String> exportSportConfiguration(String sportId) async {
    final sport = await _sportRepository.getSport(sportId);
    if (sport == null) {
      throw Exception('رشته ورزشی یافت نشد');
    }

    // تبدیل Sport به JSON با تمام جزئیات
    final config = {
      'version': '1.0',
      'exportDate': DateTime.now().toIso8601String(),
      'sport': sport.toJson(),
    };

    return jsonEncode(config);
  }

  /// واردات تنظیمات رشته ورزشی از JSON
  Future<Sport> importSportConfiguration(String jsonData) async {
    try {
      final config = jsonDecode(jsonData) as Map<String, dynamic>;

      // اعتبارسنجی ساختار
      await validateConfiguration(jsonData);

      // استخراج Sport از JSON
      final sportJson = config['sport'] as Map<String, dynamic>;
      final sport = Sport.fromJson(sportJson);

      return sport;
    } catch (e) {
      throw Exception('خطا در پارس فایل تنظیمات: ${e.toString()}');
    }
  }

  /// اعتبارسنجی ساختار JSON
  Future<void> validateConfiguration(String jsonData) async {
    try {
      final config = jsonDecode(jsonData) as Map<String, dynamic>;

      // بررسی وجود فیلدهای ضروری
      if (!config.containsKey('version')) {
        throw Exception('فیلد version یافت نشد');
      }

      if (!config.containsKey('sport')) {
        throw Exception('فیلد sport یافت نشد');
      }

      final sportJson = config['sport'] as Map<String, dynamic>;

      // بررسی فیلدهای ضروری Sport
      if (!sportJson.containsKey('id')) {
        throw Exception('فیلد id در sport یافت نشد');
      }
      if (!sportJson.containsKey('name')) {
        throw Exception('فیلد name در sport یافت نشد');
      }
      if (!sportJson.containsKey('levels')) {
        throw Exception('فیلد levels در sport یافت نشد');
      }
      if (!sportJson.containsKey('performanceRatings')) {
        throw Exception('فیلد performanceRatings در sport یافت نشد');
      }

      // بررسی ساختار levels
      final levels = sportJson['levels'] as List;
      for (final level in levels) {
        final levelMap = level as Map<String, dynamic>;
        if (!levelMap.containsKey('id') ||
            !levelMap.containsKey('name') ||
            !levelMap.containsKey('order') ||
            !levelMap.containsKey('techniques')) {
          throw Exception('ساختار level نامعتبر است');
        }

        // بررسی ساختار techniques
        final techniques = levelMap['techniques'] as List;
        for (final technique in techniques) {
          final techniqueMap = technique as Map<String, dynamic>;
          if (!techniqueMap.containsKey('id') ||
              !techniqueMap.containsKey('name') ||
              !techniqueMap.containsKey('order')) {
            throw Exception('ساختار technique نامعتبر است');
          }
        }
      }

      // بررسی ساختار performanceRatings
      final ratings = sportJson['performanceRatings'] as List;
      for (final rating in ratings) {
        final ratingMap = rating as Map<String, dynamic>;
        if (!ratingMap.containsKey('id') ||
            !ratingMap.containsKey('name') ||
            !ratingMap.containsKey('order')) {
          throw Exception('ساختار performanceRating نامعتبر است');
        }
      }
    } on FormatException {
      throw Exception('فرمت JSON نامعتبر است');
    } catch (e) {
      rethrow;
    }
  }
}
