import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/report_card_viewmodel.dart';
import '../viewmodels/student_viewmodel.dart';
import '../viewmodels/app_data_viewmodel.dart';
import '../models/models.dart';
import '../utils/report_card_template.dart';

class ReportCardScreen extends ConsumerWidget {
  const ReportCardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportCardState = ref.watch(reportCardProvider);
    final studentState = ref.watch(studentProvider);

    return CallbackShortcuts(
      bindings: _buildKeyboardShortcuts(ref, studentState),
      child: Focus(
        autofocus: true,
        child: Scaffold(
          appBar: AppBar(
            title: _buildAppBarTitle(studentState),
            actions: [
              if (reportCardState.currentReportCard != null)
                IconButton(
                  icon: const Icon(Icons.save),
                  tooltip: 'ذخیره',
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
            color: Colors.black.withOpacity(0.1),
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

  Map<ShortcutActivator, VoidCallback> _buildKeyboardShortcuts(
    WidgetRef ref,
    StudentState studentState,
  ) {
    return {
      // Arrow Left: دانش‌آموز قبلی
      const SingleActivator(LogicalKeyboardKey.arrowLeft): () {
        if (studentState.selectedIndex != null &&
            studentState.selectedIndex! > 0) {
          _navigateToPrevious(ref);
        }
      },

      // Arrow Right: دانش‌آموز بعدی
      const SingleActivator(LogicalKeyboardKey.arrowRight): () {
        if (studentState.selectedIndex != null &&
            studentState.selectedIndex! < studentState.students.length - 1) {
          _navigateToNext(ref);
        }
      },

      // Ctrl+S: ذخیره
      const SingleActivator(LogicalKeyboardKey.keyS, control: true): () {
        ref.read(reportCardProvider.notifier).saveReportCard();
      },
    };
  }

  void _navigateToPrevious(WidgetRef ref) {
    final studentNotifier = ref.read(studentProvider.notifier);
    final reportCardNotifier = ref.read(reportCardProvider.notifier);

    // ذخیره کارنامه فعلی
    reportCardNotifier.saveReportCard();

    // رفتن به دانش‌آموز قبلی
    studentNotifier.selectPreviousStudent();

    // بارگذاری کارنامه جدید
    final selectedStudent = ref.read(studentProvider).selectedStudent;
    if (selectedStudent != null) {
      reportCardNotifier.loadReportCard(
        selectedStudent.id,
        selectedStudent.name,
      );
    }
  }

  void _navigateToNext(WidgetRef ref) {
    final studentNotifier = ref.read(studentProvider.notifier);
    final reportCardNotifier = ref.read(reportCardProvider.notifier);

    // ذخیره کارنامه فعلی
    reportCardNotifier.saveReportCard();

    // رفتن به دانش‌آموز بعدی
    studentNotifier.selectNextStudent();

    // بارگذاری کارنامه جدید
    final selectedStudent = ref.read(studentProvider).selectedStudent;
    if (selectedStudent != null) {
      reportCardNotifier.loadReportCard(
        selectedStudent.id,
        selectedStudent.name,
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
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
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

    return Card(
      key: ValueKey(reportCard.studentInfo.name),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'اطلاعات دانش‌آموز',
              style: Theme.of(context).textTheme.titleLarge,
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
              key: ValueKey(
                'grade_${reportCard.studentInfo.name}_${reportCard.studentInfo.grade}',
              ),
              value: reportCard.studentInfo.grade?.isNotEmpty == true
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
              key: ValueKey(
                'level_${reportCard.studentInfo.name}_${reportCard.studentInfo.level}',
              ),
              value: reportCard.studentInfo.level?.isNotEmpty == true
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
              key: ValueKey(
                'school_${reportCard.studentInfo.name}_${reportCard.studentInfo.school}',
              ),
              value: reportCard.studentInfo.school?.isNotEmpty == true
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
              key: ValueKey(
                'headCoach_${reportCard.studentInfo.name}_${reportCard.studentInfo.headCoach}',
              ),
              value: reportCard.studentInfo.headCoach?.isNotEmpty == true
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
                      'totalSessions_${reportCard.studentInfo.name}_${reportCard.attendanceInfo.totalSessions}',
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
                      'attendedSessions_${reportCard.studentInfo.name}_${reportCard.attendanceInfo.attendedSessions}',
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

                // ردیف عملکرد
                Expanded(
                  child: TextFormField(
                    key: ValueKey(
                      'performanceRank_${reportCard.studentInfo.name}_${reportCard.attendanceInfo.performanceRank}',
                    ),
                    initialValue: reportCard.attendanceInfo.performanceRank
                        .toString(),
                    decoration: const InputDecoration(
                      labelText: 'ردیف عملکرد',
                      prefixIcon: Icon(Icons.emoji_events),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final rank = int.tryParse(value);
                      if (rank != null) {
                        ref
                            .read(reportCardProvider.notifier)
                            .updateAttendanceInfo(performanceRank: rank);
                      }
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
    final sectionNames = ReportCardTemplate.getSectionNames();

    return Column(
      children: sectionNames.map((sectionName) {
        final section = reportCard.sections[sectionName];
        if (section == null) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildSectionCard(context, ref, sectionName, section),
        );
      }).toList(),
    );
  }

  Widget _buildSectionCard(
    BuildContext context,
    WidgetRef ref,
    String sectionName,
    SectionEvaluation section,
  ) {
    return Card(
      child: ExpansionTile(
        title: Text(
          sectionName,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(
          '${section.techniques.where((t) => t.level != null).length} از ${section.techniques.length} تکنیک ارزیابی شده',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: section.techniques.map((technique) {
                return _buildTechniqueRow(context, ref, sectionName, technique);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechniqueRow(
    BuildContext context,
    WidgetRef ref,
    String sectionName,
    TechniqueEvaluation technique,
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
                technique.number.toString(),
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // نام تکنیک
          Expanded(
            child: Text(
              technique.techniqueName,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: 12),

          // Radio Buttons
          _buildPerformanceRadios(context, ref, sectionName, technique),
        ],
      ),
    );
  }

  Widget _buildPerformanceRadios(
    BuildContext context,
    WidgetRef ref,
    String sectionName,
    TechniqueEvaluation technique,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildRadioButton(
          context,
          ref,
          sectionName,
          technique,
          PerformanceLevel.excellent,
          'عالی',
          Colors.green,
        ),
        _buildRadioButton(
          context,
          ref,
          sectionName,
          technique,
          PerformanceLevel.good,
          'خوب',
          Colors.blue,
        ),
        _buildRadioButton(
          context,
          ref,
          sectionName,
          technique,
          PerformanceLevel.average,
          'متوسط',
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildRadioButton(
    BuildContext context,
    WidgetRef ref,
    String sectionName,
    TechniqueEvaluation technique,
    PerformanceLevel level,
    String label,
    Color color,
  ) {
    final isSelected = technique.level == level;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: () {
          ref
              .read(reportCardProvider.notifier)
              .updateTechniqueEvaluation(
                sectionName: sectionName,
                techniqueNumber: technique.number,
                performanceLevel: isSelected ? null : level,
              );
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.2) : null,
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
                label,
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
