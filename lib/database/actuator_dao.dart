import '../models/actuator_status.dart';
import '../models/actuator_log.dart';
import 'database_helper.dart';
import 'package:sqflite/sqflite.dart';

class ActuatorDao {
  final DatabaseHelper dbHelper = DatabaseHelper();

  // Get all actuator status
  Future<List<ActuatorStatus>> getAllActuatorStatus() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('actuators');
    return List.generate(maps.length, (i) => ActuatorStatus.fromMap(maps[i]));
  }

  // Update actuator status
  Future<void> updateActuatorStatus(String actuatorName, String state) async {
    final db = await dbHelper.database;
    await db.insert('actuators', {
      'actuator_name': actuatorName,
      'current_state': state,
      'last_updated': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Turn on actuator
  Future<void> turnOnActuator(String actuatorName) async {
    await updateActuatorStatus(actuatorName, 'ON');
  }

  // Turn off actuator
  Future<void> turnOffActuator(String actuatorName) async {
    await updateActuatorStatus(actuatorName, 'OFF');
  }

  // Log actuator action
  Future<void> logActuatorOn(String actuatorName, String mode) async {
    await _logActuatorAction(actuatorName, 'ON', mode);
  }

  Future<void> logActuatorOff(String actuatorName, String mode) async {
    await _logActuatorAction(actuatorName, 'OFF', mode);
  }

  Future<void> _logActuatorAction(
    String actuatorName,
    String action,
    String mode,
  ) async {
    final db = await dbHelper.database;
    await db.insert('actuator_logs', {
      'actuator_name': actuatorName,
      'action': action,
      'mode': mode,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // Get actuator logs
  // Get actuator logs (for control history)
  Future<List<ActuatorLog>> getActuatorLogs() async {
    // FIX: dbHelper is correctly accessed here.
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'actuator_logs',
      orderBy: 'timestamp DESC',
    );
    // Ensure ActuatorLog model is imported in this file!
    return List.generate(maps.length, (i) => ActuatorLog.fromMap(maps[i]));
  }
}
