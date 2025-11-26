import '../models/sensor_reading.dart';
import 'database_helper.dart';

class SensorDao {
  final DatabaseHelper dbHelper = DatabaseHelper();

  // Insert a new sensor reading
  Future<int> insertSensorReading(SensorReading reading) async {
    final db = await dbHelper.database;
    return await db.insert('sensor_readings', reading.toMap());
  }

  // Get all sensor readings (latest first)
  Future<List<SensorReading>> getAllSensorReadings() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sensor_readings',
      orderBy: 'timestamp DESC',
    );
    return List.generate(maps.length, (i) => SensorReading.fromMap(maps[i]));
  }

  // Get readings by sensor type (latest first)
  Future<List<SensorReading>> getSensorReadingsByType(String sensorType) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sensor_readings',
      where: 'sensor_type = ?',
      whereArgs: [sensorType],
      orderBy: 'timestamp DESC',
    );
    return List.generate(maps.length, (i) => SensorReading.fromMap(maps[i]));
  }

  // Get latest reading for a specific sensor type
  Future<SensorReading?> getLatestReading(String sensorType) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sensor_readings',
      where: 'sensor_type = ?',
      whereArgs: [sensorType],
      orderBy: 'timestamp DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return SensorReading.fromMap(maps.first);
  }

  // Get readings for charts (last 24 hours, ordered by time)
  Future<List<SensorReading>> getChartData(String sensorType, {int hours = 24}) async {
    final db = await dbHelper.database;
    final startTime = DateTime.now().subtract(Duration(hours: hours));
    
    final List<Map<String, dynamic>> maps = await db.query(
      'sensor_readings',
      where: 'sensor_type = ? AND timestamp > ?',
      whereArgs: [sensorType, startTime.toIso8601String()],
      orderBy: 'timestamp ASC',
    );
    return List.generate(maps.length, (i) => SensorReading.fromMap(maps[i]));
  }

  // Delete old readings (keep last 30 days for performance)
  Future<int> deleteOldReadings({int daysToKeep = 30}) async {
    final db = await dbHelper.database;
    final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
    
    return await db.delete(
      'sensor_readings',
      where: 'timestamp < ?',
      whereArgs: [cutoffDate.toIso8601String()],
    );
  }

  // Get readings count for statistics - FIXED (now has import)
   Future<int> getReadingsCount() async {
    final db = await dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM sensor_readings');
    return result.first['count'] as int? ?? 0;
  }
}