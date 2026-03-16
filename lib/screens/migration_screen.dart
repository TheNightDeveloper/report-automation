import 'package:flutter/material.dart';
import '../services/migration_service.dart';
import '../repositories/sport_repository.dart';
import '../repositories/report_card_repository.dart';

class MigrationScreen extends StatefulWidget {
  const MigrationScreen({super.key});

  @override
  State<MigrationScreen> createState() => _MigrationScreenState();
}

class _MigrationScreenState extends State<MigrationScreen> {
  String _status = 'در حال بررسی...';
  bool _isComplete = false;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _runMigrations();
  }

  Future<void> _runMigrations() async {
    try {
      final sportRepository = SportRepository();
      final reportCardRepository = ReportCardRepository();
      final migrationService = MigrationService(
        sportRepository,
        reportCardRepository,
      );

      // بررسی نیاز به migration نسخه 2
      setState(() => _status = 'بررسی نیاز به migration ساختار...');
      final needsMigration = await migrationService.needsMigration();

      if (needsMigration) {
        setState(() => _status = 'در حال migration ساختار داده‌ها...');
        await migrationService.migrateToV2();
      }

      // بررسی نیاز به migration ID ها
      setState(() => _status = 'بررسی نیاز به migration شناسه‌ها...');
      final needsIdMigration = await migrationService.needsIdMigration();

      if (needsIdMigration) {
        setState(() => _status = 'در حال تبدیل شناسه‌های دانش‌آموزان...');
        await migrationService.migrateStudentIds();
      }

      setState(() {
        _status = 'Migration با موفقیت کامل شد!';
        _isComplete = true;
      });

      // بعد از 2 ثانیه به صفحه اصلی برو
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/');
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _status = 'خطا در migration';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_hasError && !_isComplete)
                const CircularProgressIndicator()
              else if (_isComplete)
                const Icon(Icons.check_circle, size: 64, color: Colors.green)
              else
                const Icon(Icons.error, size: 64, color: Colors.red),

              const SizedBox(height: 24),

              Text(
                _status,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),

              if (_hasError && _errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacementNamed('/');
                  },
                  child: const Text('ادامه به برنامه'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
