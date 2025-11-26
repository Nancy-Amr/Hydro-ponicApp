import 'package:flutter/foundation.dart';
import '../models/sensor_reading.dart';
import '../models/actuator_status.dart';
import '../models/alert.dart';
import '../models/system_setting.dart';
import '../database/sensor_dao.dart';
import '../database/actuator_dao.dart';
import '../database/alert_dao.dart';
import '../database/settings_dao.dart';
import '../models/actuator_log.dart';

class HydroponicProvider with ChangeNotifier {
  // DAO instances
  final SensorDao _sensorDao = SensorDao();
  final ActuatorDao _actuatorDao = ActuatorDao();
  final AlertDao _alertDao = AlertDao();
  final SettingsDao _settingsDao = SettingsDao();

  // State variables
  List<SensorReading> _sensorReadings = [];
  List<ActuatorStatus> _actuatorStatus = [];
  List<Alert> _alerts = [];
  List<SystemSetting> _settings = [];
  bool _isLoading = false;
  String _error = '';
  bool _autoMode = true;

  // Getters
  List<SensorReading> get sensorReadings => _sensorReadings;
  List<ActuatorStatus> get actuatorStatus => _actuatorStatus;
  List<Alert> get alerts => _alerts;
  List<SystemSetting> get settings => _settings;
  bool get isLoading => _isLoading;
  String get error => _error;
  bool get autoMode => _autoMode;

  // === SENSOR DATA GETTERS ===

  // Get latest readings for each sensor type
  SensorReading? getLatestTemperature() => _getLatestReading('temperature');
  SensorReading? getLatestHumidity() => _getLatestReading('humidity');
  SensorReading? getLatestPH() => _getLatestReading('ph');
  SensorReading? getLatestWaterLevel() => _getLatestReading('water_level');
  SensorReading? getLatestLightIntensity() =>
      _getLatestReading('light_intensity');

  // Get sensor history for charts
  Future<List<SensorReading>> getTemperatureHistory() =>
      _sensorDao.getChartData('temperature');
  Future<List<SensorReading>> getHumidityHistory() =>
      _sensorDao.getChartData('humidity');
  Future<List<SensorReading>> getPHHistory() => _sensorDao.getChartData('ph');
  Future<List<SensorReading>> getWaterLevelHistory() =>
      _sensorDao.getChartData('water_level');
  Future<List<SensorReading>> getLightHistory() =>
      _sensorDao.getChartData('light_intensity');

  SensorReading? _getLatestReading(String sensorType) {
    final readings = _sensorReadings
        .where((r) => r.sensorType == sensorType)
        .toList();
    if (readings.isEmpty) return null;
    readings.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return readings.first;
  }

  // === ACTUATOR GETTERS ===

  // Get actuator by name
  ActuatorStatus? getActuatorByName(String name) {
    return _actuatorStatus.firstWhere(
      (actuator) => actuator.actuatorName == name,
      orElse: () => ActuatorStatus(
        actuatorName: name,
        currentState: 'OFF',
        lastUpdated: DateTime.now(),
      ),
    );
  }

  bool isWaterPumpOn() => getActuatorByName('water_pump')?.isOn ?? false;
  bool isFanOn() => getActuatorByName('fan')?.isOn ?? false;
  bool isLightOn() => getActuatorByName('light')?.isOn ?? false;

  // === ALERT GETTERS ===

  int get unacknowledgedAlertsCount =>
      _alerts.where((alert) => !alert.acknowledged).length;
  List<Alert> get highSeverityAlerts => _alerts
      .where((alert) => alert.isHighSeverity && !alert.acknowledged)
      .toList();
  List<Alert> get mediumSeverityAlerts => _alerts
      .where((alert) => alert.isMediumSeverity && !alert.acknowledged)
      .toList();
  List<Alert> get lowSeverityAlerts => _alerts
      .where((alert) => alert.isLowSeverity && !alert.acknowledged)
      .toList();

  // === SETTINGS GETTERS ===

  double get tempMin => _getSettingAsDouble('temp_min', 18.0);
  double get tempMax => _getSettingAsDouble('temp_max', 26.0);
  double get humidityMin => _getSettingAsDouble('humidity_min', 50.0);
  double get humidityMax => _getSettingAsDouble('humidity_max', 70.0);
  double get phMin => _getSettingAsDouble('ph_min', 5.8);
  double get phMax => _getSettingAsDouble('ph_max', 6.2);
  double get waterLevelMin => _getSettingAsDouble('water_level_min', 60.0);
  double get waterLevelMax => _getSettingAsDouble('water_level_max', 90.0);
  double get lightIntensityMin =>
      _getSettingAsDouble('light_intensity_min', 25000.0);
  double get lightIntensityMax =>
      _getSettingAsDouble('light_intensity_max', 40000.0);

  double _getSettingAsDouble(String key, double defaultValue) {
    final setting = _settings.firstWhere(
      (s) => s.settingKey == key,
      orElse: () => SystemSetting(
        settingKey: key,
        settingValue: defaultValue.toString(),
        dataType: 'double',
        description: '',
      ),
    );
    return setting.asDouble;
  }

  // === LOADING METHODS ===

  // Load all data for dashboard
  Future<void> loadAllData() async {
    _setLoading(true);
    try {
      await Future.wait([
        loadSensorReadings(),
        loadActuatorStatus(),
        loadAlerts(),
        loadSettings(),
      ]);
      _error = '';

      // Check automation rules after loading data
      if (_autoMode) {
        await checkAutomationRules();
      }
    } catch (e) {
      _error = 'Failed to load data: $e';
    } finally {
      _setLoading(false);
    }
  }

  // Load sensor readings
  Future<void> loadSensorReadings() async {
    try {
      _sensorReadings = await _sensorDao.getAllSensorReadings();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load sensor readings: $e';
      notifyListeners();
    }
  }

  // Load actuator status
  Future<void> loadActuatorStatus() async {
    try {
      _actuatorStatus = await _actuatorDao.getAllActuatorStatus();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load actuator status: $e';
      notifyListeners();
    }
  }

  // Load alerts
  Future<void> loadAlerts() async {
    try {
      _alerts = await _alertDao.getAllAlerts();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load alerts: $e';
      notifyListeners();
    }
  }

  // Load settings
  Future<void> loadSettings() async {
    try {
      _settings = await _settingsDao.getAllSettings();

      // Update auto mode from settings
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

  // === SENSOR OPERATIONS ===

  // Add new sensor reading with automation check
  Future<void> addSensorReading(SensorReading reading) async {
    try {
      await _sensorDao.insertSensorReading(reading);
      await loadSensorReadings(); // Reload to get updated list

      // Check automation rules when new reading arrives
      if (_autoMode) {
        await checkAutomationRulesForSensor(reading);
      }

      _error = '';
    } catch (e) {
      _error = 'Failed to add sensor reading: $e';
      notifyListeners();
    }
  }

  // Add multiple sensor readings (for simulation)
  Future<void> addMultipleSensorReadings(List<SensorReading> readings) async {
    try {
      for (final reading in readings) {
        await _sensorDao.insertSensorReading(reading);
      }
      await loadSensorReadings();
      _error = '';
    } catch (e) {
      _error = 'Failed to add sensor readings: $e';
      notifyListeners();
    }
  }

  // Get chart data for a sensor type
  Future<List<SensorReading>> getChartData(
    String sensorType, {
    int hours = 24,
  }) async {
    return await _sensorDao.getChartData(sensorType, hours: hours);
  }

  // Clear old sensor data
  Future<void> clearOldSensorData() async {
    try {
      final deletedCount = await _sensorDao.deleteOldReadings(daysToKeep: 7);
      await loadSensorReadings();
      _error = 'Cleared $deletedCount old readings';
      notifyListeners();
    } catch (e) {
      _error = 'Failed to clear old data: $e';
      notifyListeners();
    }
  }

  // === ACTUATOR OPERATIONS ===

  // Turn actuator ON
  Future<void> turnOnActuator(
    String actuatorName, {
    String mode = 'MANUAL',
  }) async {
    try {
      await _actuatorDao.turnOnActuator(actuatorName);
      await _actuatorDao.logActuatorOn(actuatorName, mode);
      await loadActuatorStatus(); // Reload updated status
      _error = '';
    } catch (e) {
      _error = 'Failed to turn on $actuatorName: $e';
      notifyListeners();
    }
  }

  // Turn actuator OFF
  Future<void> turnOffActuator(
    String actuatorName, {
    String mode = 'MANUAL',
  }) async {
    try {
      await _actuatorDao.turnOffActuator(actuatorName);
      await _actuatorDao.logActuatorOff(actuatorName, mode);
      await loadActuatorStatus(); // Reload updated status
      _error = '';
    } catch (e) {
      _error = 'Failed to turn off $actuatorName: $e';
      notifyListeners();
    }
  }

  // Toggle actuator
  Future<void> toggleActuator(
    String actuatorName, {
    String mode = 'MANUAL',
  }) async {
    final current = getActuatorByName(actuatorName);
    if (current == null || current.isOn) {
      await turnOffActuator(actuatorName, mode: mode);
    } else {
      await turnOnActuator(actuatorName, mode: mode);
    }
  }

  // Specific actuator methods
  Future<void> turnOnWaterPump({String mode = 'MANUAL'}) =>
      turnOnActuator('water_pump', mode: mode);
  Future<void> turnOffWaterPump({String mode = 'MANUAL'}) =>
      turnOffActuator('water_pump', mode: mode);
  Future<void> toggleWaterPump({String mode = 'MANUAL'}) =>
      toggleActuator('water_pump', mode: mode);

  Future<void> turnOnFan({String mode = 'MANUAL'}) =>
      turnOnActuator('fan', mode: mode);
  Future<void> turnOffFan({String mode = 'MANUAL'}) =>
      turnOffActuator('fan', mode: mode);
  Future<void> toggleFan({String mode = 'MANUAL'}) =>
      toggleActuator('fan', mode: mode);

  Future<void> turnOnLight({String mode = 'MANUAL'}) =>
      turnOnActuator('light', mode: mode);
  Future<void> turnOffLight({String mode = 'MANUAL'}) =>
      turnOffActuator('light', mode: mode);
  Future<void> toggleLight({String mode = 'MANUAL'}) =>
      toggleActuator('light', mode: mode);

  // Get actuator logs
  Future<List<ActuatorLog>> getActuatorLogs(String actuatorName) async {
    return await _actuatorDao.getActuatorLogs(actuatorName);
  }

  Future<List<ActuatorLog>> getAllActuatorLogs() async {
    return await _actuatorDao.getAllActuatorLogs();
  }

  // === ALERT OPERATIONS ===

  // Add new alert
  Future<void> addAlert(Alert alert) async {
    try {
      await _alertDao.insertAlert(alert);
      await loadAlerts(); // Reload alerts list
      _error = '';
    } catch (e) {
      _error = 'Failed to add alert: $e';
      notifyListeners();
    }
  }

  // Create alert for sensor threshold violation
  Future<void> createSensorAlert(
    String sensorType,
    double value,
    String thresholdType,
  ) async {
    final severity = thresholdType == 'HIGH' ? 'HIGH' : 'MEDIUM';
    final message =
        '$sensorType ${thresholdType.toLowerCase()}: ${value.toStringAsFixed(1)}';

    await addAlert(
      Alert(
        alertType: '${thresholdType}_${sensorType.toUpperCase()}',
        message: message,
        severity: severity,
        sensorType: sensorType,
        value: value,
        timestamp: DateTime.now(),
      ),
    );
  }

  // Acknowledge alert
  Future<void> acknowledgeAlert(int alertId) async {
    try {
      await _alertDao.acknowledgeAlert(alertId);
      await loadAlerts(); // Reload alerts list
      _error = '';
    } catch (e) {
      _error = 'Failed to acknowledge alert: $e';
      notifyListeners();
    }
  }

  // Acknowledge all alerts
  Future<void> acknowledgeAllAlerts() async {
    try {
      await _alertDao.acknowledgeAllAlerts();
      await loadAlerts(); // Reload alerts list
      _error = '';
    } catch (e) {
      _error = 'Failed to acknowledge all alerts: $e';
      notifyListeners();
    }
  }

  // Delete alert
  Future<void> deleteAlert(int alertId) async {
    try {
      await _alertDao.deleteAlert(alertId);
      await loadAlerts();
      _error = '';
    } catch (e) {
      _error = 'Failed to delete alert: $e';
      notifyListeners();
    }
  }

  // Clear old alerts
  Future<void> clearOldAlerts() async {
    try {
      final deletedCount = await _alertDao.deleteOldAlerts(daysToKeep: 7);
      await loadAlerts();
      _error = 'Cleared $deletedCount old alerts';
      notifyListeners();
    } catch (e) {
      _error = 'Failed to clear old alerts: $e';
      notifyListeners();
    }
  }

  // === SETTINGS OPERATIONS ===

  // Update a setting
  Future<void> updateSetting(String key, String value) async {
    try {
      await _settingsDao.updateSetting(key, value);
      await loadSettings(); // Reload settings
      _error = '';
    } catch (e) {
      _error = 'Failed to update setting: $e';
      notifyListeners();
    }
  }

  // Update multiple settings
  Future<void> updateMultipleSettings(Map<String, String> settings) async {
    try {
      await _settingsDao.updateMultipleSettings(settings);
      await loadSettings(); // Reload settings
      _error = '';
    } catch (e) {
      _error = 'Failed to update settings: $e';
      notifyListeners();
    }
  }

  // Reset settings to defaults
  Future<void> resetSettingsToDefaults() async {
    try {
      await _settingsDao.resetToDefaults();
      await loadSettings(); // Reload settings
      _error = '';
    } catch (e) {
      _error = 'Failed to reset settings: $e';
      notifyListeners();
    }
  }

  // Toggle auto mode
  Future<void> toggleAutoMode() async {
    final newValue = !_autoMode;
    await updateSetting('auto_mode', newValue.toString());
    _autoMode = newValue;
    notifyListeners();
  }

  // === AUTOMATION LOGIC ===

  // Check automation rules for specific sensor reading
  Future<void> checkAutomationRulesForSensor(SensorReading reading) async {
    if (!_autoMode) return;

    switch (reading.sensorType) {
      case 'temperature':
        await _checkTemperatureRules(reading.value);
        break;
      case 'humidity':
        await _checkHumidityRules(reading.value);
        break;
      case 'ph':
        await _checkPHRules(reading.value);
        break;
      case 'water_level':
        await _checkWaterLevelRules(reading.value);
        break;
      case 'light_intensity':
        await _checkLightIntensityRules(reading.value);
        break;
    }
  }

  // Check all automation rules
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
    if (latestWaterLevel != null)
      await _checkWaterLevelRules(latestWaterLevel.value);
    if (latestLight != null) await _checkLightIntensityRules(latestLight.value);
  }

  // Temperature automation rules
  Future<void> _checkTemperatureRules(double temperature) async {
    if (temperature > tempMax) {
      // Temperature too high - turn on fan
      await turnOnFan(mode: 'AUTOMATIC');
      await createSensorAlert('temperature', temperature, 'HIGH');
    } else if (temperature < tempMin) {
      // Temperature too low - turn off fan (if no other needs)
      await turnOffFan(mode: 'AUTOMATIC');
      await createSensorAlert('temperature', temperature, 'LOW');
    }
  }

  // Humidity automation rules
  Future<void> _checkHumidityRules(double humidity) async {
    if (humidity > humidityMax) {
      await createSensorAlert('humidity', humidity, 'HIGH');
    } else if (humidity < humidityMin) {
      await createSensorAlert('humidity', humidity, 'LOW');
    }
  }

  // pH automation rules
  Future<void> _checkPHRules(double ph) async {
    if (ph > phMax) {
      await createSensorAlert('pH', ph, 'HIGH');
    } else if (ph < phMin) {
      await createSensorAlert('pH', ph, 'LOW');
    }
  }

  // Water level automation rules
  Future<void> _checkWaterLevelRules(double waterLevel) async {
    if (waterLevel < waterLevelMin) {
      await createSensorAlert('water_level', waterLevel, 'LOW');
      // In a real system, you might trigger nutrient solution refill
    } else if (waterLevel > waterLevelMax) {
      await createSensorAlert('water_level', waterLevel, 'HIGH');
    }
  }

  // Light intensity automation rules
  Future<void> _checkLightIntensityRules(double lightIntensity) async {
    final now = DateTime.now();
    final hour = now.hour;
    final isDaytime = hour >= 6 && hour < 22; // 6 AM to 10 PM

    if (isDaytime && lightIntensity < lightIntensityMin) {
      // During daytime and light is too low - turn on grow lights
      await turnOnLight(mode: 'AUTOMATIC');
      await createSensorAlert('light_intensity', lightIntensity, 'LOW');
    } else if (!isDaytime && isLightOn()) {
      // During nighttime - turn off lights
      await turnOffLight(mode: 'AUTOMATIC');
    }
  }

  // Photoperiod control (time-based light control)
  Future<void> checkPhotoperiod() async {
    if (!_autoMode) return;

    final now = DateTime.now();
    final hour = now.hour;
    final isDaytime =
        hour >= 6 && hour < 22; // 6 AM to 10 PM (16-hour photoperiod)

    if (isDaytime && !isLightOn()) {
      await turnOnLight(mode: 'AUTOMATIC');
    } else if (!isDaytime && isLightOn()) {
      await turnOffLight(mode: 'AUTOMATIC');
    }
  }

  // Emergency stop - turn off all actuators
  Future<void> emergencyStop() async {
    try {
      await Future.wait([
        turnOffWaterPump(mode: 'EMERGENCY'),
        turnOffFan(mode: 'EMERGENCY'),
        turnOffLight(mode: 'EMERGENCY'),
      ]);

      await addAlert(
        Alert(
          alertType: 'EMERGENCY_STOP',
          message: 'Emergency stop activated - all systems shut down',
          severity: 'HIGH',
          timestamp: DateTime.now(),
        ),
      );

      _error = 'Emergency stop activated';
      notifyListeners();
    } catch (e) {
      _error = 'Failed emergency stop: $e';
      notifyListeners();
    }
  }

  // === SIMULATION METHODS (for testing) ===

  // Simulate sensor data for testing
  Future<void> simulateSensorData() async {
    final now = DateTime.now();
    final simulatedReadings = [
      SensorReading(
        sensorType: 'temperature',
        value: 24.5 + (DateTime.now().millisecond % 10) / 5,
        unit: '°C',
        timestamp: now,
      ),
      SensorReading(
        sensorType: 'humidity',
        value: 65.0 + (DateTime.now().millisecond % 20) / 2,
        unit: '%',
        timestamp: now,
      ),
      SensorReading(
        sensorType: 'ph',
        value: 6.0 + (DateTime.now().millisecond % 10) / 20,
        unit: 'pH',
        timestamp: now,
      ),
      SensorReading(
        sensorType: 'water_level',
        value: 75.0 + (DateTime.now().millisecond % 30) / 3,
        unit: '%',
        timestamp: now,
      ),
      SensorReading(
        sensorType: 'light_intensity',
        value: 30000.0 + (DateTime.now().millisecond % 10000),
        unit: 'lux',
        timestamp: now,
      ),
    ];

    await addMultipleSensorReadings(simulatedReadings);
  }

  // === HELPER METHODS ===

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = '';
    notifyListeners();
  }

  // Get system health status
  String get systemHealth {
    final highAlerts = highSeverityAlerts.length;
    if (highAlerts > 0) return 'CRITICAL';
    if (mediumSeverityAlerts.length > 2) return 'WARNING';
    if (unacknowledgedAlertsCount > 5) return 'ATTENTION';
    return 'HEALTHY';
  }

  // Get system summary for dashboard
  Map<String, dynamic> get systemSummary {
    return {
      'health': systemHealth,
      'active_alerts': unacknowledgedAlertsCount,
      'sensors_online': _sensorReadings.length > 0
          ? 5
          : 0, // Assuming 5 sensors
      'actuators_active': _actuatorStatus.where((a) => a.isOn).length,
      'auto_mode': _autoMode,
    };
  }
}
