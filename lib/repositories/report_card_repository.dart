import 'package:hive_flutter/hive_flutter.dart';
import '../models/models.dart';

class ReportCardRepository {
  static const String _boxName = 'report_cards';
  Box<ReportCard>? _box;

  Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      _box = await Hive.openBox<ReportCard>(_boxName);
    } else {
      _box = Hive.box<ReportCard>(_boxName);
    }
  }

  Future<void> saveReportCard(ReportCard reportCard) async {
    await init();
    await _box!.put(reportCard.studentId, reportCard);
  }

  Future<ReportCard?> loadReportCard(String studentId) async {
    await init();
    return _box!.get(studentId);
  }

  Future<List<ReportCard>> loadAllReportCards() async {
    await init();
    return _box!.values.toList();
  }

  Future<void> deleteReportCard(String studentId) async {
    await init();
    await _box!.delete(studentId);
  }

  Future<void> deleteAllReportCards() async {
    await init();
    await _box!.clear();
  }

  Future<bool> hasReportCard(String studentId) async {
    await init();
    return _box!.containsKey(studentId);
  }

  Future<int> getReportCardCount() async {
    await init();
    return _box!.length;
  }

  Future<void> close() async {
    if (_box?.isOpen ?? false) {
      await _box!.close();
    }
  }
}
