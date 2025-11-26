import "package:hydroponic_app/models/system_setting.dart";
import 'database_helper.dart';

class SettingsDao {
  final DatabaseHelper dbHelper = DatabaseHelper();

  // Get all system settings
  Future<List<SystemSetting>> getAllSettings() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('system_settings');
    return List.generate(maps.length, (i) => SystemSetting.fromMap(maps[i]));
  }

  // Get a specific setting by key
  Future<SystemSetting?> getSetting(String key) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'system_settings',
      where: 'setting_key = ?',
      whereArgs: [key],
    );
    if (maps.isEmpty) return null;
    return SystemSetting.fromMap(maps.first);
  }

  // Update a setting value
  Future<int> updateSetting(String key, String newValue) async {
    final db = await dbHelper.database;
    return await db.update(
      'system_settings',
      {'setting_value': newValue},
      where: 'setting_key = ?',
      whereArgs: [key],
    );
  }

  // Get setting as specific type with fallback
  Future<double> getSettingAsDouble(String key, double defaultValue) async {
    final setting = await getSetting(key);
    if (setting == null) return defaultValue;
    return setting.asDouble;
  }

  Future<int> getSettingAsInt(String key, int defaultValue) async {
    final setting = await getSetting(key);
    if (setting == null) return defaultValue;
    return setting.asInt;
  }

  Future<bool> getSettingAsBool(String key, bool defaultValue) async {
    final setting = await getSetting(key);
    if (setting == null) return defaultValue;
    return setting.asBool;
  }

  Future<String> getSettingAsString(String key, String defaultValue) async {
    final setting = await getSetting(key);
    if (setting == null) return defaultValue;
    return setting.asString;
  }

  // Bulk update multiple settings
  Future<void> updateMultipleSettings(Map<String, String> settings) async {
    final db = await dbHelper.database;
    final batch = db.batch();

    for (final entry in settings.entries) {
      batch.update(
        'system_settings',
        {'setting_value': entry.value},
        where: 'setting_key = ?',
        whereArgs: [entry.key],
      );
    }

    await batch.commit();
  }

  // Reset settings to defaults - FIXED
  Future<void> resetToDefaults() async {
    final db = await dbHelper.database;

    // Delete existing settings
    await db.delete('system_settings');

    // Re-insert default data using the PUBLIC method
    await dbHelper.insertDefaultData(db);
  }
}