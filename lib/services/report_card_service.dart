import '../models/models.dart';
import '../utils/report_card_template.dart';

class ReportCardService {
  /// ایجاد کارنامه خالی برای یک دانش‌آموز
  ReportCard createEmptyReportCard(String studentId, String studentName) {
    return ReportCard(
      studentId: studentId,
      studentInfo: StudentInfo(name: studentName),
      attendanceInfo: AttendanceInfo(),
      sections: ReportCardTemplate.createAllSections(),
    );
  }

  /// اعتبارسنجی کارنامه
  bool validateReportCard(ReportCard reportCard) {
    // بررسی اطلاعات پایه
    if (reportCard.studentInfo.name.trim().isEmpty) {
      return false;
    }

    // بررسی فیلدهای عددی (اگر پر شده باشند)
    final attendance = reportCard.attendanceInfo;
    if (attendance.totalSessions != null && attendance.totalSessions! < 0) {
      return false;
    }
    if (attendance.attendedSessions != null &&
        attendance.attendedSessions! < 0) {
      return false;
    }

    // بررسی منطقی: تعداد حضور نباید بیشتر از کل جلسات باشد
    if (attendance.totalSessions != null &&
        attendance.attendedSessions != null &&
        attendance.attendedSessions! > attendance.totalSessions!) {
      return false;
    }

    return true;
  }

  /// محاسبه درصد تکمیل کارنامه
  double calculateCompletionPercentage(ReportCard reportCard) {
    int totalFields = 0;
    int filledFields = 0;

    // فیلدهای اطلاعات دانش‌آموز (6 فیلد)
    totalFields += 6;
    if (reportCard.studentInfo.name.trim().isNotEmpty) {
      filledFields++;
    }
    if (reportCard.studentInfo.grade?.trim().isNotEmpty ?? false) {
      filledFields++;
    }
    if (reportCard.studentInfo.level?.trim().isNotEmpty ?? false) {
      filledFields++;
    }
    if (reportCard.studentInfo.school?.trim().isNotEmpty ?? false) {
      filledFields++;
    }
    if (reportCard.studentInfo.headCoach?.trim().isNotEmpty ?? false) {
      filledFields++;
    }
    if (reportCard.studentInfo.sportField?.trim().isNotEmpty ?? false) {
      filledFields++;
    }

    // فیلدهای حضور (4 فیلد)
    totalFields += 4;
    if (reportCard.attendanceInfo.totalSessions != null) {
      filledFields++;
    }
    if (reportCard.attendanceInfo.attendedSessions != null) {
      filledFields++;
    }
    if (reportCard.attendanceInfo.performanceLevel?.trim().isNotEmpty ??
        false) {
      filledFields++;
    }
    if (reportCard.attendanceInfo.sportField?.trim().isNotEmpty ?? false) {
      filledFields++;
    }

    // تکنیک‌ها (63 تکنیک = 7 سطح × 9 تکنیک)
    for (final section in reportCard.sections.values) {
      for (final technique in section.techniques) {
        totalFields++;
        if (technique.performanceLevel != null) {
          filledFields++;
        }
      }
    }

    return (filledFields / totalFields) * 100;
  }

  /// بررسی اینکه آیا کارنامه کامل است
  bool isReportCardComplete(ReportCard reportCard) {
    // حداقل اطلاعات پایه باید پر شده باشد
    if (reportCard.studentInfo.name.trim().isEmpty) {
      return false;
    }

    // حداقل یک تکنیک باید ارزیابی شده باشد
    bool hasAnyEvaluation = false;
    for (final section in reportCard.sections.values) {
      for (final technique in section.techniques) {
        if (technique.performanceLevel != null) {
          hasAnyEvaluation = true;
          break;
        }
      }
      if (hasAnyEvaluation) break;
    }

    return hasAnyEvaluation;
  }

  /// اعتبارسنجی ورودی عددی
  bool validateNumericInput(String? input) {
    if (input == null || input.trim().isEmpty) {
      return true; // فیلد خالی مجاز است
    }

    final number = int.tryParse(input.trim());
    return number != null && number >= 0;
  }

  /// اعتبارسنجی سطح عملکرد
  bool validatePerformanceLevel(String? level) {
    if (level == null || level.trim().isEmpty) {
      return true; // فیلد خالی مجاز است
    }

    return PerformanceLevelExtension.fromString(level) != null;
  }

  /// به‌روزرسانی اطلاعات دانش‌آموز
  ReportCard updateStudentInfo(ReportCard reportCard, StudentInfo newInfo) {
    return reportCard.copyWith(studentInfo: newInfo);
  }

  /// به‌روزرسانی اطلاعات حضور
  ReportCard updateAttendanceInfo(
    ReportCard reportCard,
    AttendanceInfo newInfo,
  ) {
    return reportCard.copyWith(attendanceInfo: newInfo);
  }

  /// به‌روزرسانی ارزیابی یک تکنیک
  ReportCard updateTechniqueEvaluation(
    ReportCard reportCard,
    String sectionName,
    int techniqueNumber,
    PerformanceLevel? level,
  ) {
    final sections = Map<String, SectionEvaluation>.from(reportCard.sections);
    final section = sections[sectionName];

    if (section == null) return reportCard;

    final techniques = List<TechniqueEvaluation>.from(section.techniques);
    final techniqueIndex = techniques.indexWhere(
      (t) => t.number == techniqueNumber,
    );

    if (techniqueIndex == -1) return reportCard;

    techniques[techniqueIndex] = techniques[techniqueIndex]
        .withPerformanceLevel(level);
    sections[sectionName] = section.copyWith(techniques: techniques);

    return reportCard.copyWith(sections: sections);
  }

  /// دریافت تعداد تکنیک‌های ارزیابی شده در یک بخش
  int getEvaluatedTechniquesCount(SectionEvaluation section) {
    return section.techniques.where((t) => t.performanceLevel != null).length;
  }

  /// دریافت تعداد کل تکنیک‌های ارزیابی شده
  int getTotalEvaluatedTechniquesCount(ReportCard reportCard) {
    int count = 0;
    for (final section in reportCard.sections.values) {
      count += getEvaluatedTechniquesCount(section);
    }
    return count;
  }
}
