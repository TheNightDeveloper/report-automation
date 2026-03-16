import 'dart:io';
import 'dart:convert';
import 'package:excel/excel.dart';
import '../models/models.dart';
import '../utils/id_generator.dart';

class ExcelImportService {
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

      // شروع از ردیف اول (ستون اول = نام دانش‌آموز)
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        // تقسیم بر اساس کاما یا سمی‌کالن
        final parts = line.split(RegExp(r'[,;]'));

        // باید حداقل 1 ستون داشته باشد: Name
        if (parts.isEmpty) continue;

        final name = parts[0].trim().replaceAll('"', '');

        // بررسی خالی نبودن
        if (name.isEmpty) continue;

        // بررسی تکراری بودن نام
        if (seenNames.contains(name)) {
          throw Exception('نام تکراری یافت شد: $name');
        }

        seenNames.add(name);

        // ساخت ID یکتا با UUID
        final id = IdGenerator.generateStudentId();
        students.add(Student(id: id, name: name, isCompleted: false));
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

      // استخراج نام‌های دانش‌آموزان
      final students = <Student>[];
      final seenNames = <String>{};

      // شروع از ردیف اول (ستون اول = نام دانش‌آموز)
      for (int i = 0; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];

        // باید حداقل 1 ستون داشته باشد: Name
        if (row.isEmpty) {
          continue;
        }

        final nameCell = row[1];

        if (nameCell == null || nameCell.value == null) {
          continue;
        }

        final name = nameCell.value.toString().trim();

        // بررسی خالی نبودن
        if (name.isEmpty) {
          continue;
        }

        // بررسی تکراری بودن نام
        if (seenNames.contains(name)) {
          throw Exception('نام تکراری یافت شد: $name');
        }

        seenNames.add(name);

        // ساخت ID یکتا با UUID
        final id = IdGenerator.generateStudentId();
        students.add(Student(id: id, name: name, isCompleted: false));
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
