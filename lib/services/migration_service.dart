import 'package:hive_flutter/hive_flutter.dart';
import '../models/models.dart';
import '../repositories/sport_repository.dart';
import '../repositories/report_card_repository.dart';
import '../utils/report_card_template.dart';

class MigrationService {
  static const String _migrationBoxName = 'migration_status';
  static const String _migrationKey = 'v2_migration_completed';

  final SportRepository _sportRepository;
  final ReportCardRepository _reportCardRepository;

  MigrationService(this._sportRepository, this._reportCardRepository);

  /// بررسی نیاز به migration
  Future<bool> needsMigration() async {
    try {
      // بررسی flag مهاجرت
      final migrationBox = await Hive.openBox(_migrationBoxName);
      final migrationCompleted =
          migrationBox.get(_migrationKey, defaultValue: false) as bool;

      if (migrationCompleted) {
        return false; // مهاجرت قبلاً انجام شده
      }

      // بررسی وجود کارنامه‌های قدیمی
      final reportCards = await _reportCardRepository.loadAllReportCards();
      final hasOldReportCards = reportCards.any(
        (rc) =>
            rc.sections != null &&
            rc.sections!.isNotEmpty &&
            rc.sportId == null,
      );

      return hasOldReportCards;
    } catch (e) {
      print('خطا در بررسی نیاز به migration: $e');
      return false;
    }
  }

  /// اجرای کامل migration
  Future<void> migrateToV2() async {
    try {
      print('شروع migration به نسخه 2...');

      // 1. ایجاد رشته شنا پیش‌فرض
      final swimmingSport = await createDefaultSwimmingSport();
      print('رشته شنا پیش‌فرض ایجاد شد: ${swimmingSport.id}');

      // 2. مهاجرت کارنامه‌های موجود
      await migrateReportCards(swimmingSport);
      print('کارنامه‌ها با موفقیت مهاجرت یافتند');

      // 3. ذخیره وضعیت migration
      await markMigrationComplete();
      print('Migration با موفقیت کامل شد');
    } catch (e) {
      print('خطا در migration: $e');
      rethrow;
    }
  }

  /// ذخیره وضعیت migration
  Future<void> markMigrationComplete() async {
    final migrationBox = await Hive.openBox(_migrationBoxName);
    await migrationBox.put(_migrationKey, true);
  }

  /// ایجاد رشته شنا پیش‌فرض از داده‌های hardcoded
  Future<Sport> createDefaultSwimmingSport() async {
    final sportId = 'swimming_default';

    // بررسی اگر قبلاً ایجاد شده
    final existingSport = await _sportRepository.getSport(sportId);
    if (existingSport != null) {
      return existingSport;
    }

    // ایجاد سطوح عملکرد پیش‌فرض
    final performanceRatings = [
      PerformanceRating(
        id: 'rating_excellent',
        name: 'عالی',
        order: 1,
        color: '#4CAF50', // سبز
      ),
      PerformanceRating(
        id: 'rating_good',
        name: 'خوب',
        order: 2,
        color: '#2196F3', // آبی
      ),
      PerformanceRating(
        id: 'rating_average',
        name: 'متوسط',
        order: 3,
        color: '#FF9800', // نارنجی
      ),
    ];

    // ایجاد 7 سطح با تکنیک‌ها
    final levels = <Level>[];

    // سطح 1
    levels.add(
      Level(
        id: 'level_1',
        name: 'سطح 1',
        order: 1,
        description: ReportCardTemplate.getSectionTitle('سطح 1'),
        techniques: _createTechniquesFromTemplate(
          'level_1',
          ReportCardTemplate.getLevel1Techniques(),
        ),
      ),
    );

    // سطح 2
    levels.add(
      Level(
        id: 'level_2',
        name: 'سطح 2',
        order: 2,
        description: ReportCardTemplate.getSectionTitle('سطح 2'),
        techniques: _createTechniquesFromTemplate(
          'level_2',
          ReportCardTemplate.getLevel2Techniques(),
        ),
      ),
    );

    // سطح 3
    levels.add(
      Level(
        id: 'level_3',
        name: 'سطح 3',
        order: 3,
        description: ReportCardTemplate.getSectionTitle('سطح 3'),
        techniques: _createTechniquesFromTemplate(
          'level_3',
          ReportCardTemplate.getLevel3Techniques(),
        ),
      ),
    );

    // سطح 4
    levels.add(
      Level(
        id: 'level_4',
        name: 'سطح 4',
        order: 4,
        description: ReportCardTemplate.getSectionTitle('سطح 4'),
        techniques: _createTechniquesFromTemplate(
          'level_4',
          ReportCardTemplate.getLevel4Techniques(),
        ),
      ),
    );

    // سطح 5
    levels.add(
      Level(
        id: 'level_5',
        name: 'سطح 5',
        order: 5,
        description: ReportCardTemplate.getSectionTitle('سطح 5'),
        techniques: _createTechniquesFromTemplate(
          'level_5',
          ReportCardTemplate.getLevel5Techniques(),
        ),
      ),
    );

    // سطح 6
    levels.add(
      Level(
        id: 'level_6',
        name: 'سطح 6',
        order: 6,
        description: ReportCardTemplate.getSectionTitle('سطح 6'),
        techniques: _createTechniquesFromTemplate(
          'level_6',
          ReportCardTemplate.getLevel6Techniques(),
        ),
      ),
    );

    // سطح 7
    levels.add(
      Level(
        id: 'level_7',
        name: 'سطح 7',
        order: 7,
        description: ReportCardTemplate.getSectionTitle('سطح 7'),
        techniques: _createTechniquesFromTemplate(
          'level_7',
          ReportCardTemplate.getLevel7Techniques(),
        ),
      ),
    );

    // ایجاد Sport
    final sport = Sport(
      id: sportId,
      name: 'شنا',
      description: 'رشته شنا با 7 سطح و 63 تکنیک',
      levels: levels,
      performanceRatings: performanceRatings,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isDefault: true,
    );

    // ذخیره Sport
    await _sportRepository.saveSport(sport);

    return sport;
  }

  /// تبدیل TechniqueEvaluation های قدیمی به Technique های جدید
  List<Technique> _createTechniquesFromTemplate(
    String levelId,
    List<TechniqueEvaluation> oldTechniques,
  ) {
    return oldTechniques.map((oldTech) {
      return Technique(
        id: '${levelId}_tech_${oldTech.number}',
        name: oldTech.techniqueName!,
        order: oldTech.number!,
        description: null,
      );
    }).toList();
  }

  /// مهاجرت کارنامه‌های موجود به ساختار جدید
  Future<void> migrateReportCards(Sport defaultSport) async {
    final reportCards = await _reportCardRepository.loadAllReportCards();

    for (final oldReportCard in reportCards) {
      // فقط کارنامه‌هایی که هنوز migrate نشده‌اند
      if (oldReportCard.sections != null &&
          oldReportCard.sections!.isNotEmpty &&
          oldReportCard.sportId == null) {
        try {
          // تبدیل sections به levelEvaluations
          final levelEvaluations = <String, LevelEvaluation>{};

          for (final entry in oldReportCard.sections!.entries) {
            final sectionName = entry.key; // مثلاً "سطح 1"
            final sectionEval = entry.value;

            // پیدا کردن Level مربوطه در Sport
            final level = defaultSport.levels.firstWhere(
              (l) => l.name == sectionName,
              orElse: () => defaultSport.levels.first,
            );

            // تبدیل TechniqueEvaluation های قدیمی به جدید
            final techniqueEvaluations = <String, TechniqueEvaluation>{};

            for (final oldTechEval in sectionEval.techniques) {
              // پیدا کردن Technique مربوطه
              final technique = level.techniques.firstWhere(
                (t) => t.name == oldTechEval.techniqueName,
                orElse: () => level.techniques.first,
              );

              // تبدیل performanceLevel به performanceRatingId
              String? performanceRatingId;
              if (oldTechEval.performanceLevel != null) {
                switch (oldTechEval.performanceLevel) {
                  case 'excellent':
                  case 'عالی':
                    performanceRatingId = 'rating_excellent';
                    break;
                  case 'good':
                  case 'خوب':
                    performanceRatingId = 'rating_good';
                    break;
                  case 'average':
                  case 'متوسط':
                    performanceRatingId = 'rating_average';
                    break;
                }
              }

              // ایجاد TechniqueEvaluation جدید
              techniqueEvaluations[technique.id] = TechniqueEvaluation(
                techniqueId: technique.id,
                performanceRatingId: performanceRatingId,
                // حفظ فیلدهای قدیمی برای سازگاری
                number: oldTechEval.number,
                techniqueName: oldTechEval.techniqueName,
                performanceLevel: oldTechEval.performanceLevel,
              );
            }

            // ایجاد LevelEvaluation
            levelEvaluations[level.id] = LevelEvaluation(
              levelId: level.id,
              techniqueEvaluations: techniqueEvaluations,
            );
          }

          // ایجاد ReportCard جدید
          final newReportCard = oldReportCard.copyWith(
            sportId: defaultSport.id,
            levelEvaluations: levelEvaluations,
            // حفظ sections برای سازگاری
            sections: oldReportCard.sections,
          );

          // ذخیره کارنامه به‌روزرسانی شده
          await _reportCardRepository.saveReportCard(newReportCard);

          print('کارنامه ${newReportCard.studentId} با موفقیت مهاجرت یافت');
        } catch (e) {
          print('خطا در مهاجرت کارنامه ${oldReportCard.studentId}: $e');
          // ادامه به کارنامه بعدی
        }
      }
    }
  }
}
