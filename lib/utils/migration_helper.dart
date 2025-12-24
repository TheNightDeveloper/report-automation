import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class MigrationHelper {
  /// پاک کردن تمام داده‌های قدیمی
  ///
  /// این متد تمام box های Hive را پاک می‌کند.
  /// فقط در صورت نیاز به شروع از صفر استفاده شود.
  static Future<void> clearAllData() async {
    try {
      // پاک کردن box های اصلی
      await Hive.deleteBoxFromDisk('reportCards');
      await Hive.deleteBoxFromDisk('students');
      await Hive.deleteBoxFromDisk('appData');

      print('✅ تمام داده‌های قدیمی پاک شدند');
    } catch (e) {
      print('❌ خطا در پاک کردن داده‌ها: $e');
    }
  }

  /// بررسی نیاز به migration
  ///
  /// اگر داده‌های قدیمی با ساختار جدید سازگار نباشند، true برمی‌گرداند
  static Future<bool> needsMigration() async {
    try {
      // تلاش برای باز کردن box
      final box = await Hive.openBox('reportCards');

      // اگر box خالی است، نیازی به migration نیست
      if (box.isEmpty) {
        await box.close();
        return false;
      }

      // بررسی ساختار داده‌ها
      // اگر خطا رخ دهد، یعنی نیاز به migration است
      try {
        final firstItem = box.getAt(0);
        await box.close();
        return firstItem == null;
      } catch (e) {
        await box.close();
        return true;
      }
    } catch (e) {
      // اگر box باز نشد، نیازی به migration نیست
      return false;
    }
  }

  /// نمایش دیالوگ تایید برای پاک کردن داده‌ها
  static Future<bool> showClearDataDialog(context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('پاک کردن داده‌های قدیمی'),
        content: const Text(
          'ساختار کارنامه تغییر کرده است.\n\n'
          'برای استفاده از نسخه جدید، باید داده‌های قدیمی پاک شوند.\n\n'
          'توصیه می‌شود قبل از این کار، از کارنامه‌های موجود خروجی Excel یا PDF بگیرید.\n\n'
          'آیا مایل به پاک کردن داده‌های قدیمی هستید؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('انصراف'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('پاک کردن'),
          ),
        ],
      ),
    );

    return result ?? false;
  }
}
