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
  bool _isNewSportSaved = false;

  bool get isEditMode => widget.sport != null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // گوش دادن به تغییر تب برای به‌روزرسانی UI
    _tabController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

    if (isEditMode) {
      _nameController.text = widget.sport!.name;
      _descriptionController.text = widget.sport!.description ?? '';
      _isNewSportSaved = true;
      Future.microtask(() {
        ref.read(sportProvider.notifier).selectSport(widget.sport!);
      });
    } else {
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
    final theme = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          elevation: 0,
          title: Text(
            isEditMode ? 'ویرایش رشته ورزشی' : 'رشته ورزشی جدید',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: theme.primaryColor,
          foregroundColor: Colors.white,
          actions: [
            // فقط در تب اطلاعات پایه دکمه ذخیره نمایش بده
            if (_tabController.index == 0)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: TextButton.icon(
                  onPressed: state.isSaving ? null : _saveSport,
                  icon: state.isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check, color: Colors.white),
                  label: Text(
                    'ذخیره',
                    style: TextStyle(
                      color: state.isSaving ? Colors.white60 : Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              color: theme.primaryColor,
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                tabs: const [
                  Tab(text: 'اطلاعات پایه'),
                  Tab(text: 'سطوح'),
                  Tab(text: 'سطوح عملکرد'),
                ],
              ),
            ),
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
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // کارت اطلاعات اصلی
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.sports,
                            color: Colors.blue.shade700,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'مشخصات رشته',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'نام رشته ورزشی',
                        hintText: 'مثال: شنا، فوتبال، بسکتبال',
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.blue.shade400,
                            width: 2,
                          ),
                        ),
                        prefixIcon: const Icon(Icons.edit_outlined),
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
                      decoration: InputDecoration(
                        labelText: 'توضیحات (اختیاری)',
                        hintText: 'توضیحات درباره این رشته ورزشی',
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.blue.shade400,
                            width: 2,
                          ),
                        ),
                        prefixIcon: const Icon(Icons.description_outlined),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // کارت راهنما
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade50, Colors.blue.shade100],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: Colors.blue.shade700,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'راهنما',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildGuideItem('ابتدا نام رشته را وارد و ذخیره کنید'),
                  _buildGuideItem('سپس سطوح و تکنیک‌ها را اضافه کنید'),
                  _buildGuideItem('سطوح عملکرد برای ارزیابی استفاده می‌شوند'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, size: 18, color: Colors.blue.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.blue.shade800, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelsTab(SportState state) {
    final canEdit = _isNewSportSaved || isEditMode;

    if (!canEdit) {
      return _buildLockedTab(
        icon: Icons.layers_outlined,
        title: 'ابتدا اطلاعات پایه را ذخیره کنید',
        subtitle: 'برای افزودن سطوح، ابتدا نام رشته را وارد و ذخیره کنید',
      );
    }

    final levels = state.selectedSport?.levels ?? [];

    return Column(
      children: [
        Expanded(
          child: levels.isEmpty
              ? _buildEmptyState(
                  icon: Icons.layers_outlined,
                  title: 'هیچ سطحی تعریف نشده',
                  subtitle: 'سطوح مختلف رشته ورزشی را اضافه کنید',
                  buttonText: 'افزودن اولین سطح',
                  onPressed: _addLevel,
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
        if (levels.isNotEmpty) _buildBottomButton('افزودن سطح جدید', _addLevel),
      ],
    );
  }

  Widget _buildLockedTab({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: Colors.orange.shade400),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => _tabController.animateTo(0),
              icon: const Icon(Icons.arrow_back),
              label: const Text('رفتن به اطلاعات پایه'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.add),
              label: Text(buttonText),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelCard(Level level, int index, {required Key key}) {
    return Card(
      key: key,
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.drag_handle,
              color: Colors.blue.shade400,
              size: 20,
            ),
          ),
          title: Text(
            level.name,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          subtitle: Text(
            '${level.techniques.length} تکنیک',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildIconButton(
                Icons.edit_outlined,
                Colors.blue,
                () => _editLevel(level),
              ),
              const SizedBox(width: 4),
              _buildIconButton(
                Icons.delete_outline,
                Colors.red,
                () => _deleteLevel(level),
              ),
            ],
          ),
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Column(
                children: [
                  if (level.techniques.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Icon(
                            Icons.sports_gymnastics,
                            size: 40,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'هیچ تکنیکی تعریف نشده',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    )
                  else
                    ...level.techniques.map((technique) {
                      return ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.blue.shade100,
                          child: Text(
                            '${technique.order}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                        title: Text(
                          technique.name,
                          style: const TextStyle(fontSize: 14),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildSmallIconButton(
                              Icons.edit_outlined,
                              () => _editTechnique(level, technique),
                            ),
                            _buildSmallIconButton(
                              Icons.delete_outline,
                              () => _deleteTechnique(level, technique),
                              color: Colors.red,
                            ),
                          ],
                        ),
                      );
                    }),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: OutlinedButton.icon(
                      onPressed: () => _addTechnique(level),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('افزودن تکنیک'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, Color color, VoidCallback onPressed) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }

  Widget _buildSmallIconButton(
    IconData icon,
    VoidCallback onPressed, {
    Color? color,
  }) {
    return IconButton(
      icon: Icon(icon, size: 18, color: color ?? Colors.grey.shade600),
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
    );
  }

  Widget _buildPerformanceRatingsTab(SportState state) {
    final canEdit = _isNewSportSaved || isEditMode;

    if (!canEdit) {
      return _buildLockedTab(
        icon: Icons.star_outline,
        title: 'ابتدا اطلاعات پایه را ذخیره کنید',
        subtitle: 'برای مدیریت سطوح عملکرد، ابتدا رشته را ذخیره کنید',
      );
    }

    final ratings = state.selectedSport?.performanceRatings ?? [];

    return Column(
      children: [
        Expanded(
          child: ratings.isEmpty
              ? _buildEmptyState(
                  icon: Icons.star_outline,
                  title: 'هیچ سطح عملکردی تعریف نشده',
                  subtitle: 'سطوح عملکرد برای ارزیابی تکنیک‌ها استفاده می‌شوند',
                  buttonText: 'افزودن سطح عملکرد',
                  onPressed: _addPerformanceRating,
                )
              : ReorderableListView.builder(
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
        if (ratings.isNotEmpty)
          _buildBottomButton('افزودن سطح عملکرد جدید', _addPerformanceRating),
      ],
    );
  }

  Widget _buildPerformanceRatingCard(
    PerformanceRating rating,
    int index, {
    required Key key,
  }) {
    final color = _parseColor(rating.color);

    return Card(
      key: key,
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.drag_handle, color: color, size: 20),
        ),
        title: Text(
          rating.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              'ترتیب: ${rating.order}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIconButton(
              Icons.edit_outlined,
              Colors.blue,
              () => _editPerformanceRating(rating),
            ),
            const SizedBox(width: 4),
            _buildIconButton(
              Icons.delete_outline,
              Colors.red,
              () => _deletePerformanceRating(rating),
            ),
          ],
        ),
      ),
    );
  }

  Color _parseColor(String? colorHex) {
    if (colorHex == null || colorHex.isEmpty) return Colors.grey;
    try {
      return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.grey;
    }
  }

  Widget _buildBottomButton(String text, VoidCallback onPressed) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.add),
          label: Text(text),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveSport() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      // validation دستی
      final name = _nameController.text.trim();
      if (name.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 8),
                Text('نام رشته الزامی است'),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
        return;
      }
    }

    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();

    bool success;
    // اگر در حالت ویرایش هستیم یا قبلاً ذخیره شده، update کن
    if (isEditMode || _isNewSportSaved) {
      success = await ref
          .read(sportProvider.notifier)
          .updateSportBasicInfo(
            name: name,
            description: description.isEmpty ? null : description,
          );
    } else {
      // فقط برای اولین بار create کن
      success = await ref
          .read(sportProvider.notifier)
          .createSport(
            name: name,
            description: description.isEmpty ? null : description,
          );
    }

    if (mounted) {
      final state = ref.read(sportProvider);
      if (success && state.successMessage != null) {
        setState(() {
          _isNewSportSaved = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(state.successMessage!),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
        if (!isEditMode) {
          _tabController.animateTo(1);
        }
      } else if (state.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(state.errorMessage!)),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  Future<void> _addLevel() async {
    final result = await _showInputDialog(
      title: 'افزودن سطح جدید',
      hint: 'مثال: سطح 1، مبتدی، پیشرفته',
      label: 'نام سطح',
      icon: Icons.layers_outlined,
    );

    if (result != null && result.isNotEmpty) {
      await ref.read(sportProvider.notifier).addLevel(result);
      _showMessage();
    }
  }

  Future<void> _editLevel(Level level) async {
    final result = await _showInputDialog(
      title: 'ویرایش سطح',
      label: 'نام سطح',
      initialValue: level.name,
      icon: Icons.edit_outlined,
    );

    if (result != null && result.isNotEmpty) {
      await ref.read(sportProvider.notifier).updateLevel(level.id, result);
      _showMessage();
    }
  }

  Future<void> _deleteLevel(Level level) async {
    final confirmed = await _showDeleteConfirmDialog(
      'حذف سطح',
      'آیا از حذف سطح "${level.name}" و تمام تکنیک‌های آن اطمینان دارید؟',
    );

    if (confirmed) {
      await ref.read(sportProvider.notifier).deleteLevel(level.id);
      _showMessage();
    }
  }

  Future<void> _addTechnique(Level level) async {
    final result = await _showInputDialog(
      title: 'افزودن تکنیک جدید',
      hint: 'مثال: شنای آزاد، ضربه پا',
      label: 'نام تکنیک',
      icon: Icons.sports_gymnastics,
    );

    if (result != null && result.isNotEmpty) {
      await ref.read(sportProvider.notifier).addTechnique(level.id, result);
      _showMessage();
    }
  }

  Future<void> _editTechnique(Level level, Technique technique) async {
    final result = await _showInputDialog(
      title: 'ویرایش تکنیک',
      label: 'نام تکنیک',
      initialValue: technique.name,
      icon: Icons.edit_outlined,
    );

    if (result != null && result.isNotEmpty) {
      await ref
          .read(sportProvider.notifier)
          .updateTechnique(level.id, technique.id, result);
      _showMessage();
    }
  }

  Future<void> _deleteTechnique(Level level, Technique technique) async {
    final confirmed = await _showDeleteConfirmDialog(
      'حذف تکنیک',
      'آیا از حذف تکنیک "${technique.name}" اطمینان دارید؟',
    );

    if (confirmed) {
      await ref
          .read(sportProvider.notifier)
          .deleteTechnique(level.id, technique.id);
      _showMessage();
    }
  }

  Future<void> _addPerformanceRating() async {
    final result = await _showInputDialog(
      title: 'افزودن سطح عملکرد',
      hint: 'مثال: عالی، خوب، متوسط',
      label: 'نام سطح عملکرد',
      icon: Icons.star_outline,
    );

    if (result != null && result.isNotEmpty) {
      await ref.read(sportProvider.notifier).addPerformanceRating(result);
      _showMessage();
    }
  }

  Future<void> _editPerformanceRating(PerformanceRating rating) async {
    final result = await _showInputDialog(
      title: 'ویرایش سطح عملکرد',
      label: 'نام سطح عملکرد',
      initialValue: rating.name,
      icon: Icons.edit_outlined,
    );

    if (result != null && result.isNotEmpty) {
      await ref
          .read(sportProvider.notifier)
          .updatePerformanceRating(rating.id, result);
      _showMessage();
    }
  }

  Future<void> _deletePerformanceRating(PerformanceRating rating) async {
    final confirmed = await _showDeleteConfirmDialog(
      'حذف سطح عملکرد',
      'آیا از حذف سطح عملکرد "${rating.name}" اطمینان دارید؟',
    );

    if (confirmed) {
      await ref.read(sportProvider.notifier).deletePerformanceRating(rating.id);
      _showMessage();
    }
  }

  Future<String?> _showInputDialog({
    required String title,
    required String label,
    String? hint,
    String? initialValue,
    required IconData icon,
  }) async {
    final controller = TextEditingController(text: initialValue);

    return showDialog<String>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.blue.shade700, size: 20),
              ),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(fontSize: 18)),
            ],
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
              ),
            ),
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                Navigator.pop(context, value.trim());
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('لغو', style: TextStyle(color: Colors.grey.shade600)),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  Navigator.pop(context, controller.text.trim());
                }
              },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(initialValue != null ? 'ذخیره' : 'افزودن'),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _showDeleteConfirmDialog(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.delete_outline,
                  color: Colors.red.shade700,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(fontSize: 18)),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('لغو', style: TextStyle(color: Colors.grey.shade600)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );
    return result ?? false;
  }

  void _showMessage() {
    if (!mounted) return;
    final state = ref.read(sportProvider);
    if (state.successMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text(state.successMessage!),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    } else if (state.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(state.errorMessage!)),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }
}
