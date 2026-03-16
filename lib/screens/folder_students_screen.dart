import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../viewmodels/folder_viewmodel.dart';
import '../viewmodels/report_card_viewmodel.dart';
import '../viewmodels/navigation_viewmodel.dart';
import '../models/models.dart';
import '../services/excel_import_service.dart';
import '../widgets/drop_zone.dart';
import '../utils/id_generator.dart';

class FolderStudentsScreen extends ConsumerStatefulWidget {
  final String folderId;
  final String? selectedSportId;
  final VoidCallback? onStudentSelected;

  const FolderStudentsScreen({
    super.key,
    required this.folderId,
    this.selectedSportId,
    this.onStudentSelected,
  });

  @override
  ConsumerState<FolderStudentsScreen> createState() =>
      _FolderStudentsScreenState();
}

class _FolderStudentsScreenState extends ConsumerState<FolderStudentsScreen> {
  int? _selectedStudentIndex;

  @override
  void initState() {
    super.initState();
    // پاک کردن navigation state وقتی وارد پوشه جدید میشیم
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(navigationProvider.notifier).clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final folderState = ref.watch(folderProvider);
    final folder = folderState.folders
        .where((f) => f.id == widget.folderId)
        .firstOrNull;

    if (folder == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('پوشه یافت نشد')),
        body: const Center(child: Text('پوشه مورد نظر یافت نشد')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(folder.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'اضافه کردن دانش‌آموز',
            onPressed: () => _showAddStudentDialog(folder),
          ),
        ],
      ),
      body: _buildBody(folder),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: "add_student",
            onPressed: () => _showAddStudentDialog(folder),
            child: const Icon(Icons.person_add),
            tooltip: 'اضافه کردن دانش‌آموز',
          ),
          const SizedBox(height: 8),
          FloatingActionButton.extended(
            heroTag: "import_file",
            onPressed: () => _importExcel(folder),
            icon: const Icon(Icons.upload_file),
            label: const Text('بارگذاری فایل'),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(Folder folder) {
    if (folder.students.isEmpty) {
      return _buildEmptyState(folder);
    }

    return Column(
      children: [
        _buildStats(folder),
        const Divider(height: 1),
        Expanded(child: _buildStudentList(folder)),
      ],
    );
  }

  Widget _buildEmptyState(Folder folder) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FileDropArea(
              allowedExtensions: const ['xlsx', 'xls', 'csv'],
              onFileSelected: (filePath) =>
                  _handleFileSelected(filePath, folder),
              title: 'فایل Excel را انتخاب کنید',
              subtitle: 'کلیک کنید یا فایل را بکشید',
              icon: Icons.upload_file,
              height: 180,
            ),
            const SizedBox(height: 24),
            const Text(
              'یا',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _showAddStudentDialog(folder),
              icon: const Icon(Icons.person_add),
              label: const Text('اضافه کردن دانش‌آموز جدید'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'این پوشه خالی است',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'برای شروع، فایل Excel لیست دانش‌آموزان را بارگذاری کنید یا دانش‌آموز جدید اضافه کنید',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStats(Folder folder) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _buildStatChip(Icons.people, '${folder.studentCount}', 'کل'),
          const SizedBox(width: 12),
          _buildStatChip(
            Icons.check_circle,
            '${folder.completedCount}',
            'تکمیل',
            Colors.green,
          ),
          const SizedBox(width: 12),
          _buildStatChip(
            Icons.pending,
            '${folder.studentCount - folder.completedCount}',
            'در انتظار',
            Colors.orange,
          ),
          const Spacer(),
          _buildProgressIndicator(folder),
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

  Widget _buildProgressIndicator(Folder folder) {
    return SizedBox(
      width: 100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${folder.completionPercentage.toStringAsFixed(0)}%',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: folder.completionPercentage / 100,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest,
          ),
        ],
      ),
    );
  }

  Widget _buildStudentList(Folder folder) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: folder.students.length,
      itemBuilder: (context, index) {
        final student = folder.students[index];
        final isSelected = _selectedStudentIndex == index;

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
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'حذف دانش‌آموز',
                  onPressed: () => _showDeleteStudentDialog(
                    folder,
                    student.id,
                    student.name,
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
            onTap: () => _openReportCard(index, student.id, student.name),
          ),
        );
      },
    );
  }

  void _openReportCard(int index, String studentId, String studentName) {
    setState(() {
      _selectedStudentIndex = index;
    });

    // تنظیم navigation state
    final folderState = ref.read(folderProvider);
    final folder = folderState.folders.firstWhere(
      (f) => f.id == widget.folderId,
    );

    ref
        .read(navigationProvider.notifier)
        .setStudents(
          folderId: widget.folderId,
          students: folder.students,
          currentStudentId: studentId,
        );

    // اول صفحه رو ببند و به صفحه کارنامه برو
    if (widget.onStudentSelected != null) {
      widget.onStudentSelected!();
    }
    Navigator.of(context).pop();

    // بعد کارنامه رو بارگذاری کن
    Future.microtask(() {
      ref
          .read(reportCardProvider.notifier)
          .loadReportCard(
            studentId,
            studentName,
            sportId: widget.selectedSportId,
          );
    });
  }

  Future<void> _handleFileSelected(String filePath, Folder folder) async {
    if (!mounted) return;

    _showLoadingDialog();

    try {
      final excelService = ExcelImportService();
      final students = await excelService.importStudentsFromExcel(filePath);

      await ref
          .read(folderProvider.notifier)
          .addStudentsToFolder(widget.folderId, students);

      if (!mounted) return;
      Navigator.of(context).pop();

      _showSuccessSnackBar('${students.length} دانش‌آموز به پوشه اضافه شد');
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      _showErrorSnackBar('خطا: ${e.toString()}');
    }
  }

  Future<void> _importExcel(Folder folder) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'csv'],
        dialogTitle: 'انتخاب فایل Excel یا CSV',
      );

      if (result != null && result.files.single.path != null) {
        await _handleFileSelected(result.files.single.path!, folder);
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('خطا در انتخاب فایل: ${e.toString()}');
    }
  }

  Future<void> _showAddStudentDialog(Folder folder) async {
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('اضافه کردن دانش‌آموز جدید'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'نام دانش‌آموز',
              border: OutlineInputBorder(),
            ),
            textDirection: TextDirection.rtl,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'نام دانش‌آموز نمی‌تواند خالی باشد';
              }
              return null;
            },
            autofocus: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('انصراف'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(context).pop(nameController.text.trim());
              }
            },
            child: const Text('اضافه کردن'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final id = IdGenerator.generateStudentId();
      final newStudent = Student(id: id, name: result);

      await ref
          .read(folderProvider.notifier)
          .addStudentToFolder(widget.folderId, newStudent);

      if (mounted) {
        _showSuccessSnackBar('دانش‌آموز "$result" اضافه شد');
      }
    }
  }

  Future<void> _showDeleteStudentDialog(
    Folder folder,
    String studentId,
    String studentName,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف دانش‌آموز'),
        content: Text(
          'آیا مطمئن هستید که می‌خواهید "$studentName" را حذف کنید؟',
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
      await ref
          .read(folderProvider.notifier)
          .removeStudentFromFolder(widget.folderId, studentId);
      if (mounted) _showSuccessSnackBar('دانش‌آموز "$studentName" حذف شد');
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
