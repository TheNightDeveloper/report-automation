import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../viewmodels/sport_viewmodel.dart';
import '../viewmodels/student_viewmodel.dart';
import '../models/models.dart';
import 'student_list_screen.dart';
import 'report_card_screen.dart';
import 'export_screen.dart';
import 'sports_list_screen.dart';
import 'sport_form_screen.dart';
import 'settings_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _selectedIndex = 0;
  Sport? _selectedSport;

  @override
  void initState() {
    super.initState();
    // بارگذاری رشته‌های ورزشی
    Future.microtask(() async {
      await ref.read(sportProvider.notifier).loadSports();
      // انتخاب رشته پیش‌فرض
      final state = ref.read(sportProvider);
      if (state.sports.isNotEmpty) {
        setState(() {
          _selectedSport = state.defaultSport ?? state.sports.first;
        });
      }
    });
  }

  List<Widget> get _screens => [
    _DashboardScreen(
      selectedSport: _selectedSport,
      onSportSelected: _onSportSelected,
      onManageSports: () => _onItemTapped(4),
      onStudentSelected: () => _onItemTapped(1),
    ),
    StudentListScreen(onStudentSelected: () => _onItemTapped(2)),
    ReportCardScreen(key: ValueKey(_selectedSport?.id)),
    const ExportScreen(),
    const SportsListScreen(),
    const SettingsScreen(),
  ];

  final List<NavigationItem> _navItems = const [
    NavigationItem(
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      label: 'داشبورد',
    ),
    NavigationItem(
      icon: Icons.people_outline,
      selectedIcon: Icons.people,
      label: 'دانش‌آموزان',
    ),
    NavigationItem(
      icon: Icons.description_outlined,
      selectedIcon: Icons.description,
      label: 'کارنامه',
    ),
    NavigationItem(
      icon: Icons.file_download_outlined,
      selectedIcon: Icons.file_download,
      label: 'خروجی',
    ),
    NavigationItem(
      icon: Icons.sports_outlined,
      selectedIcon: Icons.sports,
      label: 'رشته‌ها',
    ),
    NavigationItem(
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      label: 'تنظیمات',
    ),
  ];

  void _onSportSelected(Sport sport) {
    setState(() {
      _selectedSport = sport;
    });
    ref.read(sportProvider.notifier).selectSport(sport);
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveBreakpoints.of(context);

    return CallbackShortcuts(
      bindings: _buildKeyboardShortcuts(),
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: Row(
            children: [
              // Sidebar برای صفحات بزرگ
              if (responsive.largerThan(TABLET))
                _buildSidebar()
              else if (responsive.equals(TABLET))
                _buildRail(),

              // محتوای اصلی
              Expanded(child: _screens[_selectedIndex]),
            ],
          ),

          // Bottom Navigation برای موبایل
          bottomNavigationBar: responsive.smallerThan(TABLET)
              ? _buildBottomNav()
              : null,
        ),
      ),
    );
  }

  // Sidebar برای Desktop
  Widget _buildSidebar() {
    final sportState = ref.watch(sportProvider);

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          left: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Icon(
                  Icons.school,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  'کارنامه الکترونیکی',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // انتخاب رشته ورزشی
          if (sportState.sports.isNotEmpty) _buildSportSelector(sportState),

          const Divider(height: 1),

          // Navigation Items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _navItems.length,
              itemBuilder: (context, index) {
                final item = _navItems[index];
                final isSelected = _selectedIndex == index;

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child: ListTile(
                    selected: isSelected,
                    leading: Icon(isSelected ? item.selectedIcon : item.icon),
                    title: Text(item.label),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    onTap: () => _onItemTapped(index),
                  ),
                );
              },
            ),
          ),

          const Divider(height: 1),

          // Footer
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'نسخه 2.0.0',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSportSelector(SportState sportState) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.sports, size: 20),
              const SizedBox(width: 8),
              Text('رشته ورزشی', style: Theme.of(context).textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _selectedSport?.id,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            items: sportState.sports.map((sport) {
              return DropdownMenuItem<String>(
                value: sport.id,
                child: Row(
                  children: [
                    Text(sport.name),
                    if (sport.isDefault) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'پیش‌فرض',
                          style: TextStyle(fontSize: 10, color: Colors.white),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
            onChanged: (sportId) {
              if (sportId != null) {
                final sport = sportState.sports.firstWhere(
                  (s) => s.id == sportId,
                );
                _onSportSelected(sport);
              }
            },
          ),
        ],
      ),
    );
  }

  // Rail برای Tablet
  Widget _buildRail() {
    return NavigationRail(
      selectedIndex: _selectedIndex,
      onDestinationSelected: _onItemTapped,
      labelType: NavigationRailLabelType.all,
      leading: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Icon(
          Icons.school,
          size: 32,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      destinations: _navItems
          .map(
            (item) => NavigationRailDestination(
              icon: Icon(item.icon),
              selectedIcon: Icon(item.selectedIcon),
              label: Text(item.label),
            ),
          )
          .toList(),
    );
  }

  // Bottom Navigation برای Mobile
  Widget _buildBottomNav() {
    return NavigationBar(
      selectedIndex: _selectedIndex,
      onDestinationSelected: _onItemTapped,
      destinations: _navItems
          .map(
            (item) => NavigationDestination(
              icon: Icon(item.icon),
              selectedIcon: Icon(item.selectedIcon),
              label: item.label,
            ),
          )
          .toList(),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Keyboard Shortcuts برای Windows
  Map<ShortcutActivator, VoidCallback> _buildKeyboardShortcuts() {
    return {
      const SingleActivator(LogicalKeyboardKey.digit1, control: true): () =>
          _onItemTapped(0),
      const SingleActivator(LogicalKeyboardKey.digit2, control: true): () =>
          _onItemTapped(1),
      const SingleActivator(LogicalKeyboardKey.digit3, control: true): () =>
          _onItemTapped(2),
      const SingleActivator(LogicalKeyboardKey.digit4, control: true): () =>
          _onItemTapped(3),
      const SingleActivator(LogicalKeyboardKey.digit5, control: true): () =>
          _onItemTapped(4),
      const SingleActivator(LogicalKeyboardKey.digit6, control: true): () =>
          _onItemTapped(5),
    };
  }
}

// Navigation Item Model
class NavigationItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const NavigationItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

// ========== Dashboard Screen ==========
class _DashboardScreen extends ConsumerWidget {
  final Sport? selectedSport;
  final Function(Sport) onSportSelected;
  final VoidCallback onManageSports;
  final VoidCallback onStudentSelected;

  const _DashboardScreen({
    required this.selectedSport,
    required this.onSportSelected,
    required this.onManageSports,
    required this.onStudentSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sportState = ref.watch(sportProvider);
    final studentState = ref.watch(studentProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('داشبورد'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'بارگذاری مجدد',
            onPressed: () {
              ref.read(sportProvider.notifier).loadSports();
              ref.read(studentProvider.notifier).loadStudents();
            },
          ),
        ],
      ),
      body: sportState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // خوش‌آمدگویی
                  _buildWelcomeCard(context),
                  const SizedBox(height: 24),

                  // آمار کلی
                  _buildStatsRow(context, sportState, studentState),
                  const SizedBox(height: 24),

                  // رشته‌های ورزشی
                  _buildSportsSection(context, ref, sportState),
                  const SizedBox(height: 24),

                  // دسترسی سریع
                  _buildQuickActions(context),
                ],
              ),
            ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Icon(
              Icons.school,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'سیستم کارنامه الکترونیکی',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'مدیریت کارنامه‌های ورزشی با پشتیبانی از رشته‌های مختلف',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (selectedSport != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'رشته فعال: ${selectedSport!.name}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(
    BuildContext context,
    SportState sportState,
    StudentState studentState,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.sports,
            title: 'رشته‌های ورزشی',
            value: sportState.sports.length.toString(),
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.people,
            title: 'دانش‌آموزان',
            value: studentState.students.length.toString(),
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.check_circle,
            title: 'کارنامه تکمیل',
            value: studentState.completedCount.toString(),
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.layers,
            title: 'سطوح',
            value: selectedSport?.levels.length.toString() ?? '0',
            color: Colors.purple,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSportsSection(
    BuildContext context,
    WidgetRef ref,
    SportState sportState,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'رشته‌های ورزشی',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: onManageSports,
              icon: const Icon(Icons.settings),
              label: const Text('مدیریت'),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SportFormScreen(),
                  ),
                ).then((_) {
                  ref.read(sportProvider.notifier).loadSports();
                });
              },
              icon: const Icon(Icons.add),
              label: const Text('رشته جدید'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (sportState.sports.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.sports, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text('هیچ رشته ورزشی تعریف نشده است'),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SportFormScreen(),
                          ),
                        ).then((_) {
                          ref.read(sportProvider.notifier).loadSports();
                        });
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('ایجاد رشته اول'),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: sportState.sports.length,
              itemBuilder: (context, index) {
                final sport = sportState.sports[index];
                final isSelected = selectedSport?.id == sport.id;
                return _buildSportCard(context, sport, isSelected);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildSportCard(BuildContext context, Sport sport, bool isSelected) {
    final totalTechniques = sport.levels.fold<int>(
      0,
      (sum, level) => sum + level.techniques.length,
    );

    return Container(
      width: 200,
      margin: const EdgeInsets.only(left: 16),
      child: Card(
        elevation: isSelected ? 4 : 1,
        color: isSelected
            ? Theme.of(context).colorScheme.primaryContainer
            : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isSelected
              ? BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                )
              : BorderSide.none,
        ),
        child: InkWell(
          onTap: () => onSportSelected(sport),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.sports,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
                    ),
                    const Spacer(),
                    if (sport.isDefault)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'پیش‌فرض',
                          style: TextStyle(fontSize: 10, color: Colors.white),
                        ),
                      ),
                    if (isSelected && !sport.isDefault)
                      const Icon(Icons.check_circle, color: Colors.green),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  sport.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Row(
                  children: [
                    _buildMiniStat(
                      context,
                      Icons.layers,
                      '${sport.levels.length}',
                    ),
                    const SizedBox(width: 16),
                    _buildMiniStat(
                      context,
                      Icons.fitness_center,
                      '$totalTechniques',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(BuildContext context, IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 4),
        Text(value, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('دسترسی سریع', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context,
                icon: Icons.upload_file,
                title: 'بارگذاری دانش‌آموزان',
                subtitle: 'از فایل Excel',
                color: Colors.blue,
                onTap: onStudentSelected,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                context,
                icon: Icons.add_circle,
                title: 'ایجاد رشته جدید',
                subtitle: 'تعریف رشته ورزشی',
                color: Colors.green,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SportFormScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                context,
                icon: Icons.settings,
                title: 'مدیریت رشته‌ها',
                subtitle: 'ویرایش و حذف',
                color: Colors.orange,
                onTap: onManageSports,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
