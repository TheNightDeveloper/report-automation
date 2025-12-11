import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../repositories/report_card_repository.dart';
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

  @override
  ExportState build() {
    _exportService = ExportService();
    _reportCardRepository = ReportCardRepository();
    return ExportState();
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
      final filePath = format == ExportFormat.pdf
          ? await _exportService.exportToPDF(
              reportCard: reportCard,
              outputDirectory: outputDirectory,
            )
          : await _exportService.exportToExcel(
              reportCard: reportCard,
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

      final exportedFiles = await _exportService.batchExport(
        reportCards: reportCards,
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

      final exportedFiles = await _exportService.batchExport(
        reportCards: reportCards,
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
  int estimateFileSize(ReportCard reportCard, ExportFormat format) {
    return _exportService.estimateFileSize(reportCard, format);
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
