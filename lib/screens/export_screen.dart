import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../viewmodels/export_viewmodel.dart';
import '../viewmodels/student_viewmodel.dart';
import '../viewmodels/report_card_viewmodel.dart';
import '../services/export_service.dart';

class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  ExportFormat _selectedFormat = ExportFormat.pdf;
  bool _exportAll = true;
  final TextEditingController _pathController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDefaultPath();
  }

  @override
  void dispose() {
    _pathController.dispose();
    super.dispose();
  }

  Future<void> _loadDefaultPath() async {
    // مسیر پیش‌فرض: Documents/کارنامه
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final defaultPath = '${docsDir.path}${Platform.pathSeparator}کارنامه';
      final dir = Directory(defaultPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      _pathController.text = defaultPath;
      setState(() {});
    } catch (e) {
      // در صورت خطا، کاربر باید مسیر را انتخاب کند
    }
  }

  @override
  Widget build(BuildContext context) {
    final exportState = ref.watch(exportProvider);
    final studentState = ref.watch(studentProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('خروجی فایل')),
      body: studentState.students.isEmpty
          ? _buildEmptyState()
          : exportState.isExporting
          ? _buildExportingState(exportState)
          : _buildMainContent(exportState, studentState),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.file_download_off,
            size: 80,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'هیچ کارنامه‌ای برای خروجی وجود ندارد',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'ابتدا دانش‌آموزان را اضافه کنید',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildExportingState(ExportState exportState) {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(32),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              Text(
                'در حال ایجاد فایل‌ها...',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 200,
                child: LinearProgressIndicator(value: exportState.progress),
              ),
              const SizedBox(height: 8),
              Text('${exportState.currentItem} از ${exportState.totalItems}'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(ExportState exportState, StudentState studentState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // پیام‌های وضعیت
          if (exportState.successMessage != null) ...[
            _buildMessage(exportState.successMessage!, isError: false),
            const SizedBox(height: 16),
          ],
          if (exportState.errorMessage != null) ...[
            _buildMessage(exportState.errorMessage!, isError: true),
            const SizedBox(height: 16),
          ],

          // مسیر خروجی
          _buildPathSection(),
          const SizedBox(height: 16),

          // فرمت و نوع خروجی
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildFormatSection()),
              const SizedBox(width: 16),
              Expanded(child: _buildTypeSection(studentState)),
            ],
          ),
          const SizedBox(height: 24),

          // دکمه خروجی
          _buildExportButton(studentState),
        ],
      ),
    );
  }

  Widget _buildPathSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.folder_open, size: 20),
                const SizedBox(width: 8),
                Text(
                  'مسیر ذخیره فایل‌ها',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _pathController,
                    decoration: InputDecoration(
                      hintText: 'مسیر را انتخاب کنید...',
                      isDense: true,
                      border: const OutlineInputBorder(),
                      suffixIcon: _pathController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _pathController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                    ),
                    readOnly: true,
                    onTap: _selectPath,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _selectPath,
                  icon: const Icon(Icons.folder),
                  label: const Text('انتخاب'),
                ),
              ],
            ),
            if (_pathController.text.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'فایل‌ها در این مسیر ذخیره می‌شوند',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.green),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFormatSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('فرمت خروجی', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _buildFormatTile(
              ExportFormat.pdf,
              Icons.picture_as_pdf,
              'PDF',
              'قابل چاپ',
            ),
            const SizedBox(height: 8),
            _buildFormatTile(
              ExportFormat.excel,
              Icons.table_chart,
              'Excel',
              'قابل ویرایش',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatTile(
    ExportFormat format,
    IconData icon,
    String title,
    String subtitle,
  ) {
    final isSelected = _selectedFormat == format;
    return InkWell(
      onTap: () => setState(() => _selectedFormat = format),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : null,
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).dividerColor,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Theme.of(context).colorScheme.primary : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : null,
                    ),
                  ),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSection(StudentState studentState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('نوع خروجی', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _buildTypeTile(
              true,
              Icons.people,
              'همه کارنامه‌ها',
              '${studentState.students.length} کارنامه',
              true,
            ),
            const SizedBox(height: 8),
            _buildTypeTile(
              false,
              Icons.person,
              'کارنامه فعلی',
              studentState.selectedStudent?.name ?? 'انتخاب نشده',
              studentState.selectedStudent != null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeTile(
    bool value,
    IconData icon,
    String title,
    String subtitle,
    bool enabled,
  ) {
    final isSelected = _exportAll == value;
    return InkWell(
      onTap: enabled ? () => setState(() => _exportAll = value) : null,
      borderRadius: BorderRadius.circular(8),
      child: Opacity(
        opacity: enabled ? 1.0 : 0.5,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.secondaryContainer
                : null,
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.secondary
                  : Theme.of(context).dividerColor,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? Theme.of(context).colorScheme.secondary
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : null,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.secondary,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExportButton(StudentState studentState) {
    final hasPath = _pathController.text.isNotEmpty;
    final canExport =
        hasPath && (_exportAll || studentState.selectedStudent != null);

    return SizedBox(
      height: 56,
      child: ElevatedButton.icon(
        onPressed: canExport ? _handleExport : null,
        icon: const Icon(Icons.file_download, size: 28),
        label: Text(
          hasPath
              ? (_exportAll
                    ? 'خروجی ${studentState.students.length} کارنامه'
                    : 'خروجی کارنامه فعلی')
              : 'ابتدا مسیر را انتخاب کنید',
          style: const TextStyle(fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: canExport
              ? Theme.of(context).colorScheme.primary
              : null,
          foregroundColor: canExport
              ? Theme.of(context).colorScheme.onPrimary
              : null,
        ),
      ),
    );
  }

  Widget _buildMessage(String message, {required bool isError}) {
    return Card(
      color: isError
          ? Theme.of(context).colorScheme.errorContainer
          : Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              isError ? Icons.error : Icons.check_circle,
              color: isError
                  ? Theme.of(context).colorScheme.error
                  : Colors.green,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: () =>
                  ref.read(exportProvider.notifier).clearMessages(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectPath() async {
    final path = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'انتخاب مسیر ذخیره',
    );
    if (path != null) {
      _pathController.text = path;
      setState(() {});
    }
  }

  Future<void> _handleExport() async {
    final outputPath = _pathController.text;
    if (outputPath.isEmpty) return;

    if (_exportAll) {
      await ref
          .read(exportProvider.notifier)
          .exportAll(outputDirectory: outputPath, format: _selectedFormat);
    } else {
      final reportCardState = ref.read(reportCardProvider);
      if (reportCardState.currentReportCard != null) {
        await ref
            .read(exportProvider.notifier)
            .exportSingle(
              reportCard: reportCardState.currentReportCard!,
              outputDirectory: outputPath,
              format: _selectedFormat,
            );
      }
    }
  }
}
