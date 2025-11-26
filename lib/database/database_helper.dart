import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'hydroponic.db');
    return await openDatabase(path, version: 1, onCreate: _createTables);
  }

  Future<void> _createTables(Database db, int version) async {
    // Sensor readings table - stores all sensor data
    await db.execute('''
      CREATE TABLE sensor_readings(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sensor_type TEXT NOT NULL,
        value REAL NOT NULL,
        unit TEXT NOT NULL,
        timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Actuator status table - current state of actuators
    await db.execute('''
      CREATE TABLE actuator_status(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        actuator_name TEXT UNIQUE NOT NULL,
        current_state TEXT NOT NULL,
        last_updated DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Actuator logs table - history of actuator actions
    await db.execute('''
      CREATE TABLE actuator_logs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        actuator_name TEXT NOT NULL,
        action TEXT NOT NULL,
        mode TEXT NOT NULL,
        timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Alerts table - system warnings and notifications
    await db.execute('''
      CREATE TABLE alerts(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        alert_type TEXT NOT NULL,
        message TEXT NOT NULL,
        severity TEXT NOT NULL,
        sensor_type TEXT,
        value REAL,
        timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
        acknowledged INTEGER DEFAULT 0
      )
    ''');

    // System settings table - user preferences and thresholds
    await db.execute('''
      CREATE TABLE system_settings(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        setting_key TEXT UNIQUE NOT NULL,
        setting_value TEXT NOT NULL,
        data_type TEXT NOT NULL,
        description TEXT
      )
    ''');

    // Insert default actuator status
    await _insertDefaultData(db);
  }

  Future<void> _insertDefaultData(Database db) async {
    // Default actuator states
    final actuators = [
      {'name': 'water_pump', 'state': 'OFF'},
      {'name': 'fan', 'state': 'OFF'},
      {'name': 'light', 'state': 'OFF'},
    ];

    for (var actuator in actuators) {
      await db.insert('actuator_status', {
        'actuator_name': actuator['name'],
        'current_state': actuator['state'],
      });
    }

    // Default system settings
    final settings = [
      {
        'key': 'temp_min',
        'value': '18.0',
        'type': 'double',
        'desc': 'Minimum temperature threshold (°C)',
      },
      {
        'key': 'temp_max',
        'value': '26.0',
        'type': 'double',
        'desc': 'Maximum temperature threshold (°C)',
      },
      {
        'key': 'humidity_min',
        'value': '50.0',
        'type': 'double',
        'desc': 'Minimum humidity threshold (%)',
      },
      {
        'key': 'humidity_max',
        'value': '70.0',
        'type': 'double',
        'desc': 'Maximum humidity threshold (%)',
      },
      {
        'key': 'ph_min',
        'value': '5.8',
        'type': 'double',
        'desc': 'Minimum pH level threshold',
      },
      {
        'key': 'ph_max',
        'value': '6.2',
        'type': 'double',
        'desc': 'Maximum pH level threshold',
      },
      {
        'key': 'water_level_min',
        'value': '60.0',
        'type': 'double',
        'desc': 'Minimum water level threshold (%)',
      },
      {
        'key': 'water_level_max',
        'value': '90.0',
        'type': 'double',
        'desc': 'Minimum water level threshold (%)',
      },
      {
        'key': 'light_intensity_min',
        'value': '25000.0',
        'type': 'double',
        'desc': 'Minimum light intensity threshold (lux)',
      },
      {
        'key': 'light_intensity_max',
        'value': '40000.0',
        'type': 'double',
        'desc': 'Minimum light intensity threshold (lux)',
      },

      {
        'key': 'auto_mode',
        'value': 'true',
        'type': 'bool',
        'desc': 'Enable automatic control mode',
      },
    ];

    for (var setting in settings) {
      await db.insert('system_settings', {
        'setting_key': setting['key'],
        'setting_value': setting['value'],
        'data_type': setting['type'],
        'description': setting['desc'],
      });
    }
  }
}