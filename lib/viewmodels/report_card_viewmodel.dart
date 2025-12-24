import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../repositories/report_card_repository.dart';
import '../services/report_card_service.dart';

// State class برای مدیریت کارنامه
class ReportCardState {
  final ReportCard? currentReportCard;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final String? successMessage;

  ReportCardState({
    this.currentReportCard,
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.successMessage,
  });

  ReportCardState copyWith({
    ReportCard? currentReportCard,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    String? successMessage,
  }) {
    return ReportCardState(
      currentReportCard: currentReportCard ?? this.currentReportCard,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }

  double get completionPercentage {
    if (currentReportCard == null) return 0.0;
    final service = ReportCardService();
    return service.calculateCompletionPercentage(currentReportCard!);
  }

  bool get isComplete {
    if (currentReportCard == null) return false;
    final service = ReportCardService();
    return service.isReportCardComplete(currentReportCard!);
  }
}

// Notifier برای مدیریت کارنامه
class ReportCardNotifier extends Notifier<ReportCardState> {
  late final ReportCardRepository _repository;
  late final ReportCardService _service;

  @override
  ReportCardState build() {
    _repository = ReportCardRepository();
    _service = ReportCardService();
    return ReportCardState();
  }

  // بارگذاری کارنامه برای دانش‌آموز
  Future<void> loadReportCard(String studentId, String studentName) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      ReportCard? reportCard = await _repository.loadReportCard(studentId);

      if (reportCard == null) {
        reportCard = _service.createEmptyReportCard(studentId, studentName);
      }

      state = state.copyWith(currentReportCard: reportCard, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'خطا در بارگذاری کارنامه: ${e.toString()}',
      );
    }
  }

  // ذخیره کارنامه
  Future<void> saveReportCard() async {
    if (state.currentReportCard == null) return;

    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      await _repository.saveReportCard(state.currentReportCard!);
      state = state.copyWith(
        isSaving: false,
        successMessage: 'کارنامه با موفقیت ذخیره شد',
      );
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'خطا در ذخیره کارنامه: ${e.toString()}',
      );
    }
  }

  // به‌روزرسانی اطلاعات دانش‌آموز
  void updateStudentInfo({
    String? grade,
    String? level,
    String? school,
    String? headCoach,
  }) {
    if (state.currentReportCard == null) return;

    final updatedInfo = state.currentReportCard!.studentInfo.copyWith(
      grade: grade,
      level: level,
      school: school,
      headCoach: headCoach,
    );

    final updatedReportCard = state.currentReportCard!.copyWith(
      studentInfo: updatedInfo,
    );

    state = state.copyWith(currentReportCard: updatedReportCard);
    _autoSave();
  }

  // به‌روزرسانی اطلاعات حضور
  void updateAttendanceInfo({
    int? totalSessions,
    int? attendedSessions,
    String? performanceLevel,
  }) {
    if (state.currentReportCard == null) return;

    try {
      final updatedInfo = state.currentReportCard!.attendanceInfo.copyWith(
        totalSessions: totalSessions,
        attendedSessions: attendedSessions,
        performanceLevel: performanceLevel,
      );

      final updatedReportCard = state.currentReportCard!.copyWith(
        attendanceInfo: updatedInfo,
      );

      state = state.copyWith(currentReportCard: updatedReportCard);
      _autoSave();
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'خطا در به‌روزرسانی اطلاعات حضور: ${e.toString()}',
      );
    }
  }

  // به‌روزرسانی ارزیابی تکنیک
  void updateTechniqueEvaluation({
    required String sectionName,
    required int techniqueNumber,
    required PerformanceLevel? performanceLevel,
  }) {
    if (state.currentReportCard == null) return;

    try {
      final section = state.currentReportCard!.sections[sectionName];
      if (section == null) return;

      final updatedTechniques = section.techniques.map((tech) {
        if (tech.number == techniqueNumber) {
          return tech.withPerformanceLevel(performanceLevel);
        }
        return tech;
      }).toList();

      final updatedSection = section.copyWith(techniques: updatedTechniques);
      final updatedSections = Map<String, SectionEvaluation>.from(
        state.currentReportCard!.sections,
      );
      updatedSections[sectionName] = updatedSection;

      final updatedReportCard = state.currentReportCard!.copyWith(
        sections: updatedSections,
      );

      state = state.copyWith(currentReportCard: updatedReportCard);
      _autoSave();
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'خطا در به‌روزرسانی ارزیابی تکنیک: ${e.toString()}',
      );
    }
  }

  // ذخیره خودکار
  void _autoSave() {
    saveReportCard();
  }

  // به‌روزرسانی توضیحات
  void updateComments(String? comments) {
    if (state.currentReportCard == null) return;

    final updatedReportCard = state.currentReportCard!.copyWith(
      comments: comments,
    );

    state = state.copyWith(currentReportCard: updatedReportCard);
    _autoSave();
  }

  // به‌روزرسانی مسیر تصویر امضا
  void updateSignatureImage(String? imagePath) {
    if (state.currentReportCard == null) return;

    final updatedReportCard = state.currentReportCard!.copyWith(
      signatureImagePath: imagePath,
    );

    state = state.copyWith(currentReportCard: updatedReportCard);
    _autoSave();
  }

  // پاک کردن پیام‌ها
  void clearMessages() {
    state = state.copyWith(errorMessage: null, successMessage: null);
  }

  // پاک کردن کارنامه فعلی
  void clearCurrentReportCard() {
    state = ReportCardState();
  }
}

// Provider اصلی
final reportCardProvider =
    NotifierProvider<ReportCardNotifier, ReportCardState>(
      ReportCardNotifier.new,
    );
