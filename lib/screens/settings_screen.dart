import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/app_data_viewmodel.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final appData = ref.watch(appDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('تنظیمات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'بازنشانی به پیش‌فرض',
            onPressed: () => _showResetDialog(),
          ),
        ],
      ),
      body: appData.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // مقاطع تحصیلی
                  _buildSection(
                    context,
                    title: 'مقاطع تحصیلی',
                    icon: Icons.school,
                    items: appData.grades,
                    onAdd: () => _showAddDialog(
                      context,
                      'افزودن مقطع',
                      'نام مقطع',
                      (value) =>
                          ref.read(appDataProvider.notifier).addGrade(value),
                    ),
                    onDelete: (item) =>
                        ref.read(appDataProvider.notifier).removeGrade(item),
                  ),
                  const SizedBox(height: 24),

                  // پایه‌های تحصیلی
                  _buildSection(
                    context,
                    title: 'پایه‌های تحصیلی',
                    icon: Icons.grade,
                    items: appData.levels,
                    onAdd: () => _showAddDialog(
                      context,
                      'افزودن پایه',
                      'نام پایه',
                      (value) =>
                          ref.read(appDataProvider.notifier).addLevel(value),
                    ),
                    onDelete: (item) =>
                        ref.read(appDataProvider.notifier).removeLevel(item),
                  ),
                  const SizedBox(height: 24),

                  // آموزشگاه‌ها
                  _buildSection(
                    context,
                    title: 'آموزشگاه‌ها',
                    icon: Icons.business,
                    items: appData.schools,
                    onAdd: () => _showAddDialog(
                      context,
                      'افزودن آموزشگاه',
                      'نام آموزشگاه',
                      (value) =>
                          ref.read(appDataProvider.notifier).addSchool(value),
                    ),
                    onDelete: (item) =>
                        ref.read(appDataProvider.notifier).removeSchool(item),
                  ),
                  const SizedBox(height: 24),

                  // سرمربیان
                  _buildSection(
                    context,
                    title: 'سرمربیان',
                    icon: Icons.sports,
                    items: appData.headCoaches,
                    onAdd: () => _showAddDialog(
                      context,
                      'افزودن سرمربی',
                      'نام سرمربی',
                      (value) => ref
                          .read(appDataProvider.notifier)
                          .addHeadCoach(value),
                    ),
                    onDelete: (item) => ref
                        .read(appDataProvider.notifier)
                        .removeHeadCoach(item),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<String> items,
    required VoidCallback onAdd,
    required Function(String) onDelete,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('افزودن'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (items.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(Icons.inbox, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text(
                        'موردی وجود ندارد',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: items.map((item) {
                  return Chip(
                    label: Text(item),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () => _confirmDelete(context, item, onDelete),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddDialog(
    BuildContext context,
    String title,
    String hint,
    Function(String) onAdd,
  ) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              border: const OutlineInputBorder(),
            ),
            autofocus: true,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'لطفاً مقدار را وارد کنید';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('انصراف'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('افزودن'),
          ),
        ],
      ),
    );

    if (result == true && controller.text.trim().isNotEmpty) {
      onAdd(controller.text.trim());
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('با موفقیت اضافه شد'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    String item,
    Function(String) onDelete,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأیید حذف'),
        content: Text('آیا از حذف "$item" اطمینان دارید؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('انصراف'),
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
    );

    if (confirmed == true) {
      onDelete(item);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('با موفقیت حذف شد'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _showResetDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('بازنشانی به پیش‌فرض'),
        content: const Text(
          'آیا می‌خواهید تمام تنظیمات را به حالت پیش‌فرض بازگردانید؟\n\nتمام تغییرات شما حذف خواهد شد.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('انصراف'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('بازنشانی'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      ref.read(appDataProvider.notifier).resetToDefaults();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تنظیمات به حالت پیش‌فرض بازگشت'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
}
