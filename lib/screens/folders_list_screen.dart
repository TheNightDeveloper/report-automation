import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/folder_viewmodel.dart';
import '../models/models.dart';
import 'folder_students_screen.dart';

class FoldersListScreen extends ConsumerStatefulWidget {
  final String? selectedSportId;
  final VoidCallback? onStudentSelected;

  const FoldersListScreen({
    super.key,
    this.selectedSportId,
    this.onStudentSelected,
  });

  @override
  ConsumerState<FoldersListScreen> createState() => _FoldersListScreenState();
}

class _FoldersListScreenState extends ConsumerState<FoldersListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(folderProvider.notifier).loadFolders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final folderState = ref.watch(folderProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('پوشه‌های دانش‌آموزان'),
        actions: [
          IconButton(
            icon: const Icon(Icons.create_new_folder),
            tooltip: 'ایجاد پوشه جدید',
            onPressed: _showCreateFolderDialog,
          ),
        ],
      ),
      body: _buildBody(folderState),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateFolderDialog,
        icon: const Icon(Icons.create_new_folder),
        label: const Text('پوشه جدید'),
      ),
    );
  }

  Widget _buildBody(FolderState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null) {
      return _buildErrorState(state);
    }

    if (state.folders.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        _buildOverallStats(state),
        const Divider(height: 1),
        Expanded(child: _buildFolderGrid(state)),
      ],
    );
  }

  Widget _buildErrorState(FolderState state) {
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
            onPressed: () => ref.read(folderProvider.notifier).clearError(),
            icon: const Icon(Icons.refresh),
            label: const Text('تلاش مجدد'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open,
            size: 100,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 24),
          Text(
            'هیچ پوشه‌ای وجود ندارد',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'برای شروع، یک پوشه جدید ایجاد کنید',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _showCreateFolderDialog,
            icon: const Icon(Icons.create_new_folder),
            label: const Text('ایجاد اولین پوشه'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallStats(FolderState state) {
    final totalStudents = state.totalStudents;
    final totalCompleted = state.folders.fold(
      0,
      (sum, folder) => sum + folder.completedCount,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              Icons.folder,
              '${state.folders.length}',
              'پوشه',
              Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              Icons.people,
              '$totalStudents',
              'دانش‌آموز',
              Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              Icons.check_circle,
              '$totalCompleted',
              'تکمیل شده',
              Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildFolderGrid(FolderState state) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 300,
        childAspectRatio: 1.2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: state.folders.length,
      itemBuilder: (context, index) {
        final folder = state.folders[index];
        return _buildFolderCard(folder);
      },
    );
  }

  Widget _buildFolderCard(Folder folder) {
    final completionPercentage = folder.completionPercentage;
    final color = completionPercentage == 100
        ? Colors.green
        : completionPercentage > 50
        ? Colors.orange
        : Theme.of(context).colorScheme.primary;

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => _openFolder(folder),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.folder, size: 40, color: color),
                  const Spacer(),
                  PopupMenuButton(
                    icon: const Icon(Icons.more_vert),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'rename',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 8),
                            Text('تغییر نام'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('حذف', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      switch (value) {
                        case 'rename':
                          _showRenameFolderDialog(folder.id, folder.name);
                          break;
                        case 'delete':
                          _showDeleteFolderDialog(folder.id, folder.name);
                          break;
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                folder.name,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Row(
                children: [
                  Icon(
                    Icons.people,
                    size: 16,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${folder.studentCount} دانش‌آموز',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: completionPercentage / 100,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${completionPercentage.toStringAsFixed(0)}%',
                    style: TextStyle(fontWeight: FontWeight.bold, color: color),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openFolder(Folder folder) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FolderStudentsScreen(
          folderId: folder.id,
          selectedSportId: widget.selectedSportId,
          onStudentSelected: widget.onStudentSelected,
        ),
      ),
    );
  }

  Future<void> _showCreateFolderDialog() async {
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ایجاد پوشه جدید'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'نام پوشه',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.folder),
            ),
            textDirection: TextDirection.rtl,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'نام پوشه نمی‌تواند خالی باشد';
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
            child: const Text('ایجاد'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final folderId = await ref
          .read(folderProvider.notifier)
          .createFolder(result);
      if (mounted) {
        final state = ref.read(folderProvider);
        if (state.errorMessage == null && folderId != null) {
          _showSuccessSnackBar('پوشه "$result" ایجاد شد');
          // باز کردن پوشه جدید
          final folder = state.folders.firstWhere((f) => f.id == folderId);
          _openFolder(folder);
        }
      }
    }
  }

  Future<void> _showRenameFolderDialog(
    String folderId,
    String currentName,
  ) async {
    final nameController = TextEditingController(text: currentName);
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تغییر نام پوشه'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'نام جدید',
              border: OutlineInputBorder(),
            ),
            textDirection: TextDirection.rtl,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'نام پوشه نمی‌تواند خالی باشد';
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
            child: const Text('تغییر نام'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && result != currentName) {
      await ref.read(folderProvider.notifier).renameFolder(folderId, result);
      if (mounted) {
        final state = ref.read(folderProvider);
        if (state.errorMessage == null) {
          _showSuccessSnackBar('نام پوشه تغییر کرد');
        }
      }
    }
  }

  Future<void> _showDeleteFolderDialog(
    String folderId,
    String folderName,
  ) async {
    final folder = ref
        .read(folderProvider)
        .folders
        .firstWhere((f) => f.id == folderId);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف پوشه'),
        content: Text(
          'آیا مطمئن هستید که می‌خواهید پوشه "$folderName" را حذف کنید؟\n\n'
          'این پوشه شامل ${folder.studentCount} دانش‌آموز است.\n'
          'این عمل قابل بازگشت نیست!',
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
      await ref.read(folderProvider.notifier).deleteFolder(folderId);
      if (mounted) {
        _showSuccessSnackBar('پوشه "$folderName" حذف شد');
      }
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
}
