import 'package:hive_flutter/hive_flutter.dart';
import '../models/models.dart';
import '../repositories/sport_repository.dart';
import '../repositories/report_card_repository.dart';
import '../repositories/folder_repository.dart';
import '../utils/report_card_template.dart';
import '../utils/id_generator.dart';

class MigrationService {
  static const String _migrationBoxName = 'migration_status';
  static const String _migrationKey = 'v2_migration_completed';
  static const String _idMigrationKey = 'v3_id_migration_completed';

  final SportRepository _sportRepository;
  final ReportCardRepository _reportCardRepository;

  MigrationService(this._sportRepository, this._reportCardRepository);

  /// بررسی نیاز به migration ID ها
  Future<bool> needsIdMigration() async {
    try {
      final migrationBox = await Hive.openBox(_migrationBoxName);
      final migrationCompleted =
          migrationBox.get(_idMigrationKey, defaultValue: false) as bool;

      if (migrationCompleted) {
        return false;
      }

      // بررسی وجود دانش‌آموزان با ID های عددی (timestamp)
      final folderRepository = FolderRepository();
      final folders = await folderRepository.loadFolders();

      for (final folder in folders) {
        for (final student in folder.students) {
          // اگر ID فقط عدد باشه، یعنی timestamp هست
          if (int.tryParse(student.id) != null) {
            return true;
          }
        }
      }

      return false;
    } catch (e) {
      print('خطا در بررسی نیاز به migration ID: $e');
      return false;
    }
  }

  /// اجرای migration ID ها
  Future<void> migrateStudentIds() async {
    try {
      print('🔄 شروع migration ID های دانش‌آموزان...');

      final folderRepository = FolderRepository();
      final folders = await folderRepository.loadFolders();

      // Map برای نگه‌داری تبدیل ID های قدیمی به جدید
      // Key: نام دانش‌آموز + ID قدیمی (برای یکتا بودن)
      // Value: ID جدید
      final idMapping = <String, String>{};
      final usedIds = <String>{};
      int migratedCount = 0;

      // مرحله 1: ایجاد ID های جدید و map کردن
      for (final folder in folders) {
        for (final student in folder.students) {
          // فقط ID های عددی (timestamp) رو تبدیل کن
          if (int.tryParse(student.id) != null) {
            // کلید یکتا برای هر دانش‌آموز (نام + ID قدیمی)
            final uniqueKey = '${student.name}_${student.id}';

            if (!idMapping.containsKey(uniqueKey)) {
              // ساخت ID جدید یکتا
              String newId;
              do {
                newId = IdGenerator.generateStudentId();
              } while (usedIds.contains(newId));

              usedIds.add(newId);
              idMapping[uniqueKey] = newId;

              print(
                '  📝 Mapping: ${student.name} - Old ID: ${student.id} -> New ID: $newId',
              );
            }
          }
        }
      }

      if (idMapping.isEmpty) {
        print('✅ هیچ ID ای برای migration وجود ندارد');
        await _markIdMigrationComplete();
        return;
      }

      print('📊 تعداد ID های برای migration: ${idMapping.length}');

      // مرحله 2: به‌روزرسانی پوشه‌ها
      for (final folder in folders) {
        bool folderUpdated = false;
        final updatedStudents = <Student>[];

        for (final student in folder.students) {
          if (int.tryParse(student.id) != null) {
            final uniqueKey = '${student.name}_${student.id}';
            final newId = idMapping[uniqueKey];

            if (newId != null) {
              // ایجاد دانش‌آموز با ID جدید
              final newStudent = Student(
                id: newId,
                name: student.name,
                isCompleted: student.isCompleted,
              );
              updatedStudents.add(newStudent);
              folderUpdated = true;
              migratedCount++;
            } else {
              updatedStudents.add(student);
            }
          } else {
            updatedStudents.add(student);
          }
        }

        if (folderUpdated) {
          final updatedFolder = folder.copyWith(students: updatedStudents);
          await folderRepository.saveFolder(updatedFolder);
          print('  ✅ پوشه "${folder.name}" به‌روزرسانی شد');
        }
      }

      // مرحله 3: به‌روزرسانی کارنامه‌ها
      final reportCards = await _reportCardRepository.loadAllReportCards();
      int reportCardsUpdated = 0;

      // ساخت map از ID قدیمی به نام دانش‌آموز
      final oldIdToName = <String, String>{};
      for (final reportCard in reportCards) {
        if (int.tryParse(reportCard.studentId) != null) {
          oldIdToName[reportCard.studentId] = reportCard.studentInfo.name;
        }
      }

      for (final reportCard in reportCards) {
        if (int.tryParse(reportCard.studentId) != null) {
          final oldId = reportCard.studentId;
          final studentName = reportCard.studentInfo.name;
          final uniqueKey = '${studentName}_$oldId';
          final newId = idMapping[uniqueKey];

          if (newId != null) {
            // ایجاد کارنامه با ID جدید
            final updatedReportCard = reportCard.copyWith(studentId: newId);

            // حذف کارنامه قدیمی
            await _reportCardRepository.deleteReportCard(oldId);

            // ذخیره کارنامه با ID جدید
            await _reportCardRepository.saveReportCard(updatedReportCard);

            reportCardsUpdated++;
            print(
              '  ✅ کارنامه "${reportCard.studentInfo.name}" به‌روزرسانی شد (Old: $oldId -> New: $newId)',
            );
          }
        }
      }

      print('✅ Migration کامل شد:');
      print('   - $migratedCount دانش‌آموز');
      print('   - $reportCardsUpdated کارنامه');

      await _markIdMigrationComplete();
    } catch (e) {
      print('❌ خطا در migration ID ها: $e');
      rethrow;
    }
  }

  /// ذخیره وضعیت migration ID ها
  Future<void> _markIdMigrationComplete() async {
    final migrationBox = await Hive.openBox(_migrationBoxName);
    await migrationBox.put(_idMigrationKey, true);
  }

  /// Reset کردن وضعیت migration ID ها (برای اجرای مجدد)
  Future<void> resetIdMigration() async {
    final migrationBox = await Hive.openBox(_migrationBoxName);
    await migrationBox.put(_idMigrationKey, false);
    print('🔄 وضعیت migration ID ها reset شد');
  }

  /// پیدا کردن و اصلاح ID های تکراری
  Future<void> fixDuplicateIds() async {
    try {
      print('🔍 شروع بررسی ID های تکراری...');

      final folderRepository = FolderRepository();
      final folders = await folderRepository.loadFolders();

      // Map برای شمارش استفاده از هر ID
      final idUsageMap = <String, List<String>>{};

      // جمع‌آوری تمام ID ها و نام دانش‌آموزان
      for (final folder in folders) {
        for (final student in folder.students) {
          if (!idUsageMap.containsKey(student.id)) {
            idUsageMap[student.id] = [];
          }
          idUsageMap[student.id]!.add(student.name);
        }
      }

      // پیدا کردن ID های تکراری
      final duplicateIds = <String, List<String>>{};
      for (final entry in idUsageMap.entries) {
        if (entry.value.length > 1) {
          duplicateIds[entry.key] = entry.value;
        }
      }

      if (duplicateIds.isEmpty) {
        print('✅ هیچ ID تکراری پیدا نشد');
        return;
      }

      print('⚠️ ${duplicateIds.length} ID تکراری پیدا شد:');
      for (final entry in duplicateIds.entries) {
        print('   ID: ${entry.key}');
        print('   دانش‌آموزان: ${entry.value.join(', ')}');
      }

      // Map برای نگه‌داری ID های جدید
      // Key: نام دانش‌آموز + ID قدیمی
      // Value: ID جدید
      final newIdMapping = <String, String>{};
      final usedIds = <String>{};

      // ساخت ID های جدید برای دانش‌آموزان تکراری
      for (final entry in duplicateIds.entries) {
        final duplicateId = entry.key;
        final studentNames = entry.value;

        // اولین دانش‌آموز ID قدیمی رو نگه میداره
        // بقیه ID جدید میگیرن
        for (int i = 1; i < studentNames.length; i++) {
          final studentName = studentNames[i];
          final uniqueKey = '${studentName}_$duplicateId';

          String newId;
          do {
            newId = IdGenerator.generateStudentId();
          } while (usedIds.contains(newId) || idUsageMap.containsKey(newId));

          usedIds.add(newId);
          newIdMapping[uniqueKey] = newId;

          print('  📝 ${studentNames[i]}: $duplicateId -> $newId');
        }
      }

      print('📊 تعداد ID های جدید: ${newIdMapping.length}');

      // به‌روزرسانی پوشه‌ها
      int updatedCount = 0;
      for (final folder in folders) {
        bool folderUpdated = false;
        final updatedStudents = <Student>[];
        final seenIds = <String>{};

        for (final student in folder.students) {
          final uniqueKey = '${student.name}_${student.id}';

          // اگر این دانش‌آموز باید ID جدید بگیره
          if (newIdMapping.containsKey(uniqueKey)) {
            final newId = newIdMapping[uniqueKey]!;
            updatedStudents.add(
              Student(
                id: newId,
                name: student.name,
                isCompleted: student.isCompleted,
              ),
            );
            folderUpdated = true;
            updatedCount++;
            print('  ✅ پوشه "${folder.name}": ${student.name} -> ID جدید');
          }
          // اگر این ID قبلاً دیده شده (تکراری در همین پوشه)
          else if (seenIds.contains(student.id)) {
            String newId;
            do {
              newId = IdGenerator.generateStudentId();
            } while (usedIds.contains(newId) || seenIds.contains(newId));

            usedIds.add(newId);
            seenIds.add(newId);
            updatedStudents.add(
              Student(
                id: newId,
                name: student.name,
                isCompleted: student.isCompleted,
              ),
            );
            folderUpdated = true;
            updatedCount++;
            print(
              '  ✅ پوشه "${folder.name}": ${student.name} -> ID جدید (تکراری در پوشه)',
            );
          } else {
            seenIds.add(student.id);
            updatedStudents.add(student);
          }
        }

        if (folderUpdated) {
          final updatedFolder = folder.copyWith(students: updatedStudents);
          await folderRepository.saveFolder(updatedFolder);
        }
      }

      // به‌روزرسانی کارنامه‌ها
      final reportCards = await _reportCardRepository.loadAllReportCards();
      int reportCardsUpdated = 0;

      // ساخت map از ID به لیست کارنامه‌ها
      final reportCardsByOldId = <String, List<ReportCard>>{};
      for (final reportCard in reportCards) {
        if (!reportCardsByOldId.containsKey(reportCard.studentId)) {
          reportCardsByOldId[reportCard.studentId] = [];
        }
        reportCardsByOldId[reportCard.studentId]!.add(reportCard);
      }

      // به‌روزرسانی کارنامه‌های تکراری
      for (final entry in duplicateIds.entries) {
        final duplicateId = entry.key;
        final studentNames = entry.value;
        final reportCardsWithThisId = reportCardsByOldId[duplicateId] ?? [];

        if (reportCardsWithThisId.isEmpty) continue;

        // برای هر کارنامه، پیدا کردن ID جدید بر اساس نام
        for (final reportCard in reportCardsWithThisId) {
          final studentName = reportCard.studentInfo.name;
          final uniqueKey = '${studentName}_$duplicateId';

          if (newIdMapping.containsKey(uniqueKey)) {
            final newId = newIdMapping[uniqueKey]!;

            // ایجاد کارنامه با ID جدید
            final updatedReportCard = reportCard.copyWith(studentId: newId);

            // ذخیره کارنامه با ID جدید
            await _reportCardRepository.saveReportCard(updatedReportCard);

            reportCardsUpdated++;
            print(
              '  ✅ کارنامه "$studentName" به‌روزرسانی شد: $duplicateId -> $newId',
            );
          }
        }

        // حذف کارنامه قدیمی با ID تکراری
        await _reportCardRepository.deleteReportCard(duplicateId);
      }

      print('✅ اصلاح ID های تکراری کامل شد:');
      print('   - $updatedCount دانش‌آموز');
      print('   - $reportCardsUpdated کارنامه');
    } catch (e) {
      print('❌ خطا در اصلاح ID های تکراری: $e');
      rethrow;
    }
  }

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
