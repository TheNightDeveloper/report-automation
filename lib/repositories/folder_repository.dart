import 'package:hive/hive.dart';
import '../models/models.dart';

class FolderRepository {
  static const String _boxName = 'folders';

  Future<Box<Folder>> _getBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      return await Hive.openBox<Folder>(_boxName);
    }
    return Hive.box<Folder>(_boxName);
  }

  /// بارگذاری همه پوشه‌ها
  Future<List<Folder>> loadFolders() async {
    try {
      final box = await _getBox();
      return box.values.toList();
    } catch (e) {
      throw Exception('خطا در بارگذاری پوشه‌ها: ${e.toString()}');
    }
  }

  /// ذخیره یک پوشه
  Future<void> saveFolder(Folder folder) async {
    try {
      final box = await _getBox();
      await box.put(folder.id, folder);
    } catch (e) {
      throw Exception('خطا در ذخیره پوشه: ${e.toString()}');
    }
  }

  /// ذخیره لیست پوشه‌ها
  Future<void> saveFolders(List<Folder> folders) async {
    try {
      final box = await _getBox();
      await box.clear();
      for (final folder in folders) {
        await box.put(folder.id, folder);
      }
    } catch (e) {
      throw Exception('خطا در ذخیره پوشه‌ها: ${e.toString()}');
    }
  }

  /// حذف یک پوشه
  Future<void> deleteFolder(String folderId) async {
    try {
      final box = await _getBox();
      await box.delete(folderId);
    } catch (e) {
      throw Exception('خطا در حذف پوشه: ${e.toString()}');
    }
  }

  /// حذف همه پوشه‌ها
  Future<void> deleteAllFolders() async {
    try {
      final box = await _getBox();
      await box.clear();
    } catch (e) {
      throw Exception('خطا در حذف همه پوشه‌ها: ${e.toString()}');
    }
  }

  /// دریافت یک پوشه با ID
  Future<Folder?> getFolderById(String folderId) async {
    try {
      final box = await _getBox();
      return box.get(folderId);
    } catch (e) {
      throw Exception('خطا در دریافت پوشه: ${e.toString()}');
    }
  }
}
