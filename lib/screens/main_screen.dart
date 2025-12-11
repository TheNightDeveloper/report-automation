import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'student_list_screen.dart';
import 'report_card_screen.dart';
import 'export_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    StudentListScreen(),
    ReportCardScreen(),
    ExportScreen(),
  ];

  final List<NavigationItem> _navItems = const [
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
  ];

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
    return Container(
      width: 250,
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
            padding: const EdgeInsets.all(24),
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
                const SizedBox(height: 4),
                Text(
                  'آموزشگاه شنا',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

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
              'نسخه 1.0.0',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
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
      // Ctrl+1: دانش‌آموزان
      const SingleActivator(LogicalKeyboardKey.digit1, control: true): () =>
          _onItemTapped(0),

      // Ctrl+2: کارنامه
      const SingleActivator(LogicalKeyboardKey.digit2, control: true): () =>
          _onItemTapped(1),

      // Ctrl+3: خروجی
      const SingleActivator(LogicalKeyboardKey.digit3, control: true): () =>
          _onItemTapped(2),
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
