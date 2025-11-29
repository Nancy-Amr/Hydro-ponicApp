import '../models/alert.dart';
import 'database_helper.dart';
import 'package:sqflite/sqflite.dart';
class AlertDao {
  final DatabaseHelper dbHelper = DatabaseHelper();

  // Insert a new alert
  Future<int> insertAlert(Alert alert) async {
    final db = await dbHelper.database;
    return await db.insert('alerts', alert.toMap());
  }

  // Get all alerts
  Future<List<Alert>> getAllAlerts() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'alerts',
      orderBy: 'timestamp DESC',
    );
    return List.generate(maps.length, (i) => Alert.fromMap(maps[i]));
  }

  // Acknowledge alert
  Future<void> acknowledgeAlert(int alertId) async {
    final db = await dbHelper.database;
    await db.update(
      'alerts',
      {'acknowledged': 1},
      where: 'id = ?',
      whereArgs: [alertId],
    );
  }

  // Acknowledge all alerts
  Future<void> acknowledgeAllAlerts() async {
    final db = await dbHelper.database;
    await db.update(
      'alerts',
      {'acknowledged': 1},
    );
  }

  // Get unsynced alerts
  Future<List<Alert>> getUnsyncedAlerts() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'alerts',
      where: 'synced_with_firebase = ? OR synced_with_firebase IS NULL',
    );
    return List.generate(maps.length, (i) => Alert.fromMap(maps[i]));
  }

  // Mark alert as synced
  Future<void> markAsSynced(int id) async {
    final db = await dbHelper.database;
    await db.update(
      'alerts',
      {'synced_with_firebase': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Get last sync time
  Future<DateTime?> getLastSyncTime() async {
    final db = await dbHelper.database;
    try {
      final result = await db.query(
        'sync_status',
        where: 'table_name = ?',
        whereArgs: ['alerts'],
      );
      
      if (result.isEmpty) return null;
      return DateTime.parse(result.first['last_sync_time'] as String);
    } catch (e) {
      return null;
    }
  }

  // Update last sync time
  Future<void> updateLastSyncTime() async {
    final db = await dbHelper.database;
    final now = DateTime.now().toIso8601String();
    
    await db.insert(
      'sync_status',
      {
        'table_name': 'alerts',
        'last_sync_time': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}