import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'utils/app_theme.dart';
import 'services/hive_service.dart';
import 'services/migration_service.dart';
import 'repositories/sport_repository.dart';
import 'repositories/report_card_repository.dart';
import 'screens/main_screen.dart';
import 'screens/migration_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // راه‌اندازی Hive
  await Hive.initFlutter();

  // 🔴 پاک کردن داده‌های قدیمی (فقط یک بار - بعد از اجرا این خطوط را کامنت کنید)
  // await Hive.deleteBoxFromDisk('reportCards');
  // await Hive.deleteBoxFromDisk('students');
  // await Hive.deleteBoxFromDisk('appData');

  await HiveService.initialize();

  // بررسی نیاز به migration
  bool needsAnyMigration = false;
  try {
    final sportRepository = SportRepository();
    final reportCardRepository = ReportCardRepository();
    final migrationService = MigrationService(
      sportRepository,
      reportCardRepository,
    );

    final needsMigration = await migrationService.needsMigration();
    final needsIdMigration = await migrationService.needsIdMigration();

    needsAnyMigration = needsMigration || needsIdMigration;
  } catch (e) {
    print('خطا در بررسی migration: $e');
  }

  runApp(ProviderScope(child: MyApp(needsMigration: needsAnyMigration)));
}

class MyApp extends StatelessWidget {
  final bool needsMigration;

  const MyApp({super.key, this.needsMigration = false});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'کارنامه الکترونیکی',
      debugShowCheckedModeBanner: false,

      // تنظیم Theme
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,

      // تنظیم زبان فارسی
      locale: const Locale('fa', 'IR'),
      supportedLocales: const [Locale('fa', 'IR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // Responsive Framework
      builder: (context, child) => ResponsiveBreakpoints.builder(
        child: child!,
        breakpoints: [
          const Breakpoint(start: 0, end: 450, name: MOBILE),
          const Breakpoint(start: 451, end: 800, name: TABLET),
          const Breakpoint(start: 801, end: 1920, name: DESKTOP),
          const Breakpoint(start: 1921, end: double.infinity, name: '4K'),
        ],
      ),

      // صفحه اصلی
      initialRoute: needsMigration ? '/migration' : '/',

      // Routes
      routes: {
        '/': (context) => const MainScreen(),
        '/migration': (context) => const MigrationScreen(),
      },
    );
  }
}
