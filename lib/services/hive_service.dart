import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../models/models.dart';

class HiveService {
  static bool _initialized = false;

  static Future<void> initialize() async {
    await init();
  }

  static Future<void> init() async {
    if (_initialized) return;

    // Get Documents directory and create custom path
    final documentsDir = await getApplicationDocumentsDirectory();
    final customPath = Directory('${documentsDir.path}/karnameh/data');

    // Create directory if it doesn't exist
    if (!await customPath.exists()) {
      await customPath.create(recursive: true);
    }

    // Initialize Hive with custom path
    await Hive.initFlutter(customPath.path);

    // Register adapters - existing
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(StudentAdapter());
    }
    if (!Hive.isAdapterRegistered(7)) {
      Hive.registerAdapter(StudentInfoAdapter());
    }
    if (!Hive.isAdapterRegistered(6)) {
      Hive.registerAdapter(AttendanceInfoAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(TechniqueEvaluationAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(SectionEvaluationAdapter());
    }
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(ReportCardAdapter());
    }

    // Register new adapters
    if (!Hive.isAdapterRegistered(8)) {
      Hive.registerAdapter(SportAdapter());
    }
    if (!Hive.isAdapterRegistered(9)) {
      Hive.registerAdapter(LevelAdapter());
    }
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(TechniqueAdapter());
    }
    if (!Hive.isAdapterRegistered(11)) {
      Hive.registerAdapter(PerformanceRatingAdapter());
    }
    if (!Hive.isAdapterRegistered(12)) {
      Hive.registerAdapter(LevelEvaluationAdapter());
    }
    if (!Hive.isAdapterRegistered(13)) {
      Hive.registerAdapter(FolderAdapter());
    }

    _initialized = true;
  }

  static Future<void> closeAll() async {
    await Hive.close();
    _initialized = false;
  }

  static Future<void> deleteAll() async {
    await Hive.deleteFromDisk();
    _initialized = false;
  }
}
