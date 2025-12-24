import 'dart:io';
import 'dart:ui';
import 'package:flutter/services.dart' show rootBundle;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import '../models/models.dart';
import '../utils/report_card_template.dart';

class ExportService {
  List<int>? _fontData;
  List<int>? _fontBoldData;
  List<int>? _logoData;

  /// تبدیل اعداد انگلیسی به فارسی
  String _toPersianNumber(dynamic number) {
    if (number == null) return '';
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const persian = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];

    String str = number.toString();
    for (int i = 0; i < english.length; i++) {
      str = str.replaceAll(english[i], persian[i]);
    }
    return str;
  }

  /// بارگذاری فونت فارسی
  Future<List<int>> _loadPersianFont() async {
    if (_fontData != null) return _fontData!;
    final fontData = await rootBundle.load(
      'assets/fonts/Vazirmatn-Regular.ttf',
    );
    _fontData = fontData.buffer.asUint8List();
    return _fontData!;
  }

  /// بارگذاری فونت بولد فارسی
  Future<List<int>> _loadPersianBoldFont() async {
    if (_fontBoldData != null) return _fontBoldData!;
    final fontData = await rootBundle.load('assets/fonts/Vazirmatn-Bold.ttf');
    _fontBoldData = fontData.buffer.asUint8List();
    return _fontBoldData!;
  }

  /// بارگذاری لوگو
  Future<List<int>?> _loadLogo() async {
    if (_logoData != null) return _logoData;
    try {
      final logoData = await rootBundle.load('assets/image/logo.png');
      _logoData = logoData.buffer.asUint8List();
      return _logoData;
    } catch (e) {
      return null;
    }
  }

  /// خروجی PDF برای یک کارنامه
  Future<String> exportToPDF({
    required ReportCard reportCard,
    required String outputDirectory,
  }) async {
    try {
      final fontData = await _loadPersianFont();
      final fontBoldData = await _loadPersianBoldFont();
      final logoData = await _loadLogo();

      final dir = Directory(outputDirectory);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      final fileName = _sanitizeFileName(reportCard.studentInfo.name);
      final filePath = '$outputDirectory${Platform.pathSeparator}$fileName.pdf';

      // ایجاد سند PDF
      final PdfDocument document = PdfDocument();
      document.pageSettings.size = PdfPageSize.a4;
      document.pageSettings.margins.all = 20;

      // ایجاد فونت‌ها
      final PdfFont font = PdfTrueTypeFont(fontData, 9);
      final PdfFont fontBold = PdfTrueTypeFont(fontBoldData, 9);
      final PdfFont fontSmall = PdfTrueTypeFont(fontData, 7);
      final PdfFont fontSmallBold = PdfTrueTypeFont(fontBoldData, 7);
      final PdfFont fontTitle = PdfTrueTypeFont(fontBoldData, 16);

      // اضافه کردن صفحه
      PdfPage page = document.pages.add();
      PdfGraphics graphics = page.graphics;
      final double pageWidth = page.getClientSize().width;

      double yPos = 0;

      // هدر با لوگو
      yPos = _drawHeader(graphics, pageWidth, fontTitle, font, logoData, yPos);
      yPos += 15;

      // اطلاعات دانش‌آموز
      yPos = _drawStudentInfo(
        graphics,
        pageWidth,
        fontBold,
        font,
        reportCard.studentInfo,
        yPos,
      );
      yPos += 10;

      // اطلاعات حضور
      yPos = _drawAttendanceInfo(
        graphics,
        pageWidth,
        fontBold,
        font,
        reportCard.attendanceInfo,
        yPos,
      );
      yPos += 15;

      // جدول‌های سطوح
      yPos = _drawAllSections(
        document,
        page,
        graphics,
        pageWidth,
        fontSmallBold,
        fontSmall,
        reportCard.sections,
        yPos,
      );

      // توضیحات و امضا
      if ((reportCard.comments != null && reportCard.comments!.isNotEmpty) ||
          (reportCard.signatureImagePath != null &&
              reportCard.signatureImagePath!.isNotEmpty)) {
        yPos += 10;

        // بررسی فضای کافی برای باکس توضیحات
        final double boxHeight = reportCard.signatureImagePath != null
            ? 80
            : 50;
        final double pageHeight = page.getClientSize().height;

        if (yPos + boxHeight > pageHeight - 20) {
          // صفحه جدید اضافه کن
          page = document.pages.add();
          graphics = page.graphics;
          yPos = 0;
        }

        _drawComments(
          graphics,
          pageWidth,
          fontBold,
          font,
          reportCard.comments ?? '',
          yPos,
          signatureImagePath: reportCard.signatureImagePath,
        );
      }

      // ذخیره فایل
      final List<int> bytes = await document.save();
      document.dispose();

      final file = File(filePath);
      await file.writeAsBytes(bytes);

      return filePath;
    } catch (e) {
      throw Exception('خطا در ایجاد فایل PDF: ${e.toString()}');
    }
  }

  double _drawHeader(
    PdfGraphics graphics,
    double pageWidth,
    PdfFont fontTitle,
    PdfFont font,
    List<int>? logoData,
    double yPos,
  ) {
    // لوگو در سمت راست (RTL)
    if (logoData != null) {
      final PdfBitmap logo = PdfBitmap(logoData);
      graphics.drawImage(logo, Rect.fromLTWH(pageWidth - 60, yPos, 50, 50));
    }

    // عنوان در وسط
    final PdfStringFormat centerFormat = PdfStringFormat(
      alignment: PdfTextAlignment.center,
      textDirection: PdfTextDirection.rightToLeft,
    );

    graphics.drawString(
      'کارنامه الکترونیکی',
      fontTitle,
      bounds: Rect.fromLTWH(0, yPos + 10, pageWidth, 25),
      format: centerFormat,
    );

    return yPos + 55;
  }

  double _drawStudentInfo(
    PdfGraphics graphics,
    double pageWidth,
    PdfFont fontBold,
    PdfFont font,
    StudentInfo info,
    double yPos,
  ) {
    final PdfStringFormat rtlFormat = PdfStringFormat(
      alignment: PdfTextAlignment.right,
      textDirection: PdfTextDirection.rightToLeft,
    );

    graphics.drawRectangle(
      pen: PdfPen(PdfColor(150, 150, 150)),
      bounds: Rect.fromLTWH(0, yPos, pageWidth, 70),
    );

    double textY = yPos + 5;
    const double lineHeight = 13;

    graphics.drawString(
      'نام و نام خانوادگی: ${info.name}',
      font,
      bounds: Rect.fromLTWH(5, textY, pageWidth - 10, 15),
      format: rtlFormat,
    );
    textY += lineHeight;
    graphics.drawString(
      'مقطع: ${info.grade ?? "-"}',
      font,
      bounds: Rect.fromLTWH(5, textY, pageWidth - 10, 15),
      format: rtlFormat,
    );
    textY += lineHeight;
    graphics.drawString(
      'پایه: ${info.level ?? "-"}',
      font,
      bounds: Rect.fromLTWH(5, textY, pageWidth - 10, 15),
      format: rtlFormat,
    );
    textY += lineHeight;
    graphics.drawString(
      'آموزشگاه: ${info.school ?? "-"}',
      font,
      bounds: Rect.fromLTWH(5, textY, pageWidth - 10, 15),
      format: rtlFormat,
    );
    textY += lineHeight;
    graphics.drawString(
      'سرمربی: ${info.headCoach ?? "-"}',
      font,
      bounds: Rect.fromLTWH(5, textY, pageWidth - 10, 15),
      format: rtlFormat,
    );

    return yPos + 70;
  }

  double _drawAttendanceInfo(
    PdfGraphics graphics,
    double pageWidth,
    PdfFont fontBold,
    PdfFont font,
    AttendanceInfo info,
    double yPos,
  ) {
    final PdfStringFormat rtlFormat = PdfStringFormat(
      alignment: PdfTextAlignment.right,
      textDirection: PdfTextDirection.rightToLeft,
    );

    graphics.drawRectangle(
      pen: PdfPen(PdfColor(150, 150, 150)),
      bounds: Rect.fromLTWH(0, yPos, pageWidth, 45),
    );

    double textY = yPos + 5;
    const double lineHeight = 13;

    graphics.drawString(
      'تعداد جلسات: ${_toPersianNumber(info.totalSessions)}',
      font,
      bounds: Rect.fromLTWH(5, textY, pageWidth - 10, 15),
      format: rtlFormat,
    );
    textY += lineHeight;
    graphics.drawString(
      'جلسات حاضر: ${_toPersianNumber(info.attendedSessions)}',
      font,
      bounds: Rect.fromLTWH(5, textY, pageWidth - 10, 15),
      format: rtlFormat,
    );
    textY += lineHeight;
    graphics.drawString(
      'سطح عملکرد: ${info.performanceLevel ?? "-"}',
      font,
      bounds: Rect.fromLTWH(5, textY, pageWidth - 10, 15),
      format: rtlFormat,
    );

    return yPos + 45;
  }

  double _drawAllSections(
    PdfDocument document,
    PdfPage initialPage,
    PdfGraphics initialGraphics,
    double pageWidth,
    PdfFont fontBold,
    PdfFont font,
    Map<String, SectionEvaluation> sections,
    double yPos,
  ) {
    final colors = [
      PdfColor(219, 234, 254),
      PdfColor(220, 252, 231),
      PdfColor(254, 243, 199),
      PdfColor(243, 232, 255),
      PdfColor(204, 251, 241),
      PdfColor(252, 231, 243),
      PdfColor(254, 249, 195),
    ];

    int colorIndex = 0;
    PdfPage currentPage = initialPage;
    PdfGraphics g = initialGraphics;
    double pageHeight = currentPage.getClientSize().height;

    for (final section in sections.values) {
      final sectionTitle = ReportCardTemplate.getSectionTitle(
        section.sectionName,
      );
      final bgColor = colors[colorIndex % colors.length];
      final techniques = section.techniques;

      // بررسی فضای کافی (حدود 75 پیکسل برای هر سطح)
      if (yPos + 75 > pageHeight - 20) {
        currentPage = document.pages.add();
        g = currentPage.graphics;
        yPos = 0;
      }

      // عنوان سطح
      g.drawRectangle(
        brush: PdfSolidBrush(bgColor),
        pen: PdfPen(PdfColor(120, 120, 120), width: 0.5),
        bounds: Rect.fromLTWH(0, yPos, pageWidth, 16),
      );

      String titleText = sectionTitle.isNotEmpty
          ? '${section.sectionName} - $sectionTitle'
          : section.sectionName;

      g.drawString(
        titleText,
        fontBold,
        bounds: Rect.fromLTWH(5, yPos + 2, pageWidth - 10, 14),
        format: PdfStringFormat(
          alignment: PdfTextAlignment.right,
          textDirection: PdfTextDirection.rightToLeft,
        ),
      );

      yPos += 16;

      // رسم جدول 3×3
      yPos = _drawGrid(g, pageWidth, fontBold, font, techniques, yPos);
      yPos += 5;
      colorIndex++;
    }

    return yPos;
  }

  double _drawGrid(
    PdfGraphics g,
    double pageWidth,
    PdfFont fontBold,
    PdfFont font,
    List<TechniqueEvaluation> techniques,
    double yPos,
  ) {
    const double rowHeight = 14;
    const double headerHeight = 13;
    final double groupWidth = pageWidth / 3;
    final double numW = groupWidth * 0.12;
    final double techW = groupWidth * 0.48;
    final double lvlW = groupWidth * 0.133;

    final centerFmt = PdfStringFormat(
      alignment: PdfTextAlignment.center,
      textDirection: PdfTextDirection.rightToLeft,
    );
    final rtlFmt = PdfStringFormat(
      alignment: PdfTextAlignment.right,
      textDirection: PdfTextDirection.rightToLeft,
    );

    // هدر
    g.drawRectangle(
      brush: PdfSolidBrush(PdfColor(229, 231, 235)),
      pen: PdfPen(PdfColor(150, 150, 150), width: 0.5),
      bounds: Rect.fromLTWH(0, yPos, pageWidth, headerHeight),
    );

    // هدر 3 گروه - RTL (گروه 0 سمت راست، گروه 2 سمت چپ)
    for (int grp = 0; grp < 3; grp++) {
      // گروه 0 در سمت راست صفحه (x بزرگتر)
      final double gx = (2 - grp) * groupWidth;
      g.drawString(
        'ردیف',
        fontBold,
        bounds: Rect.fromLTWH(
          gx + groupWidth - numW,
          yPos + 1,
          numW,
          headerHeight,
        ),
        format: centerFmt,
      );
      g.drawString(
        'تکنیک',
        fontBold,
        bounds: Rect.fromLTWH(gx + lvlW * 3, yPos + 1, techW, headerHeight),
        format: centerFmt,
      );
      g.drawString(
        'عالی',
        fontBold,
        bounds: Rect.fromLTWH(gx + lvlW * 2, yPos + 1, lvlW, headerHeight),
        format: centerFmt,
      );
      g.drawString(
        'خوب',
        fontBold,
        bounds: Rect.fromLTWH(gx + lvlW, yPos + 1, lvlW, headerHeight),
        format: centerFmt,
      );
      g.drawString(
        'متوسط',
        fontBold,
        bounds: Rect.fromLTWH(gx, yPos + 1, lvlW, headerHeight),
        format: centerFmt,
      );
    }

    yPos += headerHeight;

    // رسم خطوط عمودی جداکننده بین گروه‌ها و ستون‌ها
    final double gridHeight = headerHeight + (3 * rowHeight);
    final double gridStartY = yPos - headerHeight;

    // خطوط بین 3 گروه اصلی
    for (int i = 1; i < 3; i++) {
      final double x = i * groupWidth;
      g.drawLine(
        PdfPen(PdfColor(150, 150, 150), width: 1),
        Offset(x, gridStartY),
        Offset(x, gridStartY + gridHeight),
      );
    }

    // خطوط داخل هر گروه (بین ستون‌ها)
    for (int grp = 0; grp < 3; grp++) {
      final double gx = grp * groupWidth;
      // خط بین متوسط و خوب
      g.drawLine(
        PdfPen(PdfColor(180, 180, 180), width: 0.5),
        Offset(gx + lvlW, gridStartY),
        Offset(gx + lvlW, gridStartY + gridHeight),
      );
      // خط بین خوب و عالی
      g.drawLine(
        PdfPen(PdfColor(180, 180, 180), width: 0.5),
        Offset(gx + lvlW * 2, gridStartY),
        Offset(gx + lvlW * 2, gridStartY + gridHeight),
      );
      // خط بین عالی و تکنیک
      g.drawLine(
        PdfPen(PdfColor(180, 180, 180), width: 0.5),
        Offset(gx + lvlW * 3, gridStartY),
        Offset(gx + lvlW * 3, gridStartY + gridHeight),
      );
      // خط بین تکنیک و ردیف
      g.drawLine(
        PdfPen(PdfColor(180, 180, 180), width: 0.5),
        Offset(gx + lvlW * 3 + techW, gridStartY),
        Offset(gx + lvlW * 3 + techW, gridStartY + gridHeight),
      );
    }

    // 3 ردیف داده
    for (int row = 0; row < 3; row++) {
      g.drawRectangle(
        pen: PdfPen(PdfColor(180, 180, 180), width: 0.5),
        bounds: Rect.fromLTWH(0, yPos, pageWidth, rowHeight),
      );

      for (int grp = 0; grp < 3; grp++) {
        // محاسبه صحیح ایندکس: گروه 0 شامل تکنیک‌های 0,1,2 - گروه 1 شامل 3,4,5 - گروه 2 شامل 6,7,8
        final int idx = grp * 3 + row;
        // گروه 0 در سمت راست صفحه (x بزرگتر)
        final double gx = (2 - grp) * groupWidth;

        if (idx < techniques.length) {
          final tech = techniques[idx];

          // ردیف
          g.drawString(
            _toPersianNumber(tech.number),
            font,
            bounds: Rect.fromLTWH(
              gx + groupWidth - numW,
              yPos + 2,
              numW,
              rowHeight,
            ),
            format: centerFmt,
          );

          // تکنیک
          g.drawString(
            tech.techniqueName,
            font,
            bounds: Rect.fromLTWH(
              gx + lvlW * 3 + 2,
              yPos + 2,
              techW - 4,
              rowHeight,
            ),
            format: rtlFmt,
          );

          // علامت سطح - رسم دایره پر شده
          if (tech.level == PerformanceLevel.excellent) {
            final double cx = gx + lvlW * 2 + lvlW / 2;
            final double cy = yPos + rowHeight / 2;
            g.drawEllipse(
              Rect.fromCenter(center: Offset(cx, cy), width: 6, height: 6),
              brush: PdfSolidBrush(PdfColor(22, 163, 74)),
            );
          } else if (tech.level == PerformanceLevel.good) {
            final double cx = gx + lvlW + lvlW / 2;
            final double cy = yPos + rowHeight / 2;
            g.drawEllipse(
              Rect.fromCenter(center: Offset(cx, cy), width: 6, height: 6),
              brush: PdfSolidBrush(PdfColor(37, 99, 235)),
            );
          } else if (tech.level == PerformanceLevel.average) {
            final double cx = gx + lvlW / 2;
            final double cy = yPos + rowHeight / 2;
            g.drawEllipse(
              Rect.fromCenter(center: Offset(cx, cy), width: 6, height: 6),
              brush: PdfSolidBrush(PdfColor(234, 88, 12)),
            );
          }
        }
      }
      yPos += rowHeight;
    }

    return yPos;
  }

  void _drawComments(
    PdfGraphics g,
    double pageWidth,
    PdfFont fontBold,
    PdfFont font,
    String comments,
    double yPos, {
    String? signatureImagePath,
  }) {
    // ارتفاع باکس بسته به وجود امضا
    final double boxHeight = signatureImagePath != null ? 80 : 50;

    g.drawRectangle(
      pen: PdfPen(PdfColor(150, 150, 150)),
      bounds: Rect.fromLTWH(0, yPos, pageWidth, boxHeight),
    );

    final rtlFmt = PdfStringFormat(
      alignment: PdfTextAlignment.right,
      textDirection: PdfTextDirection.rightToLeft,
    );

    g.drawString(
      'توضیحات:',
      fontBold,
      bounds: Rect.fromLTWH(5, yPos + 5, pageWidth - 10, 15),
      format: rtlFmt,
    );
    g.drawString(
      comments,
      font,
      bounds: Rect.fromLTWH(5, yPos + 20, pageWidth - 10, 25),
      format: rtlFmt,
    );

    // نمایش امضا در سمت چپ پایین باکس
    if (signatureImagePath != null && signatureImagePath.isNotEmpty) {
      print('DEBUG: Trying to load signature from: $signatureImagePath');
      try {
        final signatureFile = File(signatureImagePath);
        print('DEBUG: File exists: ${signatureFile.existsSync()}');
        if (signatureFile.existsSync()) {
          final signatureBytes = signatureFile.readAsBytesSync();
          print('DEBUG: Signature bytes length: ${signatureBytes.length}');
          final signatureImage = PdfBitmap(signatureBytes);
          print('DEBUG: PdfBitmap created successfully');

          // رسم امضا در گوشه چپ پایین
          final double signatureWidth = 60;
          final double signatureHeight = 30;
          final double signatureX = 10;
          final double signatureY = yPos + boxHeight - signatureHeight - 5;

          g.drawImage(
            signatureImage,
            Rect.fromLTWH(
              signatureX,
              signatureY,
              signatureWidth,
              signatureHeight,
            ),
          );
          print('DEBUG: Signature drawn successfully');

          // برچسب امضا
          g.drawString(
            'امضا:',
            font,
            bounds: Rect.fromLTWH(
              signatureX,
              signatureY - 12,
              signatureWidth,
              12,
            ),
            format: PdfStringFormat(
              alignment: PdfTextAlignment.left,
              textDirection: PdfTextDirection.rightToLeft,
            ),
          );
        } else {
          print('DEBUG: Signature file does not exist');
        }
      } catch (e) {
        // در صورت خطا در بارگذاری تصویر، فقط متن نمایش داده می‌شود
        print('خطا در بارگذاری تصویر امضا: $e');
      }
    } else {
      print('DEBUG: No signature path provided or empty');
    }
  }

  // ========== Excel Export با Syncfusion ==========

  Future<String> exportToExcel({
    required ReportCard reportCard,
    required String outputDirectory,
  }) async {
    try {
      final dir = Directory(outputDirectory);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      final fileName = _sanitizeFileName(reportCard.studentInfo.name);
      final filePath =
          '$outputDirectory${Platform.pathSeparator}$fileName.xlsx';

      // ایجاد Workbook جدید
      final xlsio.Workbook workbook = xlsio.Workbook();
      final xlsio.Worksheet sheet = workbook.worksheets[0];
      sheet.name = 'کارنامه';
      sheet.isRightToLeft = true;

      // تنظیم عرض ستون‌ها
      for (int i = 1; i <= 16; i++) {
        sheet.getRangeByIndex(1, i).columnWidth = 12;
      }

      int currentRow = 1;

      // ===== هدر =====
      final xlsio.Range headerRange = sheet.getRangeByIndex(
        currentRow,
        1,
        currentRow,
        16,
      );
      headerRange.merge();
      headerRange.setText('کارنامه الکترونیکی');
      headerRange.cellStyle.fontSize = 18;
      headerRange.cellStyle.bold = true;
      headerRange.cellStyle.hAlign = xlsio.HAlignType.center;
      headerRange.cellStyle.vAlign = xlsio.VAlignType.center;
      headerRange.cellStyle.backColor = '#2196F3';
      headerRange.cellStyle.fontColor = '#FFFFFF';
      headerRange.rowHeight = 35;
      currentRow += 2;

      // ===== اطلاعات دانش‌آموز =====
      _addExcelInfoRow(
        sheet,
        currentRow,
        'نام و نام خانوادگی:',
        reportCard.studentInfo.name,
        1,
        4,
      );
      _addExcelInfoRow(
        sheet,
        currentRow,
        'مقطع:',
        reportCard.studentInfo.grade ?? '-',
        6,
        8,
      );
      _addExcelInfoRow(
        sheet,
        currentRow,
        'پایه:',
        reportCard.studentInfo.level ?? '-',
        10,
        12,
      );
      _addExcelInfoRow(
        sheet,
        currentRow,
        'آموزشگاه:',
        reportCard.studentInfo.school ?? '-',
        14,
        16,
      );
      currentRow++;

      _addExcelInfoRow(
        sheet,
        currentRow,
        'سرمربی:',
        reportCard.studentInfo.headCoach ?? '-',
        1,
        4,
      );
      _addExcelInfoRow(
        sheet,
        currentRow,
        'تعداد جلسات:',
        _toPersianNumber(reportCard.attendanceInfo.totalSessions ?? '-'),
        6,
        8,
      );
      _addExcelInfoRow(
        sheet,
        currentRow,
        'جلسات حاضر:',
        _toPersianNumber(reportCard.attendanceInfo.attendedSessions ?? '-'),
        10,
        12,
      );
      _addExcelInfoRow(
        sheet,
        currentRow,
        'سطح عملکرد:',
        reportCard.attendanceInfo.performanceLevel ?? '-',
        14,
        16,
      );
      currentRow += 2;

      // ===== جدول‌های سطوح =====
      final sectionNames = ReportCardTemplate.getSectionNames();
      final colors = [
        '#BBDEFB',
        '#C8E6C9',
        '#FFE0B2',
        '#E1BEE7',
        '#B2DFDB',
        '#F8BBD9',
        '#FFF9C4',
      ];

      for (
        int sectionIndex = 0;
        sectionIndex < sectionNames.length;
        sectionIndex++
      ) {
        final section = reportCard.sections[sectionNames[sectionIndex]];
        if (section == null) continue;

        final sectionTitle = ReportCardTemplate.getSectionTitle(
          section.sectionName,
        );
        final bgColor = colors[sectionIndex % colors.length];

        // عنوان سطح
        final xlsio.Range sectionHeader = sheet.getRangeByIndex(
          currentRow,
          1,
          currentRow,
          16,
        );
        sectionHeader.merge();
        sectionHeader.setText('${section.sectionName} - $sectionTitle');
        sectionHeader.cellStyle.bold = true;
        sectionHeader.cellStyle.fontSize = 11;
        sectionHeader.cellStyle.hAlign = xlsio.HAlignType.right;
        sectionHeader.cellStyle.vAlign = xlsio.VAlignType.center;
        sectionHeader.cellStyle.backColor = bgColor;
        sectionHeader.rowHeight = 22;
        currentRow++;

        // هدر جدول - 3 گروه
        _addExcelTableHeader(sheet, currentRow, 1);
        _addExcelTableHeader(sheet, currentRow, 6);
        _addExcelTableHeader(sheet, currentRow, 11);
        sheet.getRangeByIndex(currentRow, 1, currentRow, 16).rowHeight = 18;
        currentRow++;

        // داده‌های تکنیک‌ها - 3 ردیف
        for (int row = 0; row < 3; row++) {
          // گروه 1 (تکنیک 0-2)
          _addExcelTechniqueRow(sheet, currentRow, 1, section.techniques, row);
          // گروه 2 (تکنیک 3-5)
          _addExcelTechniqueRow(
            sheet,
            currentRow,
            6,
            section.techniques,
            row + 3,
          );
          // گروه 3 (تکنیک 6-8)
          _addExcelTechniqueRow(
            sheet,
            currentRow,
            11,
            section.techniques,
            row + 6,
          );
          sheet.getRangeByIndex(currentRow, 1, currentRow, 16).rowHeight = 16;
          currentRow++;
        }
        currentRow++; // فاصله بین سطوح
      }

      // ===== توضیحات =====
      if (reportCard.comments != null && reportCard.comments!.isNotEmpty) {
        final xlsio.Range commentsLabel = sheet.getRangeByIndex(
          currentRow,
          1,
          currentRow,
          2,
        );
        commentsLabel.merge();
        commentsLabel.setText('توضیحات:');
        commentsLabel.cellStyle.bold = true;
        commentsLabel.cellStyle.hAlign = xlsio.HAlignType.right;

        final xlsio.Range commentsValue = sheet.getRangeByIndex(
          currentRow,
          3,
          currentRow,
          16,
        );
        commentsValue.merge();
        commentsValue.setText(reportCard.comments!);
        commentsValue.cellStyle.hAlign = xlsio.HAlignType.right;
        currentRow++;
      }

      // ===== امضا =====
      if (reportCard.signatureImagePath != null &&
          reportCard.signatureImagePath!.isNotEmpty) {
        try {
          final signatureFile = File(reportCard.signatureImagePath!);
          if (signatureFile.existsSync()) {
            final signatureBytes = signatureFile.readAsBytesSync();
            final xlsio.Picture picture = sheet.pictures.addStream(
              currentRow,
              1,
              signatureBytes,
            );
            picture.width = 100;
            picture.height = 50;

            final xlsio.Range signatureLabel = sheet.getRangeByIndex(
              currentRow,
              3,
              currentRow,
              5,
            );
            signatureLabel.merge();
            signatureLabel.setText('امضای مدیریت');
            signatureLabel.cellStyle.hAlign = xlsio.HAlignType.right;
          }
        } catch (e) {
          print('خطا در اضافه کردن امضا به Excel: $e');
        }
      }

      // ذخیره فایل
      final List<int> bytes = workbook.saveAsStream();
      workbook.dispose();

      final file = File(filePath);
      await file.writeAsBytes(bytes);

      return filePath;
    } catch (e) {
      throw Exception('خطا در ایجاد فایل Excel: ${e.toString()}');
    }
  }

  void _addExcelInfoRow(
    xlsio.Worksheet sheet,
    int row,
    String label,
    String value,
    int startCol,
    int endCol,
  ) {
    final xlsio.Range labelRange = sheet.getRangeByIndex(row, startCol);
    labelRange.setText(label);
    labelRange.cellStyle.bold = true;
    labelRange.cellStyle.fontSize = 10;
    labelRange.cellStyle.hAlign = xlsio.HAlignType.right;

    final xlsio.Range valueRange = sheet.getRangeByIndex(
      row,
      startCol + 1,
      row,
      endCol,
    );
    valueRange.merge();
    valueRange.setText(value);
    valueRange.cellStyle.fontSize = 10;
    valueRange.cellStyle.hAlign = xlsio.HAlignType.right;
  }

  void _addExcelTableHeader(xlsio.Worksheet sheet, int row, int startCol) {
    final headers = ['ردیف', 'تکنیک', 'عالی', 'خوب', 'متوسط'];
    final widths = [1, 2, 1, 1, 1]; // تعداد ستون برای هر هدر

    int col = startCol;
    for (int i = 0; i < headers.length; i++) {
      final xlsio.Range cell = sheet.getRangeByIndex(row, col);
      cell.setText(headers[i]);
      cell.cellStyle.bold = true;
      cell.cellStyle.fontSize = 9;
      cell.cellStyle.hAlign = xlsio.HAlignType.center;
      cell.cellStyle.vAlign = xlsio.VAlignType.center;
      cell.cellStyle.backColor = '#E0E0E0';
      cell.cellStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
      col += widths[i];
    }
  }

  void _addExcelTechniqueRow(
    xlsio.Worksheet sheet,
    int row,
    int startCol,
    List<TechniqueEvaluation> techniques,
    int techIndex,
  ) {
    if (techIndex >= techniques.length) return;

    final tech = techniques[techIndex];
    int col = startCol;

    // ردیف
    final xlsio.Range numCell = sheet.getRangeByIndex(row, col);
    numCell.setText(_toPersianNumber(tech.number));
    numCell.cellStyle.hAlign = xlsio.HAlignType.center;
    numCell.cellStyle.fontSize = 9;
    numCell.cellStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
    col++;

    // تکنیک
    final xlsio.Range techCell = sheet.getRangeByIndex(row, col);
    techCell.setText(tech.techniqueName);
    techCell.cellStyle.hAlign = xlsio.HAlignType.right;
    techCell.cellStyle.fontSize = 9;
    techCell.cellStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
    col++;

    // عالی
    final xlsio.Range excellentCell = sheet.getRangeByIndex(row, col);
    excellentCell.setText(tech.level == PerformanceLevel.excellent ? '✓' : '');
    excellentCell.cellStyle.hAlign = xlsio.HAlignType.center;
    excellentCell.cellStyle.fontColor = '#16A34A';
    excellentCell.cellStyle.bold = true;
    excellentCell.cellStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
    col++;

    // خوب
    final xlsio.Range goodCell = sheet.getRangeByIndex(row, col);
    goodCell.setText(tech.level == PerformanceLevel.good ? '✓' : '');
    goodCell.cellStyle.hAlign = xlsio.HAlignType.center;
    goodCell.cellStyle.fontColor = '#2563EB';
    goodCell.cellStyle.bold = true;
    goodCell.cellStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
    col++;

    // متوسط
    final xlsio.Range averageCell = sheet.getRangeByIndex(row, col);
    averageCell.setText(tech.level == PerformanceLevel.average ? '✓' : '');
    averageCell.cellStyle.hAlign = xlsio.HAlignType.center;
    averageCell.cellStyle.fontColor = '#EA580C';
    averageCell.cellStyle.bold = true;
    averageCell.cellStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
  }

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
        continue;
      }
    }

    if (exportedFiles.isEmpty) {
      throw Exception('هیچ فایلی export نشد');
    }

    return exportedFiles;
  }

  String _sanitizeFileName(String name) {
    return name
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .trim();
  }

  Future<bool> isValidOutputDirectory(String path) async {
    try {
      final dir = Directory(path);
      return await dir.exists() || await dir.parent.exists();
    } catch (e) {
      return false;
    }
  }

  int estimateFileSize(ReportCard reportCard, ExportFormat format) {
    final baseSize = format == ExportFormat.pdf ? 50000 : 20000;
    final techniqueCount = reportCard.sections.values.fold<int>(
      0,
      (sum, section) => sum + section.techniques.length,
    );
    return baseSize + (techniqueCount * 100);
  }
}

enum ExportFormat { pdf, excel }
