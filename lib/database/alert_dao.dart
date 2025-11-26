
import '../models/alert.dart';
import 'database_helper.dart';



class AlertDao {
  final DatabaseHelper dbHelper = DatabaseHelper();

  // Create a new alert
  Future<int> insertAlert(Alert alert) async {
    final db = await dbHelper.database;
    return await db.insert('alerts', alert.toMap());
  }

  // Get all alerts (latest first)
  Future<List<Alert>> getAllAlerts() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'alerts',
      orderBy: 'timestamp DESC',
    );
    return List.generate(maps.length, (i) => Alert.fromMap(maps[i]));
  }

  // Get unacknowledged alerts only
  Future<List<Alert>> getUnacknowledgedAlerts() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'alerts',
      where: 'acknowledged = ?',
      whereArgs: [0],
      orderBy: 'timestamp DESC',
    );
    return List.generate(maps.length, (i) => Alert.fromMap(maps[i]));
  }

  // Get alerts by severity
  Future<List<Alert>> getAlertsBySeverity(String severity) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'alerts',
      where: 'severity = ?',
      whereArgs: [severity],
      orderBy: 'timestamp DESC',
    );
    return List.generate(maps.length, (i) => Alert.fromMap(maps[i]));
  }

  // Mark alert as acknowledged
  Future<int> acknowledgeAlert(int alertId) async {
    final db = await dbHelper.database;
    return await db.update(
      'alerts',
      {'acknowledged': 1},
      where: 'id = ?',
      whereArgs: [alertId],
    );
  }

  // Mark all alerts as acknowledged
  Future<int> acknowledgeAllAlerts() async {
    final db = await dbHelper.database;
    return await db.update(
      'alerts',
      {'acknowledged': 1},
    );
  }

  // Delete a specific alert
  Future<int> deleteAlert(int alertId) async {
    final db = await dbHelper.database;
    return await db.delete(
      'alerts',
      where: 'id = ?',
      whereArgs: [alertId],
    );
  }

  // Delete old acknowledged alerts (keep last 30 days)
  Future<int> deleteOldAlerts({int daysToKeep = 30}) async {
    final db = await dbHelper.database;
    final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
    
    return await db.delete(
      'alerts',
      where: 'acknowledged = 1 AND timestamp < ?',
      whereArgs: [cutoffDate.toIso8601String()],
    );
  }

  // Get alert statistics
  Future<Map<String, int>> getAlertStats() async {
    final db = await dbHelper.database;
    
    final result = await db.rawQuery('''
      SELECT severity, COUNT(*) as count 
      FROM alerts 
      WHERE acknowledged = 0 
      GROUP BY severity
    ''');
    
    final stats = <String, int>{};
    for (final map in result) {
      stats[map['severity'] as String] = map['count'] as int;
    }
    
    return stats;
  }
}