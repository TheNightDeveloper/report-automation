import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
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

  @override
  Widget build(BuildContext context) {
    final exportState = ref.watch(exportProvider);
    final studentState = ref.watch(studentProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('خروجی فایل')),
      body: _buildBody(exportState, studentState),
    );
  }

  Widget _buildBody(ExportState exportState, StudentState studentState) {
    if (studentState.students.isEmpty) {
      return _buildEmptyState();
    }

    if (exportState.isExporting) {
      return _buildExportingState(exportState);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildFormatSelection(),
          const SizedBox(height: 24),
          _buildExportTypeSelection(studentState),
          const SizedBox(height: 24),
          _buildExportButton(studentState),
          const SizedBox(height: 24),
          if (exportState.successMessage != null)
            _buildSuccessMessage(exportState.successMessage!),
          if (exportState.errorMessage != null)
            _buildErrorMessage(exportState.errorMessage!),
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
            Icons.file_download_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          ),
          const SizedBox(height: 24),
          Text(
            'هیچ کارنامه‌ای برای خروجی وجود ندارد',
            style: Theme.of(context).textTheme.headlineMedium,
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
        margin: const EdgeInsets.all(24),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              Text(
                'در حال ایجاد فایل‌ها...',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(value: exportState.progress),
              const SizedBox(height: 8),
              Text(
                '${exportState.currentItem} از ${exportState.totalItems}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormatSelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'انتخاب فرمت خروجی',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildFormatOption(
                    format: ExportFormat.pdf,
                    icon: Icons.picture_as_pdf,
                    label: 'PDF',
                    description: 'فایل قابل چاپ',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildFormatOption(
                    format: ExportFormat.excel,
                    icon: Icons.table_chart,
                    label: 'Excel',
                    description: 'فایل قابل ویرایش',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatOption({
    required ExportFormat format,
    required IconData icon,
    required String label,
    required String description,
  }) {
    final isSelected = _selectedFormat == format;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedFormat = format;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : null,
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).dividerColor,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 48,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : null,
                fontWeight: isSelected ? FontWeight.bold : null,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportTypeSelection(StudentState studentState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'انتخاب نوع خروجی',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            RadioListTile<bool>(
              title: const Text('خروجی همه کارنامه‌ها'),
              subtitle: Text('${studentState.students.length} کارنامه'),
              value: true,
              groupValue: _exportAll,
              onChanged: (value) {
                setState(() {
                  _exportAll = value!;
                });
              },
            ),
            RadioListTile<bool>(
              title: const Text('خروجی کارنامه فعلی'),
              subtitle: Text(
                studentState.selectedStudent?.name ??
                    'هیچ کارنامه‌ای انتخاب نشده',
              ),
              value: false,
              groupValue: _exportAll,
              onChanged: studentState.selectedStudent != null
                  ? (value) {
                      setState(() {
                        _exportAll = value!;
                      });
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportButton(StudentState studentState) {
    final canExport = _exportAll || studentState.selectedStudent != null;

    return ElevatedButton.icon(
      onPressed: canExport ? _handleExport : null,
      icon: const Icon(Icons.file_download),
      label: Text(_exportAll ? 'خروجی همه کارنامه‌ها' : 'خروجی کارنامه فعلی'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }

  Widget _buildSuccessMessage(String message) {
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                ref.read(exportProvider.notifier).clearMessages();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorMessage(String message) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.error, color: Theme.of(context).colorScheme.error),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                ref.read(exportProvider.notifier).clearMessages();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleExport() async {
    // انتخاب مسیر ذخیره
    final outputPath = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'انتخاب مسیر ذخیره فایل‌ها',
    );

    if (outputPath == null) return;

    if (_exportAll) {
      // Export همه
      await ref
          .read(exportProvider.notifier)
          .exportAll(outputDirectory: outputPath, format: _selectedFormat);
    } else {
      // Export تکی
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
