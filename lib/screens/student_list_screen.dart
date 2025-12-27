import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../viewmodels/student_viewmodel.dart';
import '../viewmodels/report_card_viewmodel.dart';
import '../widgets/drop_zone.dart';

enum ImportAction { append, replace }

class StudentListScreen extends ConsumerStatefulWidget {
  final VoidCallback? onStudentSelected;
  final String? selectedSportId;

  const StudentListScreen({
    super.key,
    this.onStudentSelected,
    this.selectedSportId,
  });

  @override
  ConsumerState<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends ConsumerState<StudentListScreen> {
  @override
  void initState() {
    super.initState();
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
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null) {
      return _buildErrorState(state);
    }

    if (state.students.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        _buildStats(state),
        const Divider(height: 1),
        Expanded(child: _buildStudentList(state)),
      ],
    );
  }

  Widget _buildErrorState(StudentState state) {
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
            onPressed: () => ref.read(studentProvider.notifier).clearError(),
            icon: const Icon(Icons.refresh),
            label: const Text('تلاش مجدد'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ناحیه drag & drop
            FileDropArea(
              allowedExtensions: const ['xlsx', 'xls', 'csv'],
              onFileSelected: (filePath) => _handleFileSelected(filePath),
              title: 'فایل Excel را انتخاب کنید',
              subtitle: 'کلیک کنید یا فایل را بکشید',
              icon: Icons.upload_file,
              height: 180,
            ),
            const SizedBox(height: 16),
            Text(
              'هیچ دانش‌آموزی وجود ندارد',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'برای شروع، فایل Excel لیست دانش‌آموزان را بارگذاری کنید',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleFileSelected(String filePath) async {
    if (!mounted) return;

    // اگر لیست دانش‌آموز وجود داره، بپرس چیکار کنه
    bool shouldAppend = false;
    final currentStudents = ref.read(studentProvider).students;

    if (currentStudents.isNotEmpty) {
      final action = await _showImportOptionsDialog();
      if (action == null) return;
      shouldAppend = action == ImportAction.append;
    }

    _showLoadingDialog();

    await ref
        .read(studentProvider.notifier)
        .importFromExcel(filePath, append: shouldAppend);

    if (!mounted) return;
    Navigator.of(context).pop();

    final state = ref.read(studentProvider);
    if (state.errorMessage == null && state.students.isNotEmpty) {
      final message = shouldAppend
          ? 'دانش‌آموزان جدید اضافه شدند. مجموع: ${state.students.length} نفر'
          : '${state.students.length} دانش‌آموز بارگذاری شد';
      _showSuccessSnackBar(message);
    }
  }

  void _showLoadingDialog() {
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
  }

  Widget _buildStats(StudentState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _buildStatChip(Icons.people, '${state.students.length}', 'کل'),
          const SizedBox(width: 12),
          _buildStatChip(
            Icons.check_circle,
            '${state.completedCount}',
            'تکمیل',
            Colors.green,
          ),
          const SizedBox(width: 12),
          _buildStatChip(
            Icons.pending,
            '${state.students.length - state.completedCount}',
            'در انتظار',
            Colors.orange,
          ),
          const Spacer(),
          _buildProgressIndicator(state),
        ],
      ),
    );
  }

  Widget _buildStatChip(
    IconData icon,
    String value,
    String label, [
    Color? color,
  ]) {
    final chipColor = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: chipColor),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, color: chipColor),
          ),
          const SizedBox(width: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(StudentState state) {
    return SizedBox(
      width: 100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${state.completionPercentage.toStringAsFixed(0)}%',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: state.completionPercentage / 100,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest,
          ),
        ],
      ),
    );
  }

  Widget _buildStudentList(StudentState state) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: state.students.length,
      itemBuilder: (context, index) {
        final student = state.students[index];
        final isSelected = state.selectedIndex == index;

        return Card(
          elevation: isSelected ? 3 : 1,
          margin: const EdgeInsets.only(bottom: 8),
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : null,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: CircleAvatar(
              backgroundColor: student.isCompleted
                  ? Colors.green.withValues(alpha: 0.2)
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Icon(
                student.isCompleted ? Icons.check : Icons.person,
                color: student.isCompleted
                    ? Colors.green
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            title: Text(
              student.name,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              student.isCompleted ? 'کارنامه تکمیل شده' : 'در انتظار تکمیل',
              style: TextStyle(
                color: student.isCompleted
                    ? Colors.green
                    : Theme.of(context).colorScheme.outline,
                fontSize: 12,
              ),
            ),
            trailing: const Icon(Icons.chevron_left),
            onTap: () => _openReportCard(index, student.id, student.name),
          ),
        );
      },
    );
  }

  void _openReportCard(int index, String studentId, String studentName) {
    // انتخاب دانش‌آموز
    ref.read(studentProvider.notifier).selectStudent(index);

    // بارگذاری کارنامه با رشته ورزشی انتخاب شده
    ref
        .read(reportCardProvider.notifier)
        .loadReportCard(
          studentId,
          studentName,
          sportId: widget.selectedSportId,
        );

    // اطلاع به parent برای تغییر تب (اگر callback داده شده)
    if (widget.onStudentSelected != null) {
      widget.onStudentSelected!();
    }
  }

  Future<void> _importExcel() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'csv'],
        dialogTitle: 'انتخاب فایل Excel یا CSV',
      );

      if (result != null && result.files.single.path != null) {
        await _handleFileSelected(result.files.single.path!);
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('خطا در انتخاب فایل: ${e.toString()}');
    }
  }

  Future<ImportAction?> _showImportOptionsDialog() async {
    return showDialog<ImportAction>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('بارگذاری فایل جدید'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'شما در حال حاضر ${ref.read(studentProvider).students.length} دانش‌آموز دارید.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            const Text('چه کاری انجام دهم؟'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('انصراف'),
          ),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pop(ImportAction.append),
            icon: const Icon(Icons.add),
            label: const Text('اضافه کردن به لیست'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(ImportAction.replace),
            icon: const Icon(Icons.sync),
            label: const Text('جایگزینی کامل'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteAllDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف همه دانش‌آموزان'),
        content: const Text('آیا مطمئن هستید؟ این عمل قابل بازگشت نیست!'),
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
      if (mounted) _showSuccessSnackBar('همه دانش‌آموزان حذف شدند');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
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
}
