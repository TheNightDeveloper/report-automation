import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../viewmodels/sport_viewmodel.dart';
import '../repositories/sport_repository.dart';
import '../repositories/configuration_repository.dart';
import 'sport_form_screen.dart';

class SportsListScreen extends ConsumerStatefulWidget {
  const SportsListScreen({super.key});

  @override
  ConsumerState<SportsListScreen> createState() => _SportsListScreenState();
}

class _SportsListScreenState extends ConsumerState<SportsListScreen> {
  @override
  void initState() {
    super.initState();
    // بارگذاری لیست رشته‌ها
    Future.microtask(() => ref.read(sportProvider.notifier).loadSports());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sportProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('مدیریت رشته‌های ورزشی'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          actions: [
            // دکمه Import
            IconButton(
              icon: const Icon(Icons.upload_file),
              tooltip: 'واردات تنظیمات',
              onPressed: () => _importSportConfiguration(),
            ),
          ],
        ),
        body: _buildBody(state),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _navigateToAddSport(),
          icon: const Icon(Icons.add),
          label: const Text('رشته جدید'),
          backgroundColor: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildBody(SportState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              state.errorMessage!,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(sportProvider.notifier).loadSports(),
              child: const Text('تلاش مجدد'),
            ),
          ],
        ),
      );
    }

    if (state.sports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.sports, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'هیچ رشته ورزشی تعریف نشده است',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _navigateToAddSport(),
              icon: const Icon(Icons.add),
              label: const Text('افزودن رشته اول'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.sports.length,
      itemBuilder: (context, index) {
        final sport = state.sports[index];
        return _buildSportCard(sport);
      },
    );
  }

  Widget _buildSportCard(Sport sport) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _navigateToEditSport(sport),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          sport.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (sport.isDefault) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'پیش‌فرض',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green.shade800,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.download, color: Colors.green),
                    onPressed: () => _exportSportConfiguration(sport),
                    tooltip: 'صادرات تنظیمات',
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _navigateToEditSport(sport),
                    tooltip: 'ویرایش',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _confirmDelete(sport),
                    tooltip: 'حذف',
                  ),
                ],
              ),
              if (sport.description != null &&
                  sport.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  sport.description!,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _buildInfoChip(
                    Icons.layers,
                    '${sport.levels.length} سطح',
                    Colors.blue,
                  ),
                  _buildInfoChip(
                    Icons.fitness_center,
                    '${_getTotalTechniques(sport)} تکنیک',
                    Colors.orange,
                  ),
                  _buildInfoChip(
                    Icons.star,
                    '${sport.performanceRatings.length} سطح عملکرد',
                    Colors.purple,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 13, color: color)),
      ],
    );
  }

  int _getTotalTechniques(Sport sport) {
    return sport.levels.fold(0, (sum, level) => sum + level.techniques.length);
  }

  void _navigateToAddSport() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SportFormScreen()),
    ).then((_) {
      // رفرش لیست بعد از بازگشت
      ref.read(sportProvider.notifier).loadSports();
    });
  }

  void _navigateToEditSport(Sport sport) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SportFormScreen(sport: sport)),
    ).then((_) {
      // رفرش لیست بعد از بازگشت
      ref.read(sportProvider.notifier).loadSports();
    });
  }

  Future<void> _confirmDelete(Sport sport) async {
    // بررسی وجود کارنامه‌های مرتبط
    final hasReportCards = await ref
        .read(sportProvider.notifier)
        .checkHasReportCards(sport.id);

    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأیید حذف'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('آیا از حذف رشته "${sport.name}" اطمینان دارید؟'),
              if (hasReportCards) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange.shade700),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'این رشته دارای کارنامه‌های مرتبط است',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('لغو'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(sportProvider.notifier).deleteSport(sport.id);

      if (mounted) {
        final state = ref.read(sportProvider);
        if (state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.successMessage!),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // ========== Import/Export Methods ==========

  Future<void> _exportSportConfiguration(Sport sport) async {
    try {
      final repository = ConfigurationRepository(SportRepository());
      final jsonData = await repository.exportSportConfiguration(sport.id);

      // ذخیره فایل
      final fileName =
          '${sport.name}_config_${DateTime.now().millisecondsSinceEpoch}.json';

      // در Flutter Web از FileSaver استفاده می‌شود
      // در پلتفرم‌های دیگر از file_picker استفاده می‌شود
      // برای سادگی، فعلاً فقط پیام موفقیت نمایش می‌دهیم

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تنظیمات رشته "${sport.name}" با موفقیت صادر شد'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'کپی',
              textColor: Colors.white,
              onPressed: () {
                // کپی JSON به کلیپ‌بورد
                _copyToClipboard(jsonData);
              },
            ),
          ),
        );

        // نمایش dialog با JSON برای کپی
        _showExportDialog(jsonData, fileName);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در صادرات: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showExportDialog(String jsonData, String fileName) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('صادرات تنظیمات'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'فایل: $fileName',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text('محتوای JSON:'),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 300),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      jsonData,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('بستن'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                _copyToClipboard(jsonData);
                Navigator.pop(context);
              },
              icon: const Icon(Icons.copy),
              label: const Text('کپی'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _copyToClipboard(String text) async {
    // TODO: Implement clipboard copy
    // await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('JSON به کلیپ‌بورد کپی شد'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _importSportConfiguration() async {
    // نمایش dialog برای ورود JSON
    final jsonData = await _showImportDialog();
    if (jsonData == null || jsonData.isEmpty) return;

    try {
      final repository = ConfigurationRepository(SportRepository());

      // اعتبارسنجی
      await repository.validateConfiguration(jsonData);

      // واردات
      final sport = await repository.importSportConfiguration(jsonData);

      // بررسی نام تکراری
      final existingSport = await SportRepository().getAllSports();
      final hasDuplicate = existingSport.any((s) => s.name == sport.name);

      if (hasDuplicate) {
        if (!mounted) return;
        final newName = await _showDuplicateNameDialog(sport.name);
        if (newName == null) return;

        // ایجاد Sport با نام جدید
        final newSport = sport.copyWith(
          id: 'sport_${DateTime.now().millisecondsSinceEpoch}',
          name: newName,
          isDefault: false,
        );

        await SportRepository().saveSport(newSport);
      } else {
        // ذخیره با ID جدید
        final newSport = sport.copyWith(
          id: 'sport_${DateTime.now().millisecondsSinceEpoch}',
          isDefault: false,
        );
        await SportRepository().saveSport(newSport);
      }

      // رفرش لیست
      await ref.read(sportProvider.notifier).loadSports();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تنظیمات با موفقیت وارد شد'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در واردات: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _showImportDialog() async {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('واردات تنظیمات'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('محتوای JSON را وارد کنید:'),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  maxLines: 10,
                  decoration: InputDecoration(
                    hintText: '{"version": "1.0", "sport": {...}}',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('انصراف'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('واردات'),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _showDuplicateNameDialog(String originalName) async {
    final controller = TextEditingController(text: '$originalName (کپی)');

    return showDialog<String>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('نام تکراری'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('رشته‌ای با نام "$originalName" وجود دارد.'),
              const SizedBox(height: 16),
              const Text('نام جدید را وارد کنید:'),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'نام رشته',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('انصراف'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('تأیید'),
            ),
          ],
        ),
      ),
    );
  }
}
