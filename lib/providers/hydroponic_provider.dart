import 'package:flutter/foundation.dart';
import '../models/sensor_reading.dart';
import '../models/actuator_status.dart';
import '../models/alert.dart';
import '../models/system_setting.dart';
import '../database/sensor_dao.dart';
import '../database/actuator_dao.dart';
import '../database/alert_dao.dart';
import '../database/settings_dao.dart';
import 'dart:async';
import '../services/firebase_service.dart'; 
import '../models/actuator_log.dart';

class HydroponicProvider with ChangeNotifier {
  // DAO instances (SQLite)
  final SensorDao _sensorDao = SensorDao();
  final ActuatorDao _actuatorDao = ActuatorDao();
  final AlertDao _alertDao = AlertDao();
  final SettingsDao _settingsDao = SettingsDao();

  // Service instance (Firebase)
  final FirebaseService _firebaseService = FirebaseService();

  // State variables
  List<SensorReading> _sensorReadings = [];
  List<ActuatorStatus> _actuatorStatus = [];
  List<Alert> _alerts = [];
  List<SystemSetting> _settings = [];
  bool _isLoading = false;
  String _error = '';
  bool _autoMode = true;
  bool _isConnectedToFirebase = false;

  // Stream subscriptions
  StreamSubscription? _sensorStreamSubscription;
  StreamSubscription? _actuatorStreamSubscription;
  StreamSubscription? _alertStreamSubscription;

  // Getters
  List<SensorReading> get sensorReadings => _sensorReadings;
  List<ActuatorStatus> get actuatorStatus => _actuatorStatus;
  List<Alert> get alerts => _alerts;
  List<SystemSetting> get settings => _settings;
  bool get isLoading => _isLoading;
  String get error => _error;
  bool get autoMode => _autoMode;
  bool get isConnectedToFirebase => _isConnectedToFirebase;

  @override
  void dispose() {
    _sensorStreamSubscription?.cancel();
    _actuatorStreamSubscription?.cancel();
    _alertStreamSubscription?.cancel();
    super.dispose();
  }

  // === INITIALIZATION ===

  // Load all data for dashboard
  Future<void> loadAllData() async {
    _setLoading(true);
    try {
      // 1. Load local data first (fast)
      await Future.wait([
        loadSensorReadings(),
        loadActuatorStatus(),
        loadAlerts(),
        loadSettings(),
      ]);

      // 2. Check Firebase connection and setup real-time streams
      await _checkFirebaseConnection();
      if (_isConnectedToFirebase) {
        await _setupFirebaseStreams();
        await _syncLocalToFirebase();
      }

      // 3. Check automation rules
      if (_autoMode) {
        await checkAutomationRules();
      }

      _error = '';
    } catch (e) {
      _error = 'Failed to load data: $e';
      print('Error in loadAllData: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Check Firebase connection - Now uses FirebaseService
  Future<void> _checkFirebaseConnection() async {
    try {
      _isConnectedToFirebase = await _firebaseService.checkFirebaseConnection();
    } catch (e) {
      _isConnectedToFirebase = false;
      print('Firebase connection failed: $e');
    }
    notifyListeners();
  }

  // Setup Firebase real-time streams - Now uses FirebaseService streams
  Future<void> _setupFirebaseStreams() async {
    if (!_isConnectedToFirebase) return;

    try {
      // Sensor data stream from Firebase (Cloud Firestore)
      _sensorStreamSubscription = _firebaseService
          .getSensorReadingsStream()
          .listen((readings) async {
        for (final reading in readings) {
          // Immediately insert or update into SQLite
          await _sensorDao.insertSensorReading(reading);
        }
        await loadSensorReadings(); // Refresh UI from SQLite
      });

      // Actuator status stream from Firebase Realtime Database
      _actuatorStreamSubscription = _firebaseService
          .getActuatorStatusStream()
          .listen((data) async {
        if (data.isNotEmpty) {
          for (final entry in data.entries) {
            final actuatorName = entry.key;
            final actuatorData = entry.value as Map;
            // Assuming 'state' comes from hardware
            final state = actuatorData['state'] ?? 'OFF';
            await _actuatorDao.updateActuatorStatus(actuatorName, state);
          }
          await loadActuatorStatus(); // Refresh UI from SQLite
        }
      });

      // Alerts stream from Firebase (Cloud Firestore)
      _alertStreamSubscription = _firebaseService
          .getAlertsStream()
          .listen((alerts) async {
        for (final alert in alerts) {
          // Insert or update into local SQLite
          await _alertDao.insertAlert(alert);
        }
        await loadAlerts(); // Refresh UI from SQLite
      });

    } catch (e) {
      print('Failed to setup Firebase streams: $e');
    }
  }

  // Sync local data to Firebase - Uses FirebaseService's sync methods
  Future<void> _syncLocalToFirebase() async {
    if (!_isConnectedToFirebase) return;

    try {
      // Sync unsynced sensor readings
      final unsyncedReadings = await _sensorDao.getUnsyncedReadings();
      for (final reading in unsyncedReadings) {
        await _firebaseService.sendSensorReadingToFirebase(reading);
        // Mark as synced after successful send
        if (reading.id != null) {
          await _sensorDao.markAsSynced(reading.id!);
        }
      }

      // Sync unsynced alerts
      final unsyncedAlerts = await _alertDao.getUnsyncedAlerts();
      for (final alert in unsyncedAlerts) {
        await _firebaseService.sendAlertToFirebase(alert);
        // Mark as synced after successful send
        if (alert.id != null) {
          await _alertDao.markAsSynced(alert.id!);
        }
      }

      print('Firebase sync completed');
    } catch (e) {
      print('Firebase sync failed: $e');
    }
  }

  // === FIREBASE METHODS (DELEGATED) ===

  // Send sensor reading to Firebase - Now delegates to FirebaseService
  Future<void> _sendSensorReadingToFirebase(SensorReading reading) async {
    if (!_isConnectedToFirebase) return;

    try {
      await _firebaseService.sendSensorReadingToFirebase(reading);
      if (reading.id != null) {
        await _sensorDao.markAsSynced(reading.id!);
      }
    } catch (e) {
      print('Failed to send sensor reading to Firebase: $e');
    }
  }

  // Send alert to Firebase - Now delegates to FirebaseService
  Future<void> _sendAlertToFirebase(Alert alert) async {
    if (!_isConnectedToFirebase) return;

    try {
      await _firebaseService.sendAlertToFirebase(alert);
      if (alert.id != null) {
        await _alertDao.markAsSynced(alert.id!);
      }
    } catch (e) {
      print('Failed to send alert to Firebase: $e');
    }
  }

  // Control actuator via Firebase - Now delegates to FirebaseService
  Future<void> _controlActuatorViaFirebase(String actuatorName, String action) async {
    if (!_isConnectedToFirebase) return;

    try {
      await _firebaseService.controlActuator(actuatorName, action);
    } catch (e) {
      print('Failed to control actuator via Firebase: $e');
    }
  }

  // === UPDATED SENSOR OPERATIONS ===

  // Add new sensor reading with Firebase integration
  Future<void> addSensorReading(SensorReading reading) async {
    try {
      // 1. Store locally first
      final id = await _sensorDao.insertSensorReading(reading);
      final updatedReading = reading.copyWith(id: id);

      // 2. Send to Firebase if connected
      await _sendSensorReadingToFirebase(updatedReading);

      // 3. Update UI and check automation
      await loadSensorReadings();

      if (_autoMode) {
        await checkAutomationRulesForSensor(updatedReading);
      }

      _error = '';
    } catch (e) {
      _error = 'Failed to add sensor reading: $e';
      notifyListeners();
    }
  }

  // === UPDATED ACTUATOR OPERATIONS ===

  // Turn actuator ON with Firebase integration
  Future<void> turnOnActuator(String actuatorName, {String mode = 'MANUAL'}) async {
    try {
      // 1. Update local SQLite status and log
      await _actuatorDao.turnOnActuator(actuatorName);
      await _actuatorDao.logActuatorOn(actuatorName, mode);

      // 2. Send command to Firebase/hardware
      await _controlActuatorViaFirebase(actuatorName, 'ON');

      // 3. UI update will happen via the Firebase stream subscription
      _error = '';
    } catch (e) {
      _error = 'Failed to turn on $actuatorName: $e';
      notifyListeners();
    }
  }
  

  // Turn actuator OFF with Firebase integration
  Future<void> turnOffActuator(String actuatorName, {String mode = 'MANUAL'}) async {
    try {
      // 1. Update local SQLite status and log
      await _actuatorDao.turnOffActuator(actuatorName);
      await _actuatorDao.logActuatorOff(actuatorName, mode);

      // 2. Send command to Firebase/hardware
      await _controlActuatorViaFirebase(actuatorName, 'OFF');

      // 3. UI update will happen via the Firebase stream subscription
      _error = '';
    } catch (e) {
      _error = 'Failed to turn off $actuatorName: $e';
      notifyListeners();
    }
  }

  // === UPDATED ALERT OPERATIONS ===

  // Add new alert with Firebase integration
  Future<void> addAlert(Alert alert) async {
    try {
      // 1. Store locally
      final id = await _alertDao.insertAlert(alert);
      final updatedAlert = alert.copyWith(id: id);

      // 2. Send to Firebase if connected
      await _sendAlertToFirebase(updatedAlert);

      // 3. Update UI
      await loadAlerts();
      _error = '';
    } catch (e) {
      _error = 'Failed to add alert: $e';
      notifyListeners();
    }
  }
  

  // === SYNC OPERATIONS ===

  // Manual sync with Firebase
  Future<void> manualSync() async {
    _setLoading(true);
    try {
      await _checkFirebaseConnection();
      if (_isConnectedToFirebase) {
        await _syncLocalToFirebase();
        _error = 'Sync completed successfully';
      } else {
        _error = 'No Firebase connection available';
      }
    } catch (e) {
      _error = 'Sync failed: $e';
    } finally {
      _setLoading(false);
    }
  }

  // Get sync status
  Future<Map<String, dynamic>> getSyncStatus() async {
    final lastSensorSync = await _sensorDao.getLastSyncTime();
    final lastAlertSync = await _alertDao.getLastSyncTime();

    return {
      'lastSensorSync': lastSensorSync,
      'lastAlertSync': lastAlertSync,
      'isConnectedToFirebase': _isConnectedToFirebase,
    };
  }

  // === KEEP ALL YOUR EXISTING METHODS BELOW ===

  // Sensor data getters
  SensorReading? getLatestTemperature() => _getLatestReading('temperature');
  SensorReading? getLatestHumidity() => _getLatestReading('humidity');
  SensorReading? getLatestPH() => _getLatestReading('ph');
  SensorReading? getLatestWaterLevel() => _getLatestReading('water_level');
  SensorReading? getLatestLightIntensity() => _getLatestReading('light_intensity');

  Future<List<SensorReading>> getTemperatureHistory() => _sensorDao.getChartData('temperature');
  Future<List<SensorReading>> getHumidityHistory() => _sensorDao.getChartData('humidity');
  Future<List<SensorReading>> getPHHistory() => _sensorDao.getChartData('ph');
  Future<List<SensorReading>> getWaterLevelHistory() => _sensorDao.getChartData('water_level');
  Future<List<SensorReading>> getLightHistory() => _sensorDao.getChartData('light_intensity');

  SensorReading? _getLatestReading(String sensorType) {
    final readings = _sensorReadings.where((r) => r.sensorType == sensorType).toList();
    if (readings.isEmpty) return null;
    readings.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return readings.first;
  }

  // Actuator getters
  ActuatorStatus? getActuatorByName(String name) {
    try {
      return _actuatorStatus.firstWhere(
        (actuator) => actuator.actuatorName == name,
      );
    } catch (e) {
      return ActuatorStatus(
        actuatorName: name,
        currentState: 'OFF',
        lastUpdated: DateTime.now(),
      );
    }
  }
  Future<List<ActuatorLog>> getActuatorLogs() async {
  return await _actuatorDao.getActuatorLogs();
}

  bool isWaterPumpOn() => getActuatorByName('water_pump')?.isOn ?? false;
  bool isFanOn() => getActuatorByName('fan')?.isOn ?? false;
  bool isLightOn() => getActuatorByName('light')?.isOn ?? false;

  // Alert getters
  int get unacknowledgedAlertsCount => _alerts.where((alert) => !alert.acknowledged).length;
  List<Alert> get highSeverityAlerts => _alerts.where((alert) => alert.isHighSeverity && !alert.acknowledged).toList();
  List<Alert> get mediumSeverityAlerts => _alerts.where((alert) => alert.isMediumSeverity && !alert.acknowledged).toList();
  List<Alert> get lowSeverityAlerts => _alerts.where((alert) => alert.isLowSeverity && !alert.acknowledged).toList();

  // Settings getters
  double get tempMin => _getSettingAsDouble('temp_min', 18.0);
  double get tempMax => _getSettingAsDouble('temp_max', 26.0);
  double get humidityMin => _getSettingAsDouble('humidity_min', 50.0);
  double get humidityMax => _getSettingAsDouble('humidity_max', 70.0);
  double get phMin => _getSettingAsDouble('ph_min', 5.8);
  double get phMax => _getSettingAsDouble('ph_max', 6.2);
  double get waterLevelMin => _getSettingAsDouble('water_level_min', 60.0);
  double get waterLevelMax => _getSettingAsDouble('water_level_max', 90.0);
  double get lightIntensityMin => _getSettingAsDouble('light_intensity_min', 25000.0);
  double get lightIntensityMax => _getSettingAsDouble('light_intensity_max', 40000.0);

  double _getSettingAsDouble(String key, double defaultValue) {
    try {
      final setting = _settings.firstWhere((s) => s.settingKey == key);
      return setting.asDouble;
    } catch (e) {
      return defaultValue;
    }
  }

  // Loading methods
  Future<void> loadSensorReadings() async {
    try {
      _sensorReadings = await _sensorDao.getAllSensorReadings();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load sensor readings: $e';
      notifyListeners();
    }
  }

  Future<void> loadActuatorStatus() async {
    try {
      _actuatorStatus = await _actuatorDao.getAllActuatorStatus();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load actuator status: $e';
      notifyListeners();
    }
  }

  Future<void> loadAlerts() async {
    try {
      _alerts = await _alertDao.getAllAlerts();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load alerts: $e';
      notifyListeners();
    }
  }

  Future<void> loadSettings() async {
    try {
      _settings = await _settingsDao.getAllSettings();
      final autoModeSetting = _settings.firstWhere(
        (s) => s.settingKey == 'auto_mode',
        orElse: () => SystemSetting(
          settingKey: 'auto_mode',
          settingValue: 'true',
          dataType: 'bool',
          description: '',
        ),
      );
      _autoMode = autoModeSetting.asBool;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load settings: $e';
      notifyListeners();
    }
  }

  // Other actuator operations (toggle methods)
  Future<void> toggleActuator(String actuatorName, {String mode = 'MANUAL'}) async {
    final current = getActuatorByName(actuatorName);
    if (current == null || current.isOn) {
      await turnOffActuator(actuatorName, mode: mode);
    } else {
      await turnOnActuator(actuatorName, mode: mode);
    }
  }

  Future<void> turnOnWaterPump({String mode = 'MANUAL'}) => turnOnActuator('water_pump', mode: mode);
  Future<void> turnOffWaterPump({String mode = 'MANUAL'}) => turnOffActuator('water_pump', mode: mode);
  Future<void> toggleWaterPump({String mode = 'MANUAL'}) => toggleActuator('water_pump', mode: mode);

  Future<void> turnOnFan({String mode = 'MANUAL'}) => turnOnActuator('fan', mode: mode);
  Future<void> turnOffFan({String mode = 'MANUAL'}) => turnOffActuator('fan', mode: mode);
  Future<void> toggleFan({String mode = 'MANUAL'}) => toggleActuator('fan', mode: mode);

  Future<void> turnOnLight({String mode = 'MANUAL'}) => turnOnActuator('light', mode: mode);
  Future<void> turnOffLight({String mode = 'MANUAL'}) => turnOffActuator('light', mode: mode);
  Future<void> toggleLight({String mode = 'MANUAL'}) => toggleActuator('light', mode: mode);

  // Alert operations
  Future<void> createSensorAlert(String sensorType, double value, String thresholdType) async {
    final severity = thresholdType == 'HIGH' ? 'HIGH' : 'MEDIUM';
    final message = '$sensorType ${thresholdType.toLowerCase()}: ${value.toStringAsFixed(1)}';

    await addAlert(Alert(
      alertType: '${thresholdType}_${sensorType.toUpperCase()}',
      message: message,
      severity: severity,
      sensorType: sensorType,
      value: value,
      timestamp: DateTime.now(),
    ));
  }

  Future<void> acknowledgeAlert(int alertId) async {
    try {
      await _alertDao.acknowledgeAlert(alertId);
      await loadAlerts();
      _error = '';
    } catch (e) {
      _error = 'Failed to acknowledge alert: $e';
      notifyListeners();
    }
  }

  Future<void> acknowledgeAllAlerts() async {
    try {
      await _alertDao.acknowledgeAllAlerts();
      await loadAlerts();
      _error = '';
    } catch (e) {
      _error = 'Failed to acknowledge all alerts: $e';
      notifyListeners();
    }
  }

  // Settings operations
  Future<void> updateSetting(String key, String value) async {
    try {
      await _settingsDao.updateSetting(key, value);
      await loadSettings();
      _error = '';
    } catch (e) {
      _error = 'Failed to update setting: $e';
      notifyListeners();
    }
  }

  Future<void> updateMultipleSettings(Map<String, String> settings) async {
    try {
      await _settingsDao.updateMultipleSettings(settings);
      await loadSettings();
      _error = '';
    } catch (e) {
      _error = 'Failed to update settings: $e';
      notifyListeners();
    }
  }

  Future<void> resetSettingsToDefaults() async {
    try {
      await _settingsDao.resetToDefaults();
      await loadSettings();
      _error = '';
    } catch (e) {
      _error = 'Failed to reset settings: $e';
      notifyListeners();
    }
  }

  Future<void> toggleAutoMode() async {
    final newValue = !_autoMode;
    await updateSetting('auto_mode', newValue.toString());
    _autoMode = newValue;
    notifyListeners();
  }

  // Automation logic
  Future<void> checkAutomationRulesForSensor(SensorReading reading) async {
    if (!_autoMode) return;
    switch (reading.sensorType) {
      case 'temperature': await _checkTemperatureRules(reading.value); break;
      case 'humidity': await _checkHumidityRules(reading.value); break;
      case 'ph': await _checkPHRules(reading.value); break;
      case 'water_level': await _checkWaterLevelRules(reading.value); break;
      case 'light_intensity': await _checkLightIntensityRules(reading.value); break;
    }
  }

  Future<void> checkAutomationRules() async {
    if (!_autoMode) return;
    final latestTemp = getLatestTemperature();
    final latestHumidity = getLatestHumidity();
    final latestPH = getLatestPH();
    final latestWaterLevel = getLatestWaterLevel();
    final latestLight = getLatestLightIntensity();

    if (latestTemp != null) await _checkTemperatureRules(latestTemp.value);
    if (latestHumidity != null) await _checkHumidityRules(latestHumidity.value);
    if (latestPH != null) await _checkPHRules(latestPH.value);
    if (latestWaterLevel != null) await _checkWaterLevelRules(latestWaterLevel.value);
    if (latestLight != null) await _checkLightIntensityRules(latestLight.value);
  }

  Future<void> _checkTemperatureRules(double temperature) async {
    if (temperature > tempMax) {
      await turnOnFan(mode: 'AUTOMATIC');
      await createSensorAlert('temperature', temperature, 'HIGH');
    } else if (temperature < tempMin) {
      await turnOffFan(mode: 'AUTOMATIC');
      await createSensorAlert('temperature', temperature, 'LOW');
    }
  }

  Future<void> _checkHumidityRules(double humidity) async {
    if (humidity > humidityMax) {
      await createSensorAlert('humidity', humidity, 'HIGH');
    } else if (humidity < humidityMin) {
      await createSensorAlert('humidity', humidity, 'LOW');
    }
  }

  Future<void> _checkPHRules(double ph) async {
    if (ph > phMax) {
      await createSensorAlert('pH', ph, 'HIGH');
    } else if (ph < phMin) {
      await createSensorAlert('pH', ph, 'LOW');
    }
  }

  Future<void> _checkWaterLevelRules(double waterLevel) async {
    if (waterLevel < waterLevelMin) {
      await createSensorAlert('water_level', waterLevel, 'LOW');
    } else if (waterLevel > waterLevelMax) {
      await createSensorAlert('water_level', waterLevel, 'HIGH');
    }
  }

  Future<void> _checkLightIntensityRules(double lightIntensity) async {
    final now = DateTime.now();
    final hour = now.hour;
    final isDaytime = hour >= 6 && hour < 22;

    if (isDaytime && lightIntensity < lightIntensityMin) {
      await turnOnLight(mode: 'AUTOMATIC');
      await createSensorAlert('light_intensity', lightIntensity, 'LOW');
    } else if (!isDaytime && isLightOn()) {
      await turnOffLight(mode: 'AUTOMATIC');
    }
  }

  Future<void> checkPhotoperiod() async {
    if (!_autoMode) return;
    final now = DateTime.now();
    final hour = now.hour;
    final isDaytime = hour >= 6 && hour < 22;

    if (isDaytime && !isLightOn()) {
      await turnOnLight(mode: 'AUTOMATIC');
    } else if (!isDaytime && isLightOn()) {
      await turnOffLight(mode: 'AUTOMATIC');
    }
  }

  // Emergency stop
  Future<void> emergencyStop() async {
    try {
      await Future.wait([
        turnOffWaterPump(mode: 'EMERGENCY'),
        turnOffFan(mode: 'EMERGENCY'),
        turnOffLight(mode: 'EMERGENCY'),
      ]);

      await addAlert(Alert(
        alertType: 'EMERGENCY_STOP',
        message: 'Emergency stop activated - all systems shut down',
        severity: 'HIGH',
        timestamp: DateTime.now(),
      ));

      _error = 'Emergency stop activated';
      notifyListeners();
    } catch (e) {
      _error = 'Failed emergency stop: $e';
      notifyListeners();
    }
  }

  // Simulation methods
  Future<void> simulateSensorData() async {
    final now = DateTime.now();
    final simulatedReadings = [
      SensorReading(sensorType: 'temperature', value: 24.5 + (DateTime.now().millisecond % 10) / 5, unit: '°C', timestamp: now),
      SensorReading(sensorType: 'humidity', value: 65.0 + (DateTime.now().millisecond % 20) / 2, unit: '%', timestamp: now),
      SensorReading(sensorType: 'ph', value: 6.0 + (DateTime.now().millisecond % 10) / 20, unit: 'pH', timestamp: now),
      SensorReading(sensorType: 'water_level', value: 75.0 + (DateTime.now().millisecond % 30) / 3, unit: '%', timestamp: now),
      SensorReading(sensorType: 'light_intensity', value: 30000.0 + (DateTime.now().millisecond % 10000), unit: 'lux', timestamp: now),
    ];

    for (final reading in simulatedReadings) {
      await addSensorReading(reading);
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = '';
    notifyListeners();
  }

  String get systemHealth {
    final highAlerts = highSeverityAlerts.length;
    if (highAlerts > 0) return 'CRITICAL';
    if (mediumSeverityAlerts.length > 2) return 'WARNING';
    if (unacknowledgedAlertsCount > 5) return 'ATTENTION';
    return 'HEALTHY';
  }

  Map<String, dynamic> get systemSummary {
    return {
      'health': systemHealth,
      'active_alerts': unacknowledgedAlertsCount,
      'sensors_online': _sensorReadings.isNotEmpty ? 5 : 0,
      'actuators_active': _actuatorStatus.where((a) => a.isOn).length,
      'auto_mode': _autoMode,
      'firebase_connected': _isConnectedToFirebase,
    };
  }
}