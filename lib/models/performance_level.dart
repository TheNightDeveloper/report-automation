enum PerformanceLevel {
  excellent, // عالی
  good, // خوب
  average, // متوسط
}

extension PerformanceLevelExtension on PerformanceLevel {
  String get persianName {
    switch (this) {
      case PerformanceLevel.excellent:
        return 'عالی';
      case PerformanceLevel.good:
        return 'خوب';
      case PerformanceLevel.average:
        return 'متوسط';
    }
  }

  static PerformanceLevel? fromString(String? value) {
    if (value == null) return null;
    switch (value) {
      case 'excellent':
      case 'عالی':
        return PerformanceLevel.excellent;
      case 'good':
      case 'خوب':
        return PerformanceLevel.good;
      case 'average':
      case 'متوسط':
        return PerformanceLevel.average;
      default:
        return null;
    }
  }
}
