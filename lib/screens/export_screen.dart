import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../viewmodels/export_viewmodel.dart';
import '../viewmodels/folder_viewmodel.dart';
import '../services/export_service.dart';
import '../repositories/report_card_repository.dart';

class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  ExportFormat _selectedFormat = ExportFormat.pdf;
  bool _onlyCompleted = false;
  String? _selectedFolderId;
  final TextEditingController _pathController = TextEditingController();
  final _reportCardRepository = ReportCardRepository();

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
      // کاربر باید مسیر را انتخاب کند
    }
  }

  // محاسبه تعداد کارنامه‌های تکمیل شده
  Future<int> _getCompletedCount(List<String> studentIds) async {
    int count = 0;
    for (final studentId in studentIds) {
      final reportCard = await _reportCardRepository.loadReportCard(studentId);
      if (reportCard != null &&
          reportCard.levelEvaluations != null &&
          reportCard.levelEvaluations!.isNotEmpty) {
        count++;
      }
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final exportState = ref.watch(exportProvider);
    final folderState = ref.watch(folderProvider);
    final allStudents = folderState.folders
        .expand((folder) => folder.students)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('خروجی فایل'), centerTitle: true),
      body: allStudents.isEmpty
          ? _buildEmptyState()
          : exportState.isExporting
          ? _buildExportingState(exportState)
          : _buildMainContent(folderState),
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
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(strokeWidth: 3),
              const SizedBox(height: 32),
              Text(
                'در حال ایجاد فایل‌ها...',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 250,
                child: LinearProgressIndicator(
                  value: exportState.progress,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${exportState.currentItem} از ${exportState.totalItems}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(FolderState folderState) {
    final exportState = ref.watch(exportProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        // تعیین layout بر اساس عرض صفحه
        final isWideScreen = constraints.maxWidth > 900;
        final isMediumScreen = constraints.maxWidth > 600;

        if (isWideScreen) {
          // دسکتاپ: دو ستونی
          return _buildDesktopLayout(folderState, exportState);
        } else if (isMediumScreen) {
          // تبلت: یک ستونی با عرض محدود
          return _buildTabletLayout(folderState, exportState);
        } else {
          // موبایل: یک ستونی کامل
          return _buildMobileLayout(folderState, exportState);
        }
      },
    );
  }

  Widget _buildDesktopLayout(FolderState folderState, ExportState exportState) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ستون چپ: تنظیمات (60%)
        Expanded(
          flex: 6,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _buildSettingsCard(
              exportState,
              folderState,
              isDesktop: true,
            ),
          ),
        ),
        // ستون راست: خلاصه (40%)
        Expanded(
          flex: 4,
          child: Container(
            height: double.infinity,
            padding: const EdgeInsets.fromLTRB(0, 24, 24, 24),
            child: _buildExportSummary(folderState),
          ),
        ),
      ],
    );
  }

  Widget _buildTabletLayout(FolderState folderState, ExportState exportState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Column(
            children: [
              _buildSettingsCard(exportState, folderState, isDesktop: false),
              const SizedBox(height: 20),
              _buildExportSummary(folderState),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(FolderState folderState, ExportState exportState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSettingsCard(exportState, folderState, isDesktop: false),
          const SizedBox(height: 16),
          _buildExportSummary(folderState),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(
    ExportState exportState,
    FolderState folderState, {
    required bool isDesktop,
  }) {
    return Column(
      children: [
        // پیام‌های وضعیت
        if (exportState.successMessage != null)
          _buildStatusMessage(exportState.successMessage!, isError: false),
        if (exportState.errorMessage != null)
          _buildStatusMessage(exportState.errorMessage!, isError: true),

        // کارت اصلی تنظیمات
        Card(
          elevation: 2,
          child: Padding(
            padding: EdgeInsets.all(isDesktop ? 24 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // عنوان
                Row(
                  children: [
                    Icon(
                      Icons.settings,
                      color: Theme.of(context).colorScheme.primary,
                      size: isDesktop ? 28 : 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'تنظیمات خروجی',
                        style: isDesktop
                            ? Theme.of(context).textTheme.headlineSmall
                            : Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 32),

                // محتوای تنظیمات - ریسپانسیو
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 500 && isDesktop) {
                      // عرض زیاد: دو ستونی
                      return _buildSettingsGrid(folderState);
                    } else {
                      // عرض کم: یک ستونی
                      return _buildSettingsColumn(folderState);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsGrid(FolderState folderState) {
    return Column(
      children: [
        // ردیف اول: پوشه و فیلتر
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('۱. انتخاب پوشه', Icons.folder),
                  const SizedBox(height: 12),
                  _buildFolderDropdown(folderState),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('۲. نوع کارنامه‌ها', Icons.filter_list),
                  const SizedBox(height: 12),
                  _buildFilterToggle(),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // ردیف دوم: فرمت و مسیر
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('۳. فرمت خروجی', Icons.description),
                  const SizedBox(height: 12),
                  _buildFormatToggle(),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('۴. مسیر ذخیره', Icons.save_alt),
                  const SizedBox(height: 12),
                  _buildPathSelector(),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSettingsColumn(FolderState folderState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ۱. انتخاب پوشه
        _buildSectionTitle('۱. انتخاب پوشه', Icons.folder),
        const SizedBox(height: 12),
        _buildFolderDropdown(folderState),
        const SizedBox(height: 24),

        // ۲. نوع کارنامه‌ها
        _buildSectionTitle('۲. نوع کارنامه‌ها', Icons.filter_list),
        const SizedBox(height: 12),
        _buildFilterToggle(),
        const SizedBox(height: 24),

        // ۳. فرمت خروجی
        _buildSectionTitle('۳. فرمت خروجی', Icons.description),
        const SizedBox(height: 12),
        _buildFormatToggle(),
        const SizedBox(height: 24),

        // ۴. مسیر ذخیره
        _buildSectionTitle('۴. مسیر ذخیره', Icons.save_alt),
        const SizedBox(height: 12),
        _buildPathSelector(),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 22, color: Theme.of(context).colorScheme.secondary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildFolderDropdown(FolderState folderState) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: _selectedFolderId,
          isExpanded: true,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          borderRadius: BorderRadius.circular(12),
          hint: const Text('همه پوشه‌ها'),
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Row(
                children: [
                  const Icon(Icons.folder_open, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'همه پوشه‌ها (${folderState.totalStudents} دانش‌آموز)',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            ...folderState.folders.map(
              (folder) => DropdownMenuItem<String?>(
                value: folder.id,
                child: Row(
                  children: [
                    const Icon(Icons.folder, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${folder.name} (${folder.studentCount} دانش‌آموز)',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          onChanged: (value) => setState(() => _selectedFolderId = value),
        ),
      ),
    );
  }

  Widget _buildFilterToggle() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // اگر عرض کم باشه، دکمه‌ها رو کوچکتر کن
        final isNarrow = constraints.maxWidth < 300;

        return SegmentedButton<bool>(
          segments: [
            ButtonSegment<bool>(
              value: false,
              label: Text(isNarrow ? 'همه' : 'همه دانش‌آموزان'),
              icon: const Icon(Icons.people),
            ),
            ButtonSegment<bool>(
              value: true,
              label: Text(isNarrow ? 'تکمیل شده' : 'فقط تکمیل شده'),
              icon: const Icon(Icons.check_circle),
            ),
          ],
          selected: {_onlyCompleted},
          onSelectionChanged: (Set<bool> selected) {
            setState(() => _onlyCompleted = selected.first);
          },
          style: ButtonStyle(
            visualDensity: isNarrow
                ? VisualDensity.compact
                : VisualDensity.comfortable,
          ),
        );
      },
    );
  }

  Widget _buildFormatToggle() {
    return SegmentedButton<ExportFormat>(
      segments: const [
        ButtonSegment<ExportFormat>(
          value: ExportFormat.pdf,
          label: Text('PDF'),
          icon: Icon(Icons.picture_as_pdf),
        ),
        ButtonSegment<ExportFormat>(
          value: ExportFormat.excel,
          label: Text('Excel'),
          icon: Icon(Icons.table_chart),
        ),
      ],
      selected: {_selectedFormat},
      onSelectionChanged: (Set<ExportFormat> selected) {
        setState(() => _selectedFormat = selected.first);
      },
      style: ButtonStyle(visualDensity: VisualDensity.comfortable),
    );
  }

  Widget _buildPathSelector() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 400;

        if (isNarrow) {
          // عرض کم: دکمه‌ها زیر هم
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(12),
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceVariant.withOpacity(0.3),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.folder,
                      size: 20,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _pathController.text.isNotEmpty
                            ? _pathController.text
                            : 'مسیری انتخاب نشده',
                        style: TextStyle(
                          color: _pathController.text.isNotEmpty
                              ? null
                              : Theme.of(context).colorScheme.outline,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              FilledButton.tonalIcon(
                onPressed: _selectPath,
                icon: const Icon(Icons.folder_open),
                label: const Text('انتخاب مسیر'),
              ),
            ],
          );
        } else {
          // عرض زیاد: کنار هم
          return Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).dividerColor),
                    borderRadius: BorderRadius.circular(12),
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceVariant.withOpacity(0.3),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.folder,
                        size: 20,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _pathController.text.isNotEmpty
                              ? _pathController.text
                              : 'مسیری انتخاب نشده',
                          style: TextStyle(
                            color: _pathController.text.isNotEmpty
                                ? null
                                : Theme.of(context).colorScheme.outline,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.tonalIcon(
                onPressed: _selectPath,
                icon: const Icon(Icons.folder_open),
                label: const Text('انتخاب'),
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildExportSummary(FolderState folderState) {
    return FutureBuilder<int>(
      future: _calculateExportCount(folderState),
      builder: (context, snapshot) {
        final exportCount = snapshot.data ?? 0;
        final isLoading = snapshot.connectionState == ConnectionState.waiting;

        String folderName = 'همه پوشه‌ها';
        if (_selectedFolderId != null) {
          final selectedFolder = folderState.folders.firstWhere(
            (f) => f.id == _selectedFolderId,
          );
          folderName = selectedFolder.name;
        }

        final hasPath = _pathController.text.isNotEmpty;
        final canExport = hasPath && exportCount > 0 && !isLoading;

        return Card(
          elevation: 4,
          color: Theme.of(
            context,
          ).colorScheme.primaryContainer.withOpacity(0.3),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // خلاصه
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.summarize,
                      color: Theme.of(context).colorScheme.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'خلاصه خروجی',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // جزئیات
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildSummaryRow('پوشه:', folderName, Icons.folder),
                      const Divider(height: 20),
                      _buildSummaryRow(
                        'نوع:',
                        _onlyCompleted ? 'فقط تکمیل شده' : 'همه دانش‌آموزان',
                        _onlyCompleted ? Icons.check_circle : Icons.people,
                      ),
                      const Divider(height: 20),
                      _buildSummaryRow(
                        'فرمت:',
                        _selectedFormat == ExportFormat.pdf ? 'PDF' : 'Excel',
                        _selectedFormat == ExportFormat.pdf
                            ? Icons.picture_as_pdf
                            : Icons.table_chart,
                      ),
                      const Divider(height: 20),
                      _buildSummaryRow(
                        'تعداد فایل:',
                        isLoading ? 'در حال محاسبه...' : '$exportCount فایل',
                        Icons.file_copy,
                        highlight: true,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // دکمه خروجی
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton.icon(
                    onPressed: canExport ? _handleExport : null,
                    icon: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.file_download, size: 24),
                    label: Text(
                      canExport
                          ? 'شروع خروجی ($exportCount فایل)'
                          : hasPath
                          ? isLoading
                                ? 'در حال محاسبه...'
                                : 'کارنامه‌ای برای خروجی وجود ندارد'
                          : 'ابتدا مسیر را انتخاب کنید',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<int> _calculateExportCount(FolderState folderState) async {
    List<String> studentIds = [];

    if (_selectedFolderId != null) {
      final selectedFolder = folderState.folders.firstWhere(
        (f) => f.id == _selectedFolderId,
      );
      studentIds = selectedFolder.students.map((s) => s.id).toList();
    } else {
      for (final folder in folderState.folders) {
        studentIds.addAll(folder.students.map((s) => s.id));
      }
    }

    if (_onlyCompleted) {
      return await _getCompletedCount(studentIds);
    } else {
      return studentIds.length;
    }
  }

  Widget _buildSummaryRow(
    String label,
    String value,
    IconData icon, {
    bool highlight = false,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: highlight
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.secondary,
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
              color: highlight ? Theme.of(context).colorScheme.primary : null,
            ),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusMessage(String message, {required bool isError}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isError
            ? Theme.of(context).colorScheme.errorContainer
            : Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isError
              ? Theme.of(context).colorScheme.error.withOpacity(0.5)
              : Colors.green.withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error : Icons.check_circle,
            color: isError ? Theme.of(context).colorScheme.error : Colors.green,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => ref.read(exportProvider.notifier).clearMessages(),
          ),
        ],
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

    await ref
        .read(exportProvider.notifier)
        .exportAllFiltered(
          outputDirectory: outputPath,
          format: _selectedFormat,
          folderId: _selectedFolderId,
          onlyCompleted: _onlyCompleted,
        );
  }
}
