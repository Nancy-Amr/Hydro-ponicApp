import '../database/database_helper.dart';
import '../database/sensor_dao.dart';
import '../database/actuator_dao.dart';
import '../database/alert_dao.dart';
import '../database/settings_dao.dart';
import 'firebase_service.dart';
import '../models/sensor_reading.dart';
import '../models/actuator_status.dart';
import '../models/alert.dart';
import '../models/system_setting.dart';

class SyncService {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final FirebaseService _firebaseService = FirebaseService();
  final SensorDao _sensorDao = SensorDao();
  final ActuatorDao _actuatorDao = ActuatorDao();
  final AlertDao _alertDao = AlertDao();
  final SettingsDao _settingsDao = SettingsDao();

  bool _isSyncing = false;

  // Sync all data between SQLite and Firebase
  Future<void> syncAllData() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final isConnected = await _firebaseService.checkFirebaseConnection();
      if (!isConnected) {
        print('No Firebase connection - skipping sync');
        return;
      }

      // Two-way sync
      await _syncLocalToFirebase(); // Push local changes to cloud
      await _syncFirebaseToLocal(); // Pull cloud changes to local

      print('Sync completed successfully');
    } catch (e) {
      print('Sync failed: $e');
    } finally {
      _isSyncing = false;
    }
  }

  // Push local changes to Firebase
  Future<void> _syncLocalToFirebase() async {
    // Sync sensor readings
    final unsyncedReadings = await _dbHelper.getUnsyncedRecords(
      'sensor_readings',
    );
    for (final reading in unsyncedReadings) {
      final sensorReading = SensorReading.fromMap(reading);
      await _firebaseService.sendSensorReadingToFirebase(sensorReading);
    }

    // Sync alerts
    final unsyncedAlerts = await _dbHelper.getUnsyncedRecords('alerts');
    for (final alert in unsyncedAlerts) {
      final alertObj = Alert.fromMap(alert);
      await _firebaseService.sendAlertToFirebase(alertObj);
    }

    // Mark as synced
    final readingIds = unsyncedReadings.map((r) => r['id'] as int).toList();
    final alertIds = unsyncedAlerts.map((a) => a['id'] as int).toList();

    if (readingIds.isNotEmpty) {
      await _dbHelper.markAsSynced('sensor_readings', readingIds);
      await _dbHelper.updateLastSyncTime('sensor_readings');
    }

    if (alertIds.isNotEmpty) {
      await _dbHelper.markAsSynced('alerts', alertIds);
      await _dbHelper.updateLastSyncTime('alerts');
    }
  }

  // Pull Firebase changes to local
  Future<void> _syncFirebaseToLocal() async {
    // Get latest sensor readings from Firebase
    final firebaseReadings = await _firebaseService
        .getSensorReadingsStream()
        .first;
    for (final reading in firebaseReadings) {
      // Check if reading already exists locally
      final existing = await _sensorDao.getLatestReading(reading.sensorType);
      if (existing == null || existing.timestamp != reading.timestamp) {
        await _sensorDao.insertSensorReading(reading);
      }
    }

    // Get latest alerts from Firebase
    final firebaseAlerts = await _firebaseService.getAlertsStream().first;
    for (final alert in firebaseAlerts) {
      // Check if alert already exists locally
      final existingAlerts = await _alertDao.getAllAlerts();
      final exists = existingAlerts.any(
        (a) => a.message == alert.message && a.timestamp == alert.timestamp,
      );

      if (!exists) {
        await _alertDao.insertAlert(alert);
      }
    }

    // Update last sync times
    await _dbHelper.updateLastSyncTime('sensor_readings');
    await _dbHelper.updateLastSyncTime('alerts');
  }

  // Manual sync trigger
  Future<void> manualSync() async {
    await syncAllData();
  }

  // Get sync status
  Future<Map<String, dynamic>> getSyncStatus() async {
    final lastSensorSync = await _dbHelper.getLastSyncTime('sensor_readings');
    final lastAlertSync = await _dbHelper.getLastSyncTime('alerts');

    return {
      'lastSensorSync': lastSensorSync,
      'lastAlertSync': lastAlertSync,
      'isSyncing': _isSyncing,
    };
  }
}
