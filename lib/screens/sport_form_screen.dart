import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../viewmodels/sport_viewmodel.dart';

class SportFormScreen extends ConsumerStatefulWidget {
  final Sport? sport;

  const SportFormScreen({super.key, this.sport});

  @override
  ConsumerState<SportFormScreen> createState() => _SportFormScreenState();
}

class _SportFormScreenState extends ConsumerState<SportFormScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool get isEditMode => widget.sport != null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    if (isEditMode) {
      _nameController.text = widget.sport!.name;
      _descriptionController.text = widget.sport!.description ?? '';
      // بارگذاری رشته برای ویرایش
      Future.microtask(() {
        ref.read(sportProvider.notifier).selectSport(widget.sport!);
      });
    } else {
      // ایجاد رشته جدید با سطوح عملکرد پیش‌فرض
      Future.microtask(() {
        ref.read(sportProvider.notifier).createNewSport();
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sportProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isEditMode ? 'ویرایش رشته ورزشی' : 'رشته ورزشی جدید'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: state.isSaving ? null : _saveSport,
              tooltip: 'ذخیره',
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: const [
              Tab(text: 'اطلاعات پایه'),
              Tab(text: 'سطوح'),
              Tab(text: 'سطوح عملکرد'),
            ],
          ),
        ),
        body: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildBasicInfoTab(),
                  _buildLevelsTab(state),
                  _buildPerformanceRatingsTab(state),
                ],
              ),
      ),
    );
  }

  Widget _buildBasicInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'نام رشته ورزشی *',
                hintText: 'مثال: شنا، فوتبال، بسکتبال',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.sports),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'نام رشته الزامی است';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'توضیحات',
                hintText: 'توضیحات اختیاری درباره رشته',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'راهنما',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• بعد از ذخیره اطلاعات پایه، می‌توانید سطوح و تکنیک‌ها را اضافه کنید\n'
                    '• هر رشته باید حداقل یک سطح و یک تکنیک داشته باشد\n'
                    '• سطوح عملکرد برای ارزیابی تکنیک‌ها استفاده می‌شوند',
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelsTab(SportState state) {
    if (state.selectedSport == null) {
      return const Center(child: Text('ابتدا اطلاعات پایه را ذخیره کنید'));
    }

    final levels = state.selectedSport!.levels;

    return Column(
      children: [
        Expanded(
          child: levels.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.layers, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'هیچ سطحی تعریف نشده است',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _addLevel,
                        icon: const Icon(Icons.add),
                        label: const Text('افزودن سطح اول'),
                      ),
                    ],
                  ),
                )
              : ReorderableListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: levels.length,
                  onReorder: (oldIndex, newIndex) {
                    ref
                        .read(sportProvider.notifier)
                        .reorderLevels(oldIndex, newIndex);
                  },
                  itemBuilder: (context, index) {
                    final level = levels[index];
                    return _buildLevelCard(
                      level,
                      index,
                      key: ValueKey(level.id),
                    );
                  },
                ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: ElevatedButton.icon(
              onPressed: _addLevel,
              icon: const Icon(Icons.add),
              label: const Text('افزودن سطح جدید'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLevelCard(Level level, int index, {required Key key}) {
    return Card(
      key: key,
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: const Icon(Icons.drag_handle),
        title: Text(
          level.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${level.techniques.length} تکنیک'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => _editLevel(level),
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20, color: Colors.red),
              onPressed: () => _deleteLevel(level),
            ),
          ],
        ),
        children: [
          if (level.techniques.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'هیچ تکنیکی تعریف نشده است',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _addTechnique(level),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('افزودن تکنیک'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 40),
                    ),
                  ),
                ],
              ),
            )
          else
            ...level.techniques.map((technique) {
              return ListTile(
                dense: true,
                leading: CircleAvatar(
                  radius: 12,
                  child: Text(
                    '${technique.order}',
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
                title: Text(technique.name),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 18),
                      onPressed: () => _editTechnique(level, technique),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete,
                        size: 18,
                        color: Colors.red,
                      ),
                      onPressed: () => _deleteTechnique(level, technique),
                    ),
                  ],
                ),
              );
            }),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: () => _addTechnique(level),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('افزودن تکنیک'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 40),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceRatingsTab(SportState state) {
    if (state.selectedSport == null) {
      return const Center(child: Text('ابتدا اطلاعات پایه را ذخیره کنید'));
    }

    final ratings = state.selectedSport!.performanceRatings;

    return Column(
      children: [
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: ratings.length,
            onReorder: (oldIndex, newIndex) {
              ref
                  .read(sportProvider.notifier)
                  .reorderPerformanceRatings(oldIndex, newIndex);
            },
            itemBuilder: (context, index) {
              final rating = ratings[index];
              return _buildPerformanceRatingCard(
                rating,
                index,
                key: ValueKey(rating.id),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: ElevatedButton.icon(
              onPressed: _addPerformanceRating,
              icon: const Icon(Icons.add),
              label: const Text('افزودن سطح عملکرد جدید'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceRatingCard(
    PerformanceRating rating,
    int index, {
    required Key key,
  }) {
    return Card(
      key: key,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.drag_handle),
        title: Text(
          rating.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('ترتیب: ${rating.order}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => _editPerformanceRating(rating),
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20, color: Colors.red),
              onPressed: () => _deletePerformanceRating(rating),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveSport() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();

    if (isEditMode) {
      await ref
          .read(sportProvider.notifier)
          .updateSportBasicInfo(
            name: name,
            description: description.isEmpty ? null : description,
          );
    } else {
      await ref
          .read(sportProvider.notifier)
          .createSport(
            name: name,
            description: description.isEmpty ? null : description,
          );
    }

    if (mounted) {
      final state = ref.read(sportProvider);
      if (state.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.successMessage!),
            backgroundColor: Colors.green,
          ),
        );
        if (!isEditMode) {
          // بعد از ایجاد موفق، به تب سطوح برو
          _tabController.animateTo(1);
        }
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

  Future<void> _addLevel() async {
    final nameController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('افزودن سطح جدید'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'نام سطح',
              hintText: 'مثال: سطح 1، مبتدی، پیشرفته',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('لغو'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('افزودن'),
            ),
          ],
        ),
      ),
    );

    if (result == true && nameController.text.trim().isNotEmpty) {
      await ref
          .read(sportProvider.notifier)
          .addLevel(nameController.text.trim());
      _showMessage();
    }
  }

  Future<void> _editLevel(Level level) async {
    final nameController = TextEditingController(text: level.name);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('ویرایش سطح'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'نام سطح',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('لغو'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('ذخیره'),
            ),
          ],
        ),
      ),
    );

    if (result == true && nameController.text.trim().isNotEmpty) {
      await ref
          .read(sportProvider.notifier)
          .updateLevel(level.id, nameController.text.trim());
      _showMessage();
    }
  }

  Future<void> _deleteLevel(Level level) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأیید حذف'),
          content: Text('آیا از حذف سطح "${level.name}" اطمینان دارید؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('لغو'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      await ref.read(sportProvider.notifier).deleteLevel(level.id);
      _showMessage();
    }
  }

  Future<void> _addTechnique(Level level) async {
    final nameController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('افزودن تکنیک جدید'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'نام تکنیک',
              hintText: 'مثال: شنای آزاد، ضربه پا',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('لغو'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('افزودن'),
            ),
          ],
        ),
      ),
    );

    if (result == true && nameController.text.trim().isNotEmpty) {
      await ref
          .read(sportProvider.notifier)
          .addTechnique(level.id, nameController.text.trim());
      _showMessage();
    }
  }

  Future<void> _editTechnique(Level level, Technique technique) async {
    final nameController = TextEditingController(text: technique.name);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('ویرایش تکنیک'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'نام تکنیک',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('لغو'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('ذخیره'),
            ),
          ],
        ),
      ),
    );

    if (result == true && nameController.text.trim().isNotEmpty) {
      await ref
          .read(sportProvider.notifier)
          .updateTechnique(level.id, technique.id, nameController.text.trim());
      _showMessage();
    }
  }

  Future<void> _deleteTechnique(Level level, Technique technique) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأیید حذف'),
          content: Text('آیا از حذف تکنیک "${technique.name}" اطمینان دارید؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('لغو'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      await ref
          .read(sportProvider.notifier)
          .deleteTechnique(level.id, technique.id);
      _showMessage();
    }
  }

  Future<void> _addPerformanceRating() async {
    final nameController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('افزودن سطح عملکرد جدید'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'نام سطح عملکرد',
              hintText: 'مثال: عالی، خوب، متوسط',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('لغو'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('افزودن'),
            ),
          ],
        ),
      ),
    );

    if (result == true && nameController.text.trim().isNotEmpty) {
      await ref
          .read(sportProvider.notifier)
          .addPerformanceRating(nameController.text.trim());
      _showMessage();
    }
  }

  Future<void> _editPerformanceRating(PerformanceRating rating) async {
    final nameController = TextEditingController(text: rating.name);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('ویرایش سطح عملکرد'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'نام سطح عملکرد',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('لغو'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('ذخیره'),
            ),
          ],
        ),
      ),
    );

    if (result == true && nameController.text.trim().isNotEmpty) {
      await ref
          .read(sportProvider.notifier)
          .updatePerformanceRating(rating.id, nameController.text.trim());
      _showMessage();
    }
  }

  Future<void> _deletePerformanceRating(PerformanceRating rating) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأیید حذف'),
          content: Text(
            'آیا از حذف سطح عملکرد "${rating.name}" اطمینان دارید؟',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('لغو'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      await ref.read(sportProvider.notifier).deletePerformanceRating(rating.id);
      _showMessage();
    }
  }

  void _showMessage() {
    if (!mounted) return;
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
