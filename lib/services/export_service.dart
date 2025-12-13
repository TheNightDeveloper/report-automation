import 'dart:io';
import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show rootBundle;
import '../models/models.dart';

class ExportService {
  pw.Font? _persianFont;

  /// بارگذاری فونت فارسی
  Future<pw.Font> _loadPersianFont() async {
    if (_persianFont != null) return _persianFont!;

    try {
      // استفاده از فونت Vazir که با زبان فارسی سازگار است
      final fontData = await rootBundle.load(
        'assets/fonts/Vazirmatn-Regular.ttf',
      );
      _persianFont = pw.Font.ttf(fontData);
      return _persianFont!;
    } catch (e) {
      // اگر فونت پیدا نشد، از فونت پیش‌فرض استفاده می‌کنیم
      // اما این فونت فارسی را به درستی نمایش نمی‌دهد
      throw Exception(
        'فونت فارسی یافت نشد. لطفاً فونت را در assets/fonts قرار دهید.',
      );
    }
  }

  /// خروجی PDF برای یک کارنامه
  Future<String> exportToPDF({
    required ReportCard reportCard,
    required String outputDirectory,
  }) async {
    try {
      // بارگذاری فونت فارسی
      final persianFont = await _loadPersianFont();

      // بررسی وجود پوشه خروجی
      final dir = Directory(outputDirectory);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      // ایجاد نام فایل
      final fileName = _sanitizeFileName(reportCard.studentInfo.name);
      final filePath = '$outputDirectory${Platform.pathSeparator}$fileName.pdf';

      // ایجاد سند PDF
      final pdf = pw.Document();

      // افزودن صفحات
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          textDirection: pw.TextDirection.rtl,
          theme: pw.ThemeData.withFont(base: persianFont, bold: persianFont),
          build: (context) => [
            _buildPDFHeader(reportCard),
            pw.SizedBox(height: 20),
            _buildPDFStudentInfo(reportCard.studentInfo),
            pw.SizedBox(height: 15),
            _buildPDFAttendanceInfo(reportCard.attendanceInfo),
            pw.SizedBox(height: 20),
            ..._buildPDFSections(reportCard.sections),
          ],
        ),
      );

      // ذخیره فایل
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      return filePath;
    } catch (e) {
      throw Exception('خطا در ایجاد فایل PDF: ${e.toString()}');
    }
  }

  /// خروجی Excel برای یک کارنامه
  Future<String> exportToExcel({
    required ReportCard reportCard,
    required String outputDirectory,
  }) async {
    try {
      // بررسی وجود پوشه خروجی
      final dir = Directory(outputDirectory);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      // ایجاد نام فایل
      final fileName = _sanitizeFileName(reportCard.studentInfo.name);
      final filePath =
          '$outputDirectory${Platform.pathSeparator}$fileName.xlsx';

      // ایجاد فایل Excel
      final excel = Excel.createExcel();
      final sheet = excel['کارنامه'];

      // افزودن هدر
      int currentRow = 0;
      _addExcelHeader(sheet, currentRow);
      currentRow += 2;

      // افزودن اطلاعات دانش‌آموز
      currentRow = _addExcelStudentInfo(
        sheet,
        reportCard.studentInfo,
        currentRow,
      );
      currentRow += 1;

      // افزودن اطلاعات حضور
      currentRow = _addExcelAttendanceInfo(
        sheet,
        reportCard.attendanceInfo,
        currentRow,
      );
      currentRow += 2;

      // افزودن بخش‌های ارزیابی
      _addExcelSections(sheet, reportCard.sections, currentRow);

      // ذخیره فایل
      final fileBytes = excel.encode();
      if (fileBytes == null) {
        throw Exception('خطا در ایجاد فایل Excel');
      }

      final file = File(filePath);
      await file.writeAsBytes(fileBytes);

      return filePath;
    } catch (e) {
      throw Exception('خطا در ایجاد فایل Excel: ${e.toString()}');
    }
  }

  /// خروجی دسته‌جمعی
  Future<List<String>> batchExport({
    required List<ReportCard> reportCards,
    required String outputDirectory,
    required ExportFormat format,
    Function(int current, int total)? onProgress,
  }) async {
    final exportedFiles = <String>[];

    for (int i = 0; i < reportCards.length; i++) {
      try {
        final filePath = format == ExportFormat.pdf
            ? await exportToPDF(
                reportCard: reportCards[i],
                outputDirectory: outputDirectory,
              )
            : await exportToExcel(
                reportCard: reportCards[i],
                outputDirectory: outputDirectory,
              );

        exportedFiles.add(filePath);
        onProgress?.call(i + 1, reportCards.length);
      } catch (e) {
        // ادامه export حتی در صورت خطا برای یک کارنامه
        print('خطا در export کارنامه ${reportCards[i].studentInfo.name}: $e');
      }
    }

    if (exportedFiles.isEmpty) {
      throw Exception('هیچ فایلی export نشد');
    }

    return exportedFiles;
  }

  // ========== متدهای کمکی PDF ==========

  pw.Widget _buildPDFHeader(ReportCard reportCard) {
    return pw.Container(
      alignment: pw.Alignment.center,
      child: pw.Column(
        children: [
          pw.Text(
            'کارنامه الکترونیکی',
            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 5),
          pw.Text('آموزشگاه شنا', style: pw.TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  pw.Widget _buildPDFStudentInfo(StudentInfo info) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildPDFInfoRow('نام دانش‌آموز:', info.name),
          _buildPDFInfoRow('مقطع:', info.grade ?? '-'),
          _buildPDFInfoRow('پایه:', info.level ?? '-'),
          _buildPDFInfoRow('آموزشگاه:', info.school ?? '-'),
          _buildPDFInfoRow('سرمربی:', info.headCoach ?? '-'),
        ],
      ),
    );
  }

  pw.Widget _buildPDFAttendanceInfo(AttendanceInfo info) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildPDFInfoRow('تعداد جلسات:', info.totalSessions.toString()),
          _buildPDFInfoRow('جلسات حاضر:', info.attendedSessions.toString()),
          _buildPDFInfoRow('ردیف عملکرد:', info.performanceRank.toString()),
        ],
      ),
    );
  }

  pw.Widget _buildPDFInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        children: [
          pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(width: 10),
          pw.Text(value),
        ],
      ),
    );
  }

  List<pw.Widget> _buildPDFSections(Map<String, SectionEvaluation> sections) {
    final widgets = <pw.Widget>[];

    for (final section in sections.values) {
      widgets.add(
        pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 15),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                section.sectionName,
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.TableHelper.fromTextArray(
                headers: ['ردیف', 'تکنیک', 'سطح عملکرد'],
                data: section.techniques.map((tech) {
                  return [
                    tech.number.toString(),
                    tech.techniqueName,
                    tech.level?.persianName ?? '-',
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                cellAlignment: pw.Alignment.centerRight,
                headerAlignment: pw.Alignment.center,
                border: pw.TableBorder.all(color: PdfColors.grey),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.grey300,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return widgets;
  }

  // ========== متدهای کمکی Excel ==========

  void _addExcelHeader(Sheet sheet, int row) {
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
      ..value = TextCellValue('کارنامه الکترونیکی - آموزشگاه شنا')
      ..cellStyle = CellStyle(
        bold: true,
        fontSize: 16,
        horizontalAlign: HorizontalAlign.Center,
      );
  }

  int _addExcelStudentInfo(Sheet sheet, StudentInfo info, int startRow) {
    int row = startRow;

    _addExcelRow(sheet, row++, 'نام دانش‌آموز:', info.name);
    _addExcelRow(sheet, row++, 'مقطع:', info.grade ?? '-');
    _addExcelRow(sheet, row++, 'پایه:', info.level ?? '-');
    _addExcelRow(sheet, row++, 'آموزشگاه:', info.school ?? '-');
    _addExcelRow(sheet, row++, 'سرمربی:', info.headCoach ?? '-');

    return row;
  }

  int _addExcelAttendanceInfo(Sheet sheet, AttendanceInfo info, int startRow) {
    int row = startRow;

    _addExcelRow(sheet, row++, 'تعداد جلسات:', info.totalSessions.toString());
    _addExcelRow(sheet, row++, 'جلسات حاضر:', info.attendedSessions.toString());
    _addExcelRow(sheet, row++, 'ردیف عملکرد:', info.performanceRank.toString());

    return row;
  }

  void _addExcelSections(
    Sheet sheet,
    Map<String, SectionEvaluation> sections,
    int startRow,
  ) {
    int row = startRow;

    for (final section in sections.values) {
      // عنوان بخش
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        ..value = TextCellValue(section.sectionName)
        ..cellStyle = CellStyle(bold: true, fontSize: 14);
      row += 2;

      // هدر جدول
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        ..value = TextCellValue('ردیف')
        ..cellStyle = CellStyle(bold: true);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
        ..value = TextCellValue('تکنیک')
        ..cellStyle = CellStyle(bold: true);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
        ..value = TextCellValue('سطح عملکرد')
        ..cellStyle = CellStyle(bold: true);
      row++;

      // تکنیک‌ها
      for (final tech in section.techniques) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
            .value = IntCellValue(
          tech.number,
        );
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
            .value = TextCellValue(
          tech.techniqueName,
        );
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
            .value = TextCellValue(
          tech.level?.persianName ?? '-',
        );
        row++;
      }

      row += 2; // فاصله بین بخش‌ها
    }
  }

  void _addExcelRow(Sheet sheet, int row, String label, String value) {
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
      ..value = TextCellValue(label)
      ..cellStyle = CellStyle(bold: true);
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
        .value = TextCellValue(
      value,
    );
  }

  // ========== متدهای کمکی عمومی ==========

  /// پاکسازی نام فایل از کاراکترهای غیرمجاز
  String _sanitizeFileName(String name) {
    return name
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .trim();
  }

  /// بررسی معتبر بودن مسیر خروجی
  Future<bool> isValidOutputDirectory(String path) async {
    try {
      final dir = Directory(path);
      return await dir.exists() || await dir.parent.exists();
    } catch (e) {
      return false;
    }
  }

  /// محاسبه حجم تقریبی فایل خروجی (به بایت)
  int estimateFileSize(ReportCard reportCard, ExportFormat format) {
    // تخمین تقریبی بر اساس تعداد داده‌ها
    final baseSize = format == ExportFormat.pdf
        ? 50000
        : 20000; // 50KB for PDF, 20KB for Excel
    final techniqueCount = reportCard.sections.values.fold<int>(
      0,
      (sum, section) => sum + section.techniques.length,
    );
    return baseSize + (techniqueCount * 100);
  }
}

enum ExportFormat { pdf, excel }
