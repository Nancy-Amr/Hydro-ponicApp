import '../models/actuator_status.dart';
import '../models/actuator_log.dart';
import 'database_helper.dart';

class ActuatorDao {
  final DatabaseHelper dbHelper = DatabaseHelper();

  // === ACTUATOR STATUS METHODS ===

  // Get current status of all actuators
  Future<List<ActuatorStatus>> getAllActuatorStatus() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('actuator_status');
    return List.generate(maps.length, (i) => ActuatorStatus.fromMap(maps[i]));
  }

  // Get current status of a specific actuator
  Future<ActuatorStatus?> getActuatorStatus(String actuatorName) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'actuator_status',
      where: 'actuator_name = ?',
      whereArgs: [actuatorName],
    );
    if (maps.isEmpty) return null;
    return ActuatorStatus.fromMap(maps.first);
  }

  // Update actuator status (ON/OFF)
  Future<int> updateActuatorStatus(String actuatorName, String newState) async {
    final db = await dbHelper.database;
    return await db.update(
      'actuator_status',
      {
        'current_state': newState,
        'last_updated': DateTime.now().toIso8601String(),
      },
      where: 'actuator_name = ?',
      whereArgs: [actuatorName],
    );
  }

  // Turn actuator ON
  Future<int> turnOnActuator(String actuatorName) async {
    return await updateActuatorStatus(actuatorName, 'ON');
  }

  // Turn actuator OFF
  Future<int> turnOffActuator(String actuatorName) async {
    return await updateActuatorStatus(actuatorName, 'OFF');
  }

  // Toggle actuator state
  Future<int> toggleActuator(String actuatorName) async {
    final currentStatus = await getActuatorStatus(actuatorName);
    if (currentStatus == null) return 0;
    
    final newState = currentStatus.isOn ? 'OFF' : 'ON';
    return await updateActuatorStatus(actuatorName, newState);
  }

  // === ACTUATOR LOG METHODS ===

  // Log an actuator action
  Future<int> logActuatorAction(ActuatorLog log) async {
    final db = await dbHelper.database;
    return await db.insert('actuator_logs', log.toMap());
  }

  // Log actuator turn ON with mode
  Future<int> logActuatorOn(String actuatorName, String mode) async {
    return await logActuatorAction(ActuatorLog(
      actuatorName: actuatorName,
      action: 'TURNED_ON',
      mode: mode,
      timestamp: DateTime.now(),
    ));
  }

  // Log actuator turn OFF with mode
  Future<int> logActuatorOff(String actuatorName, String mode) async {
    return await logActuatorAction(ActuatorLog(
      actuatorName: actuatorName,
      action: 'TURNED_OFF',
      mode: mode,
      timestamp: DateTime.now(),
    ));
  }

  // Get all actuator logs (latest first)
  Future<List<ActuatorLog>> getAllActuatorLogs() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'actuator_logs',
      orderBy: 'timestamp DESC',
    );
    return List.generate(maps.length, (i) => ActuatorLog.fromMap(maps[i]));
  }

  // Get logs for a specific actuator
  Future<List<ActuatorLog>> getActuatorLogs(String actuatorName) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'actuator_logs',
      where: 'actuator_name = ?',
      whereArgs: [actuatorName],
      orderBy: 'timestamp DESC',
    );
    return List.generate(maps.length, (i) => ActuatorLog.fromMap(maps[i]));
  }

  // Get actuator usage statistics (last 7 days)
  Future<Map<String, int>> getActuatorUsageStats() async {
    final db = await dbHelper.database;
    final sevenDaysAgo = DateTime.now().subtract(Duration(days: 7));
    
    final result = await db.rawQuery('''
      SELECT actuator_name, COUNT(*) as usage_count 
      FROM actuator_logs 
      WHERE timestamp > ? AND action = 'TURNED_ON'
      GROUP BY actuator_name
    ''', [sevenDaysAgo.toIso8601String()]);
    
    final stats = <String, int>{};
    for (final map in result) {
      stats[map['actuator_name'] as String] = map['usage_count'] as int;
    }
    
    return stats;
  }
}