import '../models/system_setting.dart';
import 'database_helper.dart';

class SettingsDao {
  final DatabaseHelper dbHelper = DatabaseHelper();

  // Get all settings
  Future<List<SystemSetting>> getAllSettings() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('system_settings');
    return List.generate(maps.length, (i) => SystemSetting.fromMap(maps[i]));
  }

  // Update setting
  Future<void> updateSetting(String key, String value) async {
    final db = await dbHelper.database;
    await db.update(
      'system_settings',
      {'setting_value': value},
      where: 'setting_key = ?',
      whereArgs: [key],
    );
  }

  // Update multiple settings
  Future<void> updateMultipleSettings(Map<String, String> settings) async {
    final db = await dbHelper.database;
    final batch = db.batch();
    
    settings.forEach((key, value) {
      batch.update(
        'system_settings',
        {'setting_value': value},
        where: 'setting_key = ?',
        whereArgs: [key],
      );
    });
    
    await batch.commit();
  }

  // Reset to defaults
  Future<void> resetToDefaults() async {
    final db = await dbHelper.database;
    final defaultSettings = [
      {'setting_key': 'temp_min', 'setting_value': '18.0'},
      {'setting_key': 'temp_max', 'setting_value': '26.0'},
      {'setting_key': 'humidity_min', 'setting_value': '50.0'},
      {'setting_key': 'humidity_max', 'setting_value': '70.0'},
      {'setting_key': 'ph_min', 'setting_value': '5.8'},
      {'setting_key': 'ph_max', 'setting_value': '6.2'},
      {'setting_key': 'water_level_min', 'setting_value': '60.0'},
      {'setting_key': 'water_level_max', 'setting_value': '90.0'},
      {'setting_key': 'light_intensity_min', 'setting_value': '25000.0'},
      {'setting_key': 'light_intensity_max', 'setting_value': '40000.0'},
      {'setting_key': 'auto_mode', 'setting_value': 'true'},
    ];

    final batch = db.batch();
    for (final setting in defaultSettings) {
      batch.update(
        'system_settings',
        {'setting_value': setting['setting_value']},
        where: 'setting_key = ?',
        whereArgs: [setting['setting_key']],
      );
    }
    await batch.commit();
  }
}