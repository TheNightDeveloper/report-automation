import 'dart:io';
import 'dart:convert';
import 'package:excel/excel.dart';
import '../models/models.dart';

class ExcelImportService {
  // کلمات کلیدی برای تشخیص ستون نام
  static const List<String> nameKeywords = [
    'نام',
    'نام خانوادگی',
    'نام نام خانوادگی',
    'نام و نام خانوادگی',
    'name',
  ];

  /// وارد کردن لیست دانش‌آموزان از فایل (Excel یا CSV)
  Future<List<Student>> importStudentsFromExcel(String filePath) async {
    // بررسی نوع فایل
    if (filePath.toLowerCase().endsWith('.csv')) {
      return _importFromCSV(filePath);
    } else {
      return _importFromExcel(filePath);
    }
  }

  /// وارد کردن از فایل CSV
  Future<List<Student>> _importFromCSV(String filePath) async {
    try {
      final file = File(filePath);
      final contents = await file.readAsString(encoding: utf8);
      final lines = const LineSplitter().convert(contents);

      if (lines.isEmpty) {
        throw Exception('فایل CSV خالی است');
      }

      final students = <Student>[];
      final seenNames = <String>{};

      // تشخیص ردیف header و ستون نام
      int headerRowIndex = -1;
      int nameColumnIndex = -1;

      // جستجو برای header در چند ردیف اول
      for (int i = 0; i < (lines.length < 3 ? lines.length : 3); i++) {
        final parts = lines[i].split(RegExp(r'[,;]'));
        for (int j = 0; j < parts.length; j++) {
          final cellValue = parts[j].trim().toLowerCase();
          for (final keyword in nameKeywords) {
            if (cellValue.contains(keyword.toLowerCase())) {
              headerRowIndex = i;
              nameColumnIndex = j;
              break;
            }
          }
          if (nameColumnIndex >= 0) break;
        }
        if (nameColumnIndex >= 0) break;
      }

      // اگر ستون نام پیدا نشد، از ستون دوم استفاده کن (ستون اول معمولاً ردیف است)
      if (nameColumnIndex == -1) {
        print('ستون نام پیدا نشد. از ستون دوم استفاده می‌شود.');
        nameColumnIndex = 1;
      }

      final startRow = headerRowIndex >= 0 ? headerRowIndex + 1 : 0;

      for (int i = startRow; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        // تقسیم بر اساس کاما یا سمی‌کالن
        final parts = line.split(RegExp(r'[,;]'));
        if (parts.isEmpty || nameColumnIndex >= parts.length) continue;

        // استفاده از ستون تشخیص داده شده
        final name = parts[nameColumnIndex].trim().replaceAll('"', '');

        if (name.isEmpty) continue;

        // بررسی تکراری بودن
        if (seenNames.contains(name)) {
          throw Exception('نام تکراری یافت شد: $name');
        }

        seenNames.add(name);
        students.add(
          Student(
            id: '${DateTime.now().millisecondsSinceEpoch}_$i',
            name: name,
            isCompleted: false,
          ),
        );
      }

      if (students.isEmpty) {
        throw Exception('هیچ نام معتبری در فایل یافت نشد');
      }

      return students;
    } on FileSystemException catch (e) {
      throw Exception('خطا در خواندن فایل: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('فایل CSV نامعتبر یا خراب است');
    }
  }

  /// وارد کردن از فایل Excel
  Future<List<Student>> _importFromExcel(String filePath) async {
    try {
      // خواندن فایل Excel
      final bytes = File(filePath).readAsBytesSync();
      final excel = Excel.decodeBytes(bytes);

      if (excel.tables.isEmpty) {
        throw Exception('فایل Excel خالی است');
      }

      // استفاده از اولین sheet
      final sheet = excel.tables[excel.tables.keys.first];
      if (sheet == null || sheet.rows.isEmpty) {
        throw Exception('Sheet خالی است');
      }

      // تشخیص ستون نام
      int nameColumnIndex = _detectNameColumn(sheet.rows);

      // اگر ستون نام پیدا نشد، از اولین ستون استفاده کن
      if (nameColumnIndex == -1) {
        print(
          'ستون نام با کلمات کلیدی پیدا نشد. از اولین ستون استفاده می‌شود.',
        );
        nameColumnIndex = 0;
      }

      // تشخیص اینکه header در کدام ردیف است
      final headerRowIndex = _findHeaderRowIndex(sheet.rows);
      final startRow = headerRowIndex >= 0 ? headerRowIndex + 1 : 0;

      // استخراج نام‌های دانش‌آموزان
      final students = <Student>[];
      final seenNames = <String>{};

      for (int i = startRow; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];

        if (row.isEmpty || nameColumnIndex >= row.length) {
          continue; // ردیف خالی را رد کن
        }

        final cell = row[nameColumnIndex];
        if (cell == null || cell.value == null) {
          continue; // سلول خالی را رد کن
        }

        final name = cell.value.toString().trim();

        if (name.isEmpty) {
          continue; // نام خالی را رد کن
        }

        // بررسی تکراری بودن
        if (seenNames.contains(name)) {
          throw Exception('نام تکراری یافت شد: $name');
        }

        seenNames.add(name);
        students.add(
          Student(
            id: DateTime.now().millisecondsSinceEpoch.toString() + '_$i',
            name: name,
            isCompleted: false,
          ),
        );
      }

      if (students.isEmpty) {
        throw Exception('هیچ نام معتبری در فایل یافت نشد');
      }

      return students;
    } on FileSystemException catch (e) {
      throw Exception('خطا در خواندن فایل: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('فایل Excel نامعتبر یا خراب است');
    }
  }

  /// تشخیص خودکار ستون نام
  int _detectNameColumn(List<List<Data?>> rows) {
    if (rows.isEmpty) return -1;

    // بررسی چند ردیف اول برای یافتن header
    final maxRowsToCheck = rows.length < 3 ? rows.length : 3;

    for (int rowIndex = 0; rowIndex < maxRowsToCheck; rowIndex++) {
      final row = rows[rowIndex];

      for (int colIndex = 0; colIndex < row.length; colIndex++) {
        final cell = row[colIndex];
        if (cell == null || cell.value == null) continue;

        final cellValue = cell.value.toString().trim().toLowerCase();

        for (final keyword in nameKeywords) {
          if (cellValue.contains(keyword.toLowerCase())) {
            return colIndex;
          }
        }
      }
    }

    return -1; // ستون نام یافت نشد
  }

  /// بررسی اینکه آیا فایل ردیف header دارد و در کدام ردیف است
  int _findHeaderRowIndex(List<List<Data?>> rows) {
    if (rows.isEmpty) return -1;

    // بررسی چند ردیف اول برای یافتن header
    final maxRowsToCheck = rows.length < 3 ? rows.length : 3;

    for (int rowIndex = 0; rowIndex < maxRowsToCheck; rowIndex++) {
      final row = rows[rowIndex];

      // بررسی اینکه آیا این ردیف شامل کلمات کلیدی header است
      for (final cell in row) {
        if (cell == null || cell.value == null) continue;

        final cellValue = cell.value.toString().trim().toLowerCase();

        // کلمات کلیدی header
        final headerKeywords = [
          'ردیف',
          'شماره',
          'نام',
          'row',
          'number',
          'name',
        ];

        for (final keyword in headerKeywords) {
          if (cellValue.contains(keyword.toLowerCase())) {
            return rowIndex;
          }
        }
      }
    }

    return -1; // header یافت نشد
  }

  /// بررسی معتبر بودن فایل Excel
  Future<bool> isValidExcelFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return false;
      }

      final bytes = await file.readAsBytes();
      Excel.decodeBytes(bytes);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// دریافت لیست sheet های موجود در فایل
  Future<List<String>> getSheetNames(String filePath) async {
    try {
      final bytes = File(filePath).readAsBytesSync();
      final excel = Excel.decodeBytes(bytes);
      return excel.tables.keys.toList();
    } catch (e) {
      throw Exception('خطا در خواندن فایل Excel');
    }
  }
}
