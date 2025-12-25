import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../repositories/report_card_repository.dart';
import '../repositories/sport_repository.dart';

// State class برای مدیریت کارنامه
class ReportCardState {
  final ReportCard? currentReportCard;
  final Sport? selectedSport;
  final List<Sport> availableSports;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final String? successMessage;

  ReportCardState({
    this.currentReportCard,
    this.selectedSport,
    this.availableSports = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.successMessage,
  });

  ReportCardState copyWith({
    ReportCard? currentReportCard,
    Sport? selectedSport,
    List<Sport>? availableSports,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    String? successMessage,
  }) {
    return ReportCardState(
      currentReportCard: currentReportCard ?? this.currentReportCard,
      selectedSport: selectedSport ?? this.selectedSport,
      availableSports: availableSports ?? this.availableSports,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }

  double get completionPercentage {
    if (currentReportCard == null || selectedSport == null) return 0.0;
    return _calculateCompletionPercentage();
  }

  double _calculateCompletionPercentage() {
    if (currentReportCard?.levelEvaluations == null) return 0.0;

    int totalTechniques = 0;
    int evaluatedTechniques = 0;

    for (final level in selectedSport!.levels) {
      totalTechniques += level.techniques.length;
      final levelEval = currentReportCard!.levelEvaluations?[level.id];
      if (levelEval != null) {
        for (final tech in level.techniques) {
          final techEval = levelEval.techniqueEvaluations[tech.id];
          if (techEval?.performanceRatingId != null) {
            evaluatedTechniques++;
          }
        }
      }
    }

    if (totalTechniques == 0) return 0.0;
    return (evaluatedTechniques / totalTechniques) * 100;
  }

  bool get isComplete => completionPercentage >= 100;
}

// Notifier برای مدیریت کارنامه
class ReportCardNotifier extends Notifier<ReportCardState> {
  late final ReportCardRepository _repository;
  late final SportRepository _sportRepository;

  @override
  ReportCardState build() {
    _repository = ReportCardRepository();
    _sportRepository = SportRepository();
    return ReportCardState();
  }

  // بارگذاری لیست رشته‌های ورزشی
  Future<void> loadAvailableSports() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final sports = await _sportRepository.getAllSports();
      sports.sort((a, b) {
        if (a.isDefault && !b.isDefault) return -1;
        if (!a.isDefault && b.isDefault) return 1;
        return a.name.compareTo(b.name);
      });
      state = state.copyWith(availableSports: sports, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'خطا در بارگذاری رشته‌های ورزشی: ${e.toString()}',
      );
    }
  }

  // انتخاب رشته ورزشی
  void selectSport(Sport sport) {
    state = state.copyWith(selectedSport: sport);
  }

  // بارگذاری کارنامه برای دانش‌آموز با رشته ورزشی
  Future<void> loadReportCard(
    String studentId,
    String studentName, {
    String? sportId,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      ReportCard? reportCard = await _repository.loadReportCard(studentId);

      // اگر کارنامه موجود است و sportId دارد
      if (reportCard != null && reportCard.sportId != null) {
        final sport = await _sportRepository.getSport(reportCard.sportId!);
        if (sport != null) {
          state = state.copyWith(
            currentReportCard: reportCard,
            selectedSport: sport,
            isLoading: false,
          );
          return;
        }
      }

      // اگر sportId مشخص شده
      if (sportId != null) {
        final sport = await _sportRepository.getSport(sportId);
        if (sport != null) {
          if (reportCard == null) {
            reportCard = _createEmptyReportCard(studentId, studentName, sport);
          } else {
            reportCard = reportCard.copyWith(sportId: sportId);
          }
          state = state.copyWith(
            currentReportCard: reportCard,
            selectedSport: sport,
            isLoading: false,
          );
          return;
        }
      }

      // استفاده از رشته پیش‌فرض
      final defaultSport = await _sportRepository.getDefaultSport();
      if (defaultSport != null) {
        reportCard ??= _createEmptyReportCard(
          studentId,
          studentName,
          defaultSport,
        );
        state = state.copyWith(
          currentReportCard: reportCard,
          selectedSport: defaultSport,
          isLoading: false,
        );
      } else {
        // اگر هیچ رشته‌ای وجود ندارد
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'هیچ رشته ورزشی تعریف نشده است',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'خطا در بارگذاری کارنامه: ${e.toString()}',
      );
    }
  }

  // ایجاد کارنامه خالی با ساختار جدید
  ReportCard _createEmptyReportCard(
    String studentId,
    String studentName,
    Sport sport,
  ) {
    final levelEvaluations = <String, LevelEvaluation>{};

    for (final level in sport.levels) {
      final techniqueEvaluations = <String, TechniqueEvaluation>{};
      for (final technique in level.techniques) {
        techniqueEvaluations[technique.id] = TechniqueEvaluation(
          techniqueId: technique.id,
          performanceRatingId: null,
        );
      }
      levelEvaluations[level.id] = LevelEvaluation(
        levelId: level.id,
        techniqueEvaluations: techniqueEvaluations,
      );
    }

    return ReportCard(
      studentId: studentId,
      studentInfo: StudentInfo(
        name: studentName,
        grade: null,
        level: null,
        school: null,
        headCoach: null,
      ),
      attendanceInfo: AttendanceInfo(
        totalSessions: 0,
        attendedSessions: 0,
        performanceLevel: null,
      ),
      sportId: sport.id,
      levelEvaluations: levelEvaluations,
      comments: null,
      signatureImagePath: null,
    );
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

  // به‌روزرسانی ارزیابی تکنیک - ساختار جدید
  void updateTechniqueEvaluationNew({
    required String levelId,
    required String techniqueId,
    required String? performanceRatingId,
  }) {
    if (state.currentReportCard == null) return;

    try {
      final levelEvaluations = Map<String, LevelEvaluation>.from(
        state.currentReportCard!.levelEvaluations ?? {},
      );

      var levelEval = levelEvaluations[levelId];
      levelEval ??= LevelEvaluation(levelId: levelId, techniqueEvaluations: {});

      final techniqueEvaluations = Map<String, TechniqueEvaluation>.from(
        levelEval.techniqueEvaluations,
      );

      techniqueEvaluations[techniqueId] = TechniqueEvaluation(
        techniqueId: techniqueId,
        performanceRatingId: performanceRatingId,
      );

      levelEvaluations[levelId] = levelEval.copyWith(
        techniqueEvaluations: techniqueEvaluations,
      );

      final updatedReportCard = state.currentReportCard!.copyWith(
        levelEvaluations: levelEvaluations,
      );

      state = state.copyWith(currentReportCard: updatedReportCard);
      _autoSave();
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'خطا در به‌روزرسانی ارزیابی تکنیک: ${e.toString()}',
      );
    }
  }

  // به‌روزرسانی ارزیابی تکنیک - ساختار قدیمی (برای سازگاری)
  void updateTechniqueEvaluation({
    required String sectionName,
    required int techniqueNumber,
    required PerformanceLevel? performanceLevel,
  }) {
    if (state.currentReportCard == null) return;
    if (state.currentReportCard!.sections == null) return;

    try {
      final section = state.currentReportCard!.sections![sectionName];
      if (section == null) return;

      final updatedTechniques = section.techniques.map((tech) {
        if (tech.number == techniqueNumber) {
          return tech.withPerformanceLevel(performanceLevel);
        }
        return tech;
      }).toList();

      final updatedSection = section.copyWith(techniques: updatedTechniques);
      final updatedSections = Map<String, SectionEvaluation>.from(
        state.currentReportCard!.sections!,
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
    state = ReportCardState(availableSports: state.availableSports);
  }

  // دریافت ارزیابی یک تکنیک
  String? getTechniqueRating(String levelId, String techniqueId) {
    final levelEval = state.currentReportCard?.levelEvaluations?[levelId];
    if (levelEval == null) return null;
    return levelEval.techniqueEvaluations[techniqueId]?.performanceRatingId;
  }

  // دریافت نام سطح عملکرد
  String? getPerformanceRatingName(String? ratingId) {
    if (ratingId == null || state.selectedSport == null) return null;
    try {
      return state.selectedSport!.performanceRatings
          .firstWhere((r) => r.id == ratingId)
          .name;
    } catch (e) {
      return null;
    }
  }
}

// Provider اصلی
final reportCardProvider =
    NotifierProvider<ReportCardNotifier, ReportCardState>(
      ReportCardNotifier.new,
    );
