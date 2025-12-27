import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../viewmodels/report_card_viewmodel.dart';
import '../viewmodels/student_viewmodel.dart';
import '../viewmodels/app_data_viewmodel.dart';
import '../models/models.dart';
import '../widgets/drop_zone.dart';

// Intent classes for keyboard shortcuts
class _PreviousStudentIntent extends Intent {
  const _PreviousStudentIntent();
}

class _NextStudentIntent extends Intent {
  const _NextStudentIntent();
}

class _SaveIntent extends Intent {
  const _SaveIntent();
}

class ReportCardScreen extends ConsumerWidget {
  const ReportCardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportCardState = ref.watch(reportCardProvider);
    final studentState = ref.watch(studentProvider);

    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        const SingleActivator(LogicalKeyboardKey.arrowLeft):
            const _PreviousStudentIntent(),
        const SingleActivator(LogicalKeyboardKey.arrowRight):
            const _NextStudentIntent(),
        const SingleActivator(LogicalKeyboardKey.keyS, control: true):
            const _SaveIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _PreviousStudentIntent: CallbackAction<_PreviousStudentIntent>(
            onInvoke: (_) {
              if (studentState.selectedIndex != null &&
                  studentState.selectedIndex! > 0) {
                _navigateToPrevious(ref);
              }
              return null;
            },
          ),
          _NextStudentIntent: CallbackAction<_NextStudentIntent>(
            onInvoke: (_) {
              if (studentState.selectedIndex != null &&
                  studentState.selectedIndex! <
                      studentState.students.length - 1) {
                _navigateToNext(ref);
              }
              return null;
            },
          ),
          _SaveIntent: CallbackAction<_SaveIntent>(
            onInvoke: (_) {
              ref.read(reportCardProvider.notifier).saveReportCard();
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            appBar: AppBar(
              title: _buildAppBarTitle(studentState),
              actions: [
                if (reportCardState.currentReportCard != null)
                  IconButton(
                    icon: const Icon(Icons.save),
                    tooltip: 'ذخیره (Ctrl+S)',
                    onPressed: () {
                      ref.read(reportCardProvider.notifier).saveReportCard();
                    },
                  ),
              ],
            ),
            body: _buildBody(context, ref, reportCardState, studentState),
            bottomNavigationBar: studentState.students.isNotEmpty
                ? _buildNavigationBar(context, ref, studentState)
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildAppBarTitle(StudentState studentState) {
    if (studentState.selectedStudent == null) {
      return const Text('کارنامه');
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('کارنامه'),
        Text(
          '${studentState.selectedIndex! + 1} از ${studentState.students.length}',
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildNavigationBar(
    BuildContext context,
    WidgetRef ref,
    StudentState studentState,
  ) {
    final canGoPrevious =
        studentState.selectedIndex != null && studentState.selectedIndex! > 0;
    final canGoNext =
        studentState.selectedIndex != null &&
        studentState.selectedIndex! < studentState.students.length - 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Previous Button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: canGoPrevious ? () => _navigateToPrevious(ref) : null,
              icon: const Icon(Icons.arrow_back),
              label: const Text('دانش‌آموز قبلی'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Student Info
          if (studentState.selectedStudent != null)
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      studentState.selectedStudent!.name,
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${studentState.selectedIndex! + 1} از ${studentState.students.length}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(width: 16),

          // Next Button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: canGoNext ? () => _navigateToNext(ref) : null,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('دانش‌آموز بعدی'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToPrevious(WidgetRef ref) {
    final studentNotifier = ref.read(studentProvider.notifier);
    final reportCardNotifier = ref.read(reportCardProvider.notifier);
    final currentSportId = ref.read(reportCardProvider).selectedSport?.id;

    // ذخیره کارنامه فعلی
    reportCardNotifier.saveReportCard();

    // رفتن به دانش‌آموز قبلی
    studentNotifier.selectPreviousStudent();

    // بارگذاری کارنامه جدید با همان رشته ورزشی
    final selectedStudent = ref.read(studentProvider).selectedStudent;
    if (selectedStudent != null) {
      reportCardNotifier.loadReportCard(
        selectedStudent.id,
        selectedStudent.name,
        sportId: currentSportId,
      );
    }
  }

  void _navigateToNext(WidgetRef ref) {
    final studentNotifier = ref.read(studentProvider.notifier);
    final reportCardNotifier = ref.read(reportCardProvider.notifier);
    final currentSportId = ref.read(reportCardProvider).selectedSport?.id;

    // ذخیره کارنامه فعلی
    reportCardNotifier.saveReportCard();

    // رفتن به دانش‌آموز بعدی
    studentNotifier.selectNextStudent();

    // بارگذاری کارنامه جدید با همان رشته ورزشی
    final selectedStudent = ref.read(studentProvider).selectedStudent;
    if (selectedStudent != null) {
      reportCardNotifier.loadReportCard(
        selectedStudent.id,
        selectedStudent.name,
        sportId: currentSportId,
      );
    }
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    ReportCardState reportCardState,
    StudentState studentState,
  ) {
    // Loading
    if (reportCardState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // No student selected
    if (studentState.selectedStudent == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 80,
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'هیچ دانش‌آموزی انتخاب نشده',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'لطفاً از بخش دانش‌آموزان، یک دانش‌آموز را انتخاب کنید',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // No report card
    if (reportCardState.currentReportCard == null) {
      return const Center(child: Text('کارنامه بارگذاری نشد'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Section
          _buildHeaderSection(context, ref, reportCardState.currentReportCard!),
          const SizedBox(height: 24),

          // Attendance Section
          _buildAttendanceSection(
            context,
            ref,
            reportCardState.currentReportCard!,
          ),
          const SizedBox(height: 24),

          // Techniques Sections
          _buildTechniquesSections(
            context,
            ref,
            reportCardState.currentReportCard!,
          ),

          const SizedBox(height: 24),

          // Comments Section
          _buildCommentsSection(
            context,
            ref,
            reportCardState.currentReportCard!,
          ),
          const SizedBox(height: 24),

          // Signature Section
          _buildSignatureSection(
            context,
            ref,
            reportCardState.currentReportCard!,
          ),
          const SizedBox(height: 24),

          // Progress Info
          _buildProgressInfo(context, reportCardState),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(
    BuildContext context,
    WidgetRef ref,
    ReportCard reportCard,
  ) {
    final appData = ref.watch(appDataProvider);
    final reportCardState = ref.watch(reportCardProvider);
    final selectedSport = reportCardState.selectedSport;

    return Card(
      key: ValueKey(reportCard.studentInfo.name),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'اطلاعات دانش‌آموز',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                // نمایش رشته ورزشی
                if (selectedSport != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blue),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.sports, size: 16, color: Colors.blue),
                        const SizedBox(width: 6),
                        Text(
                          selectedSport.name,
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // نام دانش‌آموز (read-only)
            TextFormField(
              key: ValueKey('name_${reportCard.studentInfo.name}'),
              initialValue: reportCard.studentInfo.name,
              decoration: const InputDecoration(
                labelText: 'نام دانش‌آموز',
                prefixIcon: Icon(Icons.person),
              ),
              readOnly: true,
            ),
            const SizedBox(height: 16),

            // مقطع
            DropdownButtonFormField<String>(
              key: ValueKey('grade_${reportCard.studentInfo.name}'),
              initialValue: reportCard.studentInfo.grade?.isNotEmpty == true
                  ? reportCard.studentInfo.grade
                  : null,
              decoration: const InputDecoration(
                labelText: 'مقطع',
                hintText: 'انتخاب مقطع',
                prefixIcon: Icon(Icons.school),
              ),
              items: appData.grades
                  .map(
                    (grade) =>
                        DropdownMenuItem(value: grade, child: Text(grade)),
                  )
                  .toList(),
              onChanged: (value) {
                ref
                    .read(reportCardProvider.notifier)
                    .updateStudentInfo(grade: value);
              },
            ),
            const SizedBox(height: 16),

            // پایه
            DropdownButtonFormField<String>(
              key: ValueKey('level_${reportCard.studentInfo.name}'),
              initialValue: reportCard.studentInfo.level?.isNotEmpty == true
                  ? reportCard.studentInfo.level
                  : null,
              decoration: const InputDecoration(
                labelText: 'پایه',
                hintText: 'انتخاب پایه',
                prefixIcon: Icon(Icons.grade),
              ),
              items: appData.levels
                  .map(
                    (level) =>
                        DropdownMenuItem(value: level, child: Text(level)),
                  )
                  .toList(),
              onChanged: (value) {
                ref
                    .read(reportCardProvider.notifier)
                    .updateStudentInfo(level: value);
              },
            ),
            const SizedBox(height: 16),

            // آموزشگاه
            DropdownButtonFormField<String>(
              key: ValueKey('school_${reportCard.studentInfo.name}'),
              initialValue: reportCard.studentInfo.school?.isNotEmpty == true
                  ? reportCard.studentInfo.school
                  : null,
              decoration: const InputDecoration(
                labelText: 'آموزشگاه',
                hintText: 'انتخاب آموزشگاه',
                prefixIcon: Icon(Icons.business),
              ),
              items: appData.schools
                  .map(
                    (school) =>
                        DropdownMenuItem(value: school, child: Text(school)),
                  )
                  .toList(),
              onChanged: (value) {
                ref
                    .read(reportCardProvider.notifier)
                    .updateStudentInfo(school: value);
              },
            ),
            const SizedBox(height: 16),

            // سرمربی
            DropdownButtonFormField<String>(
              key: ValueKey('headCoach_${reportCard.studentInfo.name}'),
              initialValue: reportCard.studentInfo.headCoach?.isNotEmpty == true
                  ? reportCard.studentInfo.headCoach
                  : null,
              decoration: const InputDecoration(
                labelText: 'سرمربی',
                hintText: 'انتخاب سرمربی',
                prefixIcon: Icon(Icons.sports),
              ),
              items: appData.headCoaches
                  .map(
                    (headCoach) => DropdownMenuItem(
                      value: headCoach,
                      child: Text(headCoach),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                ref
                    .read(reportCardProvider.notifier)
                    .updateStudentInfo(headCoach: value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceSection(
    BuildContext context,
    WidgetRef ref,
    ReportCard reportCard,
  ) {
    final reportCardState = ref.watch(reportCardProvider);
    final selectedSport = reportCardState.selectedSport;

    return Card(
      key: ValueKey('attendance_${reportCard.studentInfo.name}'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'اطلاعات حضور و عملکرد',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                // تعداد جلسات
                Expanded(
                  child: TextFormField(
                    key: ValueKey(
                      'totalSessions_${reportCard.studentInfo.name}',
                    ),
                    initialValue: reportCard.attendanceInfo.totalSessions
                        .toString(),
                    decoration: const InputDecoration(
                      labelText: 'تعداد جلسات',
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final sessions = int.tryParse(value);
                      if (sessions != null) {
                        ref
                            .read(reportCardProvider.notifier)
                            .updateAttendanceInfo(totalSessions: sessions);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),

                // جلسات حاضر
                Expanded(
                  child: TextFormField(
                    key: ValueKey(
                      'attendedSessions_${reportCard.studentInfo.name}',
                    ),
                    initialValue: reportCard.attendanceInfo.attendedSessions
                        .toString(),
                    decoration: const InputDecoration(
                      labelText: 'جلسات حاضر',
                      prefixIcon: Icon(Icons.check_circle),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final sessions = int.tryParse(value);
                      if (sessions != null) {
                        ref
                            .read(reportCardProvider.notifier)
                            .updateAttendanceInfo(attendedSessions: sessions);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),

                // سطح عملکرد
                Expanded(
                  child: DropdownButtonFormField<String>(
                    key: ValueKey(
                      'performanceLevel_${reportCard.studentInfo.name}_${selectedSport?.id}',
                    ),
                    value:
                        _isValidPerformanceLevel(
                          reportCard.attendanceInfo.performanceLevel,
                          selectedSport,
                        )
                        ? reportCard.attendanceInfo.performanceLevel
                        : null,
                    decoration: const InputDecoration(
                      labelText: 'سطح عملکرد',
                      prefixIcon: Icon(Icons.emoji_events),
                    ),
                    items:
                        selectedSport?.levels.map((level) {
                          return DropdownMenuItem<String>(
                            value: level.name,
                            child: Text(level.name),
                          );
                        }).toList() ??
                        [],
                    onChanged: (value) {
                      ref
                          .read(reportCardProvider.notifier)
                          .updateAttendanceInfo(performanceLevel: value ?? '');
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTechniquesSections(
    BuildContext context,
    WidgetRef ref,
    ReportCard reportCard,
  ) {
    final reportCardState = ref.watch(reportCardProvider);
    final selectedSport = reportCardState.selectedSport;

    if (selectedSport == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              'رشته ورزشی بارگذاری نشده است',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
      );
    }

    // مرتب‌سازی سطوح بر اساس order
    final sortedLevels = List<Level>.from(selectedSport.levels)
      ..sort((a, b) => a.order.compareTo(b.order));

    // سطح عملکرد انتخاب شده
    final selectedPerformanceLevel = reportCard.attendanceInfo.performanceLevel;

    return Column(
      children: sortedLevels.map((level) {
        final levelEvaluation = reportCard.levelEvaluations?[level.id];
        final isActive = selectedPerformanceLevel == level.name;

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildLevelCard(
            context,
            ref,
            level,
            levelEvaluation,
            selectedSport,
            isActive: isActive,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLevelCard(
    BuildContext context,
    WidgetRef ref,
    Level level,
    LevelEvaluation? levelEvaluation,
    Sport sport, {
    required bool isActive,
  }) {
    // مرتب‌سازی تکنیک‌ها بر اساس order
    final sortedTechniques = List<Technique>.from(level.techniques)
      ..sort((a, b) => a.order.compareTo(b.order));

    // محاسبه تعداد تکنیک‌های ارزیابی شده
    int evaluatedCount = 0;
    if (levelEvaluation != null) {
      for (final technique in sortedTechniques) {
        final techEval = levelEvaluation.techniqueEvaluations[technique.id];
        if (techEval?.performanceRatingId != null) {
          evaluatedCount++;
        }
      }
    }

    // یافتن تکنیک‌های orphaned (حذف شده)
    final orphanedTechniques = <String, TechniqueEvaluation>{};
    if (levelEvaluation != null) {
      for (final entry in levelEvaluation.techniqueEvaluations.entries) {
        final techniqueId = entry.key;
        final evaluation = entry.value;
        // اگر تکنیک در لیست فعلی نیست، orphaned است
        if (!sortedTechniques.any((t) => t.id == techniqueId)) {
          orphanedTechniques[techniqueId] = evaluation;
        }
      }
    }

    return Opacity(
      opacity: isActive ? 1.0 : 0.5,
      child: Card(
        color: isActive ? null : Colors.grey.shade100,
        child: ExpansionTile(
          enabled: isActive,
          initiallyExpanded: isActive,
          title: Row(
            children: [
              if (isActive)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, size: 16, color: Colors.white),
                ),
              Expanded(
                child: Text(
                  level.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isActive ? null : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$evaluatedCount از ${sortedTechniques.length} تکنیک ارزیابی شده',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isActive ? null : Colors.grey,
                  ),
                ),
                if (orphanedTechniques.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '⚠️ ${orphanedTechniques.length} تکنیک حذف شده',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // تکنیک‌های فعال
                  ...sortedTechniques.map((technique) {
                    final techEval =
                        levelEvaluation?.techniqueEvaluations[technique.id];
                    return _buildTechniqueRow(
                      context,
                      ref,
                      level.id,
                      technique,
                      techEval,
                      sport,
                    );
                  }),
                  // تکنیک‌های orphaned
                  if (orphanedTechniques.isNotEmpty) ...[
                    const Divider(height: 32),
                    Text(
                      'تکنیک‌های حذف شده',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...orphanedTechniques.entries.map((entry) {
                      return _buildOrphanedTechniqueRow(
                        context,
                        ref,
                        level.id,
                        entry.key,
                        entry.value,
                        sport,
                      );
                    }),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTechniqueRow(
    BuildContext context,
    WidgetRef ref,
    String levelId,
    Technique technique,
    TechniqueEvaluation? evaluation,
    Sport sport,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // شماره
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                technique.order.toString(),
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // نام تکنیک
          Expanded(
            child: Text(
              technique.name,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: 12),

          // Performance Rating Buttons
          _buildPerformanceRatingButtons(
            context,
            ref,
            levelId,
            technique,
            evaluation,
            sport,
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceRatingButtons(
    BuildContext context,
    WidgetRef ref,
    String levelId,
    Technique technique,
    TechniqueEvaluation? evaluation,
    Sport sport,
  ) {
    // مرتب‌سازی performance ratings بر اساس order
    final sortedRatings = List<PerformanceRating>.from(sport.performanceRatings)
      ..sort((a, b) => a.order.compareTo(b.order));

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: sortedRatings.map((rating) {
        return _buildRatingButton(
          context,
          ref,
          levelId,
          technique,
          evaluation,
          rating,
        );
      }).toList(),
    );
  }

  Widget _buildRatingButton(
    BuildContext context,
    WidgetRef ref,
    String levelId,
    Technique technique,
    TechniqueEvaluation? evaluation,
    PerformanceRating rating,
  ) {
    final isSelected = evaluation?.performanceRatingId == rating.id;
    final color = _parseColor(rating.color);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: () {
          ref
              .read(reportCardProvider.notifier)
              .updateTechniqueEvaluationNew(
                levelId: levelId,
                techniqueId: technique.id,
                performanceRatingId: isSelected ? null : rating.id,
              );
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.2) : null,
            border: Border.all(
              color: isSelected ? color : Theme.of(context).dividerColor,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                size: 20,
                color: isSelected
                    ? color
                    : Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(width: 4),
              Text(
                rating.name,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: isSelected ? color : null,
                  fontWeight: isSelected ? FontWeight.bold : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _parseColor(String? colorString) {
    if (colorString == null || colorString.isEmpty) {
      return Colors.grey;
    }

    try {
      // Remove # if present
      final hexColor = colorString.replaceAll('#', '');
      // Parse hex color
      return Color(int.parse('FF$hexColor', radix: 16));
    } catch (e) {
      // Default to grey if parsing fails
      return Colors.grey;
    }
  }

  Widget _buildOrphanedTechniqueRow(
    BuildContext context,
    WidgetRef ref,
    String levelId,
    String techniqueId,
    TechniqueEvaluation evaluation,
    Sport sport,
  ) {
    // یافتن نام performance rating
    String ratingName = 'نامشخص';
    if (evaluation.performanceRatingId != null) {
      final rating = sport.performanceRatings.firstWhere(
        (r) => r.id == evaluation.performanceRatingId,
        orElse: () => PerformanceRating(id: '', name: 'حذف شده', order: 0),
      );
      ratingName = rating.name;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        border: Border.all(color: Colors.orange),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning, color: Colors.orange, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'تکنیک حذف شده',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ارزیابی: $ratingName',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () {
              _showOrphanedTechniqueDialog(context, ref, levelId, techniqueId);
            },
            icon: const Icon(Icons.delete, size: 16),
            label: const Text('حذف'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  void _showOrphanedTechniqueDialog(
    BuildContext context,
    WidgetRef ref,
    String levelId,
    String techniqueId,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف ارزیابی'),
        content: const Text(
          'این تکنیک از رشته ورزشی حذف شده است. آیا می‌خواهید ارزیابی آن را نیز حذف کنید؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('انصراف'),
          ),
          ElevatedButton(
            onPressed: () {
              ref
                  .read(reportCardProvider.notifier)
                  .updateTechniqueEvaluationNew(
                    levelId: levelId,
                    techniqueId: techniqueId,
                    performanceRatingId: null,
                  );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsSection(
    BuildContext context,
    WidgetRef ref,
    ReportCard reportCard,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('توضیحات', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              key: ValueKey('comments_${reportCard.studentInfo.name}'),
              initialValue: reportCard.comments ?? '',
              decoration: const InputDecoration(
                labelText: 'توضیحات و یادداشت‌ها',
                hintText: 'توضیحات مربی درباره عملکرد دانش‌آموز...',
                prefixIcon: Icon(Icons.note),
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
              onChanged: (value) {
                ref.read(reportCardProvider.notifier).updateComments(value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignatureSection(
    BuildContext context,
    WidgetRef ref,
    ReportCard reportCard,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('امضای مدیریت', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            FileDropArea(
              allowedExtensions: const ['jpg', 'jpeg', 'png', 'gif', 'bmp'],
              fileType: FileType.image,

              onFileSelected: (filePath) {
                ref
                    .read(reportCardProvider.notifier)
                    .updateSignatureImage(filePath);
              },
              currentFilePath: reportCard.signatureImagePath,
              onClear: () {
                ref
                    .read(reportCardProvider.notifier)
                    .updateSignatureImage(null);
              },
              title: 'تصویر امضا را انتخاب کنید',
              subtitle: 'کلیک کنید یا تصویر را بکشید',
              icon: Icons.draw,
              height: 180,
            ),
          ],
        ),
      ),
    );
  }

  // بررسی اینکه آیا سطح عملکرد معتبر است
  bool _isValidPerformanceLevel(String? performanceLevel, Sport? sport) {
    if (performanceLevel == null || performanceLevel.isEmpty || sport == null) {
      return false;
    }
    return sport.levels.any((level) => level.name == performanceLevel);
  }

  Widget _buildProgressInfo(BuildContext context, ReportCardState state) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'پیشرفت تکمیل کارنامه',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: state.completionPercentage / 100,
                    backgroundColor: Theme.of(context).colorScheme.surface,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${state.completionPercentage.toStringAsFixed(0)}% تکمیل شده',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
