import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../repositories/report_card_repository.dart';
import '../repositories/sport_repository.dart';
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
