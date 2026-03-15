import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../repositories/report_card_repository.dart';
import '../repositories/sport_repository.dart';
import '../repositories/folder_repository.dart';
import '../services/export_service.dart';

// State class برای مدیریت export
class ExportState {
  final bool isExporting;
  final double progress; // 0.0 to 1.0
  final int currentItem;
  final int totalItems;
  final String? errorMessage;
  final String? successMessage;
  final List<String> exportedFiles;

  ExportState({
    this.isExporting = false,
    this.progress = 0.0,
    this.currentItem = 0,
    this.totalItems = 0,
    this.errorMessage,
    this.successMessage,
    this.exportedFiles = const [],
  });

  ExportState copyWith({
    bool? isExporting,
    double? progress,
    int? currentItem,
    int? totalItems,
    String? errorMessage,
    String? successMessage,
    List<String>? exportedFiles,
  }) {
    return ExportState(
      isExporting: isExporting ?? this.isExporting,
      progress: progress ?? this.progress,
      currentItem: currentItem ?? this.currentItem,
      totalItems: totalItems ?? this.totalItems,
      errorMessage: errorMessage,
      successMessage: successMessage,
      exportedFiles: exportedFiles ?? this.exportedFiles,
    );
  }
}

// Notifier برای مدیریت export
class ExportNotifier extends Notifier<ExportState> {
  late final ExportService _exportService;
  late final ReportCardRepository _reportCardRepository;
  late final SportRepository _sportRepository;

  @override
  ExportState build() {
    _exportService = ExportService();
    _reportCardRepository = ReportCardRepository();
    _sportRepository = SportRepository();
    return ExportState();
  }

  // export تکی با رشته ورزشی مشخص
  Future<void> exportSingleWithSport({
    required ReportCard reportCard,
    required String outputDirectory,
    required ExportFormat format,
    required Sport sport,
  }) async {
    state = state.copyWith(
      isExporting: true,
      errorMessage: null,
      successMessage: null,
      exportedFiles: [],
    );

    try {
      final filePath = format == ExportFormat.pdf
          ? await _exportService.exportToPDF(
              reportCard: reportCard,
              sport: sport,
              outputDirectory: outputDirectory,
            )
          : await _exportService.exportToExcel(
              reportCard: reportCard,
              sport: sport,
              outputDirectory: outputDirectory,
            );

      state = state.copyWith(
        isExporting: false,
        exportedFiles: [filePath],
        successMessage: 'فایل با موفقیت ذخیره شد:\n$filePath',
      );
    } catch (e) {
      state = state.copyWith(
        isExporting: false,
        errorMessage: 'خطا در export: ${e.toString()}',
      );
    }
  }

  // export تکی
  Future<void> exportSingle({
    required ReportCard reportCard,
    required String outputDirectory,
    required ExportFormat format,
  }) async {
    state = state.copyWith(
      isExporting: true,
      errorMessage: null,
      successMessage: null,
      exportedFiles: [],
    );

    try {
      // بارگذاری Sport مرتبط با کارنامه
      Sport? sport;
      if (reportCard.sportId != null) {
        sport = await _sportRepository.getSport(reportCard.sportId!);
      }

      // اگر Sport یافت نشد، از رشته پیش‌فرض استفاده کن
      sport ??= await _sportRepository.getDefaultSport();

      if (sport == null) {
        state = state.copyWith(
          isExporting: false,
          errorMessage: 'رشته ورزشی یافت نشد',
        );
        return;
      }

      final filePath = format == ExportFormat.pdf
          ? await _exportService.exportToPDF(
              reportCard: reportCard,
              sport: sport,
              outputDirectory: outputDirectory,
            )
          : await _exportService.exportToExcel(
              reportCard: reportCard,
              sport: sport,
              outputDirectory: outputDirectory,
            );

      state = state.copyWith(
        isExporting: false,
        exportedFiles: [filePath],
        successMessage: 'فایل با موفقیت ذخیره شد:\n$filePath',
      );
    } catch (e) {
      state = state.copyWith(
        isExporting: false,
        errorMessage: 'خطا در export: ${e.toString()}',
      );
    }
  }

  // export دسته‌جمعی
  Future<void> exportBatch({
    required List<String> studentIds,
    required String outputDirectory,
    required ExportFormat format,
  }) async {
    state = state.copyWith(
      isExporting: true,
      errorMessage: null,
      successMessage: null,
      exportedFiles: [],
      totalItems: studentIds.length,
      currentItem: 0,
      progress: 0.0,
    );

    try {
      final reportCards = <ReportCard>[];
      for (final studentId in studentIds) {
        final reportCard = await _reportCardRepository.loadReportCard(
          studentId,
        );
        if (reportCard != null) {
          reportCards.add(reportCard);
        }
      }

      if (reportCards.isEmpty) {
        state = state.copyWith(
          isExporting: false,
          errorMessage: 'هیچ کارنامه‌ای برای export یافت نشد',
        );
        return;
      }

      // بارگذاری تمام رشته‌های ورزشی
      final allSports = await _sportRepository.getAllSports();
      final sportsMap = <String, Sport>{};
      for (final sport in allSports) {
        sportsMap[sport.id] = sport;
      }

      final exportedFiles = await _exportService.batchExport(
        reportCards: reportCards,
        sportsMap: sportsMap,
        outputDirectory: outputDirectory,
        format: format,
        onProgress: (current, total) {
          state = state.copyWith(
            currentItem: current,
            totalItems: total,
            progress: current / total,
          );
        },
      );

      state = state.copyWith(
        isExporting: false,
        exportedFiles: exportedFiles,
        successMessage:
            '${exportedFiles.length} فایل با موفقیت ذخیره شد در:\n$outputDirectory',
      );
    } catch (e) {
      state = state.copyWith(
        isExporting: false,
        errorMessage: 'خطا در export دسته‌جمعی: ${e.toString()}',
      );
    }
  }

  // export همه کارنامه‌ها با رشته ورزشی مشخص
  Future<void> exportAllWithSport({
    required String outputDirectory,
    required ExportFormat format,
    required Sport sport,
  }) async {
    state = state.copyWith(
      isExporting: true,
      errorMessage: null,
      successMessage: null,
      exportedFiles: [],
    );

    try {
      final reportCards = await _reportCardRepository.loadAllReportCards();

      if (reportCards.isEmpty) {
        state = state.copyWith(
          isExporting: false,
          errorMessage: 'هیچ کارنامه‌ای برای export یافت نشد',
        );
        return;
      }

      state = state.copyWith(
        totalItems: reportCards.length,
        currentItem: 0,
        progress: 0.0,
      );

      // استفاده از رشته ورزشی انتخاب شده برای همه کارنامه‌ها
      final sportsMap = <String, Sport>{sport.id: sport};

      // همچنین کارنامه‌هایی که sportId ندارند را با این رشته export می‌کنیم
      final updatedReportCards = reportCards.map((rc) {
        if (rc.sportId == null || rc.sportId!.isEmpty) {
          return rc.copyWith(sportId: sport.id);
        }
        return rc;
      }).toList();

      final exportedFiles = await _exportService.batchExport(
        reportCards: updatedReportCards,
        sportsMap: sportsMap,
        outputDirectory: outputDirectory,
        format: format,
        onProgress: (current, total) {
          state = state.copyWith(
            currentItem: current,
            totalItems: total,
            progress: current / total,
          );
        },
      );

      state = state.copyWith(
        isExporting: false,
        exportedFiles: exportedFiles,
        successMessage:
            '${exportedFiles.length} فایل با موفقیت ذخیره شد در:\n$outputDirectory',
      );
    } catch (e) {
      state = state.copyWith(
        isExporting: false,
        errorMessage: 'خطا در export همه کارنامه‌ها: ${e.toString()}',
      );
    }
  }

  // export همه کارنامه‌ها با فیلتر
  Future<void> exportAllFiltered({
    required String outputDirectory,
    required ExportFormat format,
    String? folderId,
    bool onlyCompleted = false,
  }) async {
    state = state.copyWith(
      isExporting: true,
      errorMessage: null,
      successMessage: null,
      exportedFiles: [],
    );

    try {
      // بارگذاری تمام رشته‌های ورزشی
      final allSports = await _sportRepository.getAllSports();
      final sportsMap = <String, Sport>{};
      for (final sport in allSports) {
        sportsMap[sport.id] = sport;
      }

      // بارگذاری همه کارنامه‌های موجود
      final allReportCards = await _reportCardRepository.loadAllReportCards();
      final reportCardsMap = <String, ReportCard>{};
      for (final rc in allReportCards) {
        reportCardsMap[rc.studentId] = rc;
      }

      // بارگذاری پوشه‌ها
      final folderRepository = FolderRepository();
      final folders = await folderRepository.loadFolders();

      // فیلتر کردن پوشه‌ها بر اساس انتخاب کاربر
      final selectedFolders = folderId == null
          ? folders
          : folders.where((f) => f.id == folderId).toList();

      // جمع‌آوری دانش‌آموزان از پوشه‌های انتخاب شده
      // استفاده از Set برای جلوگیری از تکراری شدن دانش‌آموزان
      final studentIdsSet = <String>{};
      final studentsMap = <String, Student>{};

      for (final folder in selectedFolders) {
        for (final student in folder.students) {
          if (!studentIdsSet.contains(student.id)) {
            studentIdsSet.add(student.id);
            studentsMap[student.id] = student;
          }
        }
      }

      final allStudents = studentsMap.values.toList();

      if (allStudents.isEmpty) {
        state = state.copyWith(
          isExporting: false,
          errorMessage: 'هیچ دانش‌آموزی برای export یافت نشد',
        );
        return;
      }

      // ساخت لیست کارنامه‌ها برای export
      final reportCardsToExport = <ReportCard>[];
      for (final student in allStudents) {
        ReportCard? reportCard = reportCardsMap[student.id];

        // اگر فقط کارنامه‌های تکمیل شده خواسته شده
        if (onlyCompleted) {
          if (reportCard == null) {
            continue; // skip کردن دانش‌آموزانی که کارنامه ندارند
          }
          // چک کردن اینکه آیا کارنامه تکمیل شده یا نه
          if (reportCard.levelEvaluations == null ||
              reportCard.levelEvaluations!.isEmpty) {
            continue; // skip کردن کارنامه‌های خالی
          }
        } else {
          // اگر همه دانش‌آموزان خواسته شده، برای کسانی که کارنامه ندارند یک کارنامه خالی بساز
          reportCard ??= ReportCard(
            studentId: student.id,
            studentInfo: StudentInfo(
              name: student.name,
              grade: null,
              level: null,
              school: null,
              headCoach: null,
            ),
            attendanceInfo: AttendanceInfo(
              totalSessions: 0,
              attendedSessions: 0,
              performanceLevels: [],
            ),
            sportId: sportsMap.isNotEmpty ? sportsMap.values.first.id : null,
            levelEvaluations: {},
            comments: null,
            signatureImagePath: null,
          );
        }

        reportCardsToExport.add(reportCard);
      }

      if (reportCardsToExport.isEmpty) {
        state = state.copyWith(
          isExporting: false,
          errorMessage: onlyCompleted
              ? 'هیچ کارنامه تکمیل شده‌ای یافت نشد'
              : 'هیچ کارنامه‌ای برای export یافت نشد',
        );
        return;
      }

      state = state.copyWith(
        totalItems: reportCardsToExport.length,
        currentItem: 0,
        progress: 0.0,
      );

      final exportedFiles = await _exportService.batchExport(
        reportCards: reportCardsToExport,
        sportsMap: sportsMap,
        outputDirectory: outputDirectory,
        format: format,
        onProgress: (current, total) {
          state = state.copyWith(
            currentItem: current,
            totalItems: total,
            progress: current / total,
          );
        },
      );

      state = state.copyWith(
        isExporting: false,
        exportedFiles: exportedFiles,
        successMessage:
            '${exportedFiles.length} فایل با موفقیت ذخیره شد در:\n$outputDirectory',
      );
    } catch (e) {
      state = state.copyWith(
        isExporting: false,
        errorMessage: 'خطا در export: ${e.toString()}',
      );
    }
  }

  // export همه کارنامه‌ها
  Future<void> exportAll({
    required String outputDirectory,
    required ExportFormat format,
  }) async {
    state = state.copyWith(
      isExporting: true,
      errorMessage: null,
      successMessage: null,
      exportedFiles: [],
    );

    try {
      // بارگذاری تمام رشته‌های ورزشی
      final allSports = await _sportRepository.getAllSports();

      final sportsMap = <String, Sport>{};
      for (final sport in allSports) {
        sportsMap[sport.id] = sport;
      }

      // بارگذاری همه کارنامه‌های موجود
      final allReportCards = await _reportCardRepository.loadAllReportCards();

      // ساخت map از studentId به ReportCard
      final reportCardsMap = <String, ReportCard>{};
      for (final rc in allReportCards) {
        reportCardsMap[rc.studentId] = rc;
      }

      // بارگذاری همه دانش‌آموزان از همه پوشه‌ها
      final folderRepository = FolderRepository();
      final folders = await folderRepository.loadFolders();

      // استفاده از Set برای جلوگیری از تکراری شدن دانش‌آموزان
      final studentIdsSet = <String>{};
      final studentsMap = <String, Student>{};

      for (final folder in folders) {
        for (final student in folder.students) {
          if (!studentIdsSet.contains(student.id)) {
            studentIdsSet.add(student.id);
            studentsMap[student.id] = student;
          }
        }
      }

      final allStudents = studentsMap.values.toList();

      if (allStudents.isEmpty) {
        state = state.copyWith(
          isExporting: false,
          errorMessage: 'هیچ دانش‌آموزی برای export یافت نشد',
        );
        return;
      }

      state = state.copyWith(
        totalItems: allStudents.length,
        currentItem: 0,
        progress: 0.0,
      );

      // ساخت لیست کارنامه‌ها برای export
      final reportCardsToExport = <ReportCard>[];
      for (final student in allStudents) {
        ReportCard? reportCard = reportCardsMap[student.id];

        reportCard ??= ReportCard(
          studentId: student.id,
          studentInfo: StudentInfo(
            name: student.name,
            grade: null,
            level: null,
            school: null,
            headCoach: null,
          ),
          attendanceInfo: AttendanceInfo(
            totalSessions: 0,
            attendedSessions: 0,
            performanceLevels: [],
          ),
          sportId: sportsMap.isNotEmpty ? sportsMap.values.first.id : null,
          levelEvaluations: {},
          comments: null,
          signatureImagePath: null,
        );

        reportCardsToExport.add(reportCard);
      }

      final exportedFiles = await _exportService.batchExport(
        reportCards: reportCardsToExport,
        sportsMap: sportsMap,
        outputDirectory: outputDirectory,
        format: format,
        onProgress: (current, total) {
          state = state.copyWith(
            currentItem: current,
            totalItems: total,
            progress: current / total,
          );
        },
      );

      state = state.copyWith(
        isExporting: false,
        exportedFiles: exportedFiles,
        successMessage:
            '${exportedFiles.length} فایل با موفقیت ذخیره شد در:\n$outputDirectory',
      );
    } catch (e) {
      state = state.copyWith(
        isExporting: false,
        errorMessage: 'خطا در export همه کارنامه‌ها: ${e.toString()}',
      );
    }
  }

  // بررسی معتبر بودن مسیر خروجی
  Future<bool> validateOutputDirectory(String path) async {
    return await _exportService.isValidOutputDirectory(path);
  }

  // محاسبه حجم تقریبی
  int estimateFileSize(
    ReportCard reportCard,
    Sport sport,
    ExportFormat format,
  ) {
    return _exportService.estimateFileSize(reportCard, sport, format);
  }

  // پاک کردن پیام‌ها
  void clearMessages() {
    state = state.copyWith(errorMessage: null, successMessage: null);
  }

  // ریست کردن state
  void reset() {
    state = ExportState();
  }
}

// Provider اصلی
final exportProvider = NotifierProvider<ExportNotifier, ExportState>(
  ExportNotifier.new,
);
