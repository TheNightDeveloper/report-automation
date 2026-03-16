import 'package:uuid/uuid.dart';

class IdGenerator {
  static const _uuid = Uuid();

  /// تولید ID یکتا برای دانش‌آموز
  static String generateStudentId() {
    return _uuid.v4();
  }

  /// تولید ID یکتا برای پوشه
  static String generateFolderId() {
    return _uuid.v4();
  }

  /// تولید ID یکتا برای رشته ورزشی
  static String generateSportId() {
    return 'sport_${_uuid.v4()}';
  }

  /// تولید ID یکتا برای سطح
  static String generateLevelId() {
    return 'level_${_uuid.v4()}';
  }

  /// تولید ID یکتا برای تکنیک
  static String generateTechniqueId() {
    return 'technique_${_uuid.v4()}';
  }

  /// تولید ID یکتا برای رتبه عملکرد
  static String generatePerformanceRatingId() {
    return 'rating_${_uuid.v4()}';
  }
}
