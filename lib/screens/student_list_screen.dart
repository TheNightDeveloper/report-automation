import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../viewmodels/student_viewmodel.dart';
import '../viewmodels/report_card_viewmodel.dart';

class StudentListScreen extends ConsumerStatefulWidget {
  const StudentListScreen({super.key});

  @override
  ConsumerState<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends ConsumerState<StudentListScreen> {
  @override
  void initState() {
    super.initState();
    // بارگذاری لیست دانش‌آموزان
    Future.microtask(() {
      ref.read(studentProvider.notifier).loadStudents();
    });
  }

  @override
  Widget build(BuildContext context) {
    final studentState = ref.watch(studentProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('لیست دانش‌آموزان'),
        actions: [
          // دکمه حذف همه
          if (studentState.students.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'حذف همه دانش‌آموزان',
              onPressed: () => _showDeleteAllDialog(),
            ),
        ],
      ),
      body: _buildBody(studentState),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _importExcel,
        icon: const Icon(Icons.upload_file),
        label: const Text('بارگذاری فایل'),
      ),
    );
  }

  Widget _buildBody(StudentState state) {
    // نمایش Loading
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // نمایش خطا
    if (state.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              state.errorMessage!,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(studentProvider.notifier).clearError();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('تلاش مجدد'),
            ),
          ],
        ),
      );
    }

    // لیست خالی
    if (state.students.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'هیچ دانش‌آموزی وجود ندارد',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'برای شروع، فایل Excel لیست دانش‌آموزان را بارگذاری کنید',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _importExcel,
              icon: const Icon(Icons.upload_file),
              label: const Text('بارگذاری فایل'),
            ),
          ],
        ),
      );
    }

    // نمایش لیست
    return Column(
      children: [
        // آمار
        _buildStats(state),
        const Divider(height: 1),

        // لیست دانش‌آموزان
        Expanded(child: _buildStudentList(state)),
      ],
    );
  }

  Widget _buildStats(StudentState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.people,
              label: 'تعداد کل',
              value: state.students.length.toString(),
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              icon: Icons.check_circle,
              label: 'تکمیل شده',
              value: state.completedCount.toString(),
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              icon: Icons.pending,
              label: 'در انتظار',
              value: (state.students.length - state.completedCount).toString(),
              color: Colors.orange,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              icon: Icons.percent,
              label: 'درصد پیشرفت',
              value: '${state.completionPercentage.toStringAsFixed(0)}%',
              color: Theme.of(context).colorScheme.tertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentList(StudentState state) {
    final responsive = ResponsiveBreakpoints.of(context);
    final crossAxisCount = responsive.largerThan(TABLET)
        ? 3
        : responsive.equals(TABLET)
        ? 2
        : 1;

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: state.students.length,
      itemBuilder: (context, index) {
        final student = state.students[index];
        final isSelected = state.selectedIndex == index;

        return Card(
          elevation: isSelected ? 4 : 1,
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : null,
          child: InkWell(
            onTap: () => _selectStudent(index),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // آیکون وضعیت
                  Icon(
                    student.isCompleted
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: student.isCompleted
                        ? Theme.of(context).colorScheme.secondary
                        : Theme.of(context).colorScheme.outline,
                    size: 32,
                  ),
                  const SizedBox(width: 16),

                  // نام دانش‌آموز
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          student.name,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          student.isCompleted ? 'تکمیل شده' : 'در انتظار',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),

                  // دکمه ویرایش
                  IconButton(
                    icon: const Icon(Icons.edit),
                    tooltip: 'ویرایش کارنامه',
                    onPressed: () => _editReportCard(student.id, student.name),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Import Excel
  Future<void> _importExcel() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'csv'],
        dialogTitle: 'انتخاب فایل Excel یا CSV',
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;

        if (!mounted) return;

        // نمایش progress
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('در حال بارگذاری...'),
                  ],
                ),
              ),
            ),
          ),
        );

        await ref.read(studentProvider.notifier).importFromExcel(filePath);

        if (!mounted) return;
        Navigator.of(context).pop(); // بستن dialog

        final state = ref.read(studentProvider);
        if (state.errorMessage == null) {
          _showSuccessSnackBar(
            'فایل با موفقیت بارگذاری شد. ${state.students.length} دانش‌آموز اضافه شد.',
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // بستن dialog در صورت خطا
      _showErrorSnackBar('خطا در انتخاب فایل: ${e.toString()}');
    }
  }

  void _selectStudent(int index) {
    ref.read(studentProvider.notifier).selectStudent(index);
  }

  void _editReportCard(String studentId, String studentName) {
    // بارگذاری کارنامه
    ref
        .read(reportCardProvider.notifier)
        .loadReportCard(studentId, studentName);

    // رفتن به صفحه کارنامه (تغییر tab در MainScreen)
    // این کار باید از طریق navigation انجام شود
    _showInfoSnackBar(
      'کارنامه $studentName بارگذاری شد. به بخش کارنامه بروید.',
    );
  }

  Future<void> _showDeleteAllDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف همه دانش‌آموزان'),
        content: const Text(
          'آیا مطمئن هستید که می‌خواهید همه دانش‌آموزان و کارنامه‌های آنها را حذف کنید؟\n\nاین عمل قابل بازگشت نیست!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('انصراف'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(studentProvider.notifier).deleteAllStudents();
      if (mounted) {
        _showSuccessSnackBar('همه دانش‌آموزان حذف شدند');
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}
