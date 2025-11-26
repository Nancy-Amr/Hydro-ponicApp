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
    return await openDatabase(
      path,
      version: 2, // Increment version for new table
      onCreate: _createTables,
      onUpgrade: _upgradeDatabase,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    // Sensor readings table - stores all sensor data
    await db.execute('''
      CREATE TABLE sensor_readings(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sensor_type TEXT NOT NULL,
        value REAL NOT NULL,
        unit TEXT NOT NULL,
        timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
        synced_with_firebase INTEGER DEFAULT 0
      )
    ''');

    // Actuator status table - current state of actuators
    await db.execute('''
      CREATE TABLE actuator_status(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        actuator_name TEXT UNIQUE NOT NULL,
        current_state TEXT NOT NULL,
        last_updated DATETIME DEFAULT CURRENT_TIMESTAMP,
        synced_with_firebase INTEGER DEFAULT 0
      )
    ''');

    // Actuator logs table - history of actuator actions
    await db.execute('''
      CREATE TABLE actuator_logs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        actuator_name TEXT NOT NULL,
        action TEXT NOT NULL,
        mode TEXT NOT NULL,
        timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
        synced_with_firebase INTEGER DEFAULT 0
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
        acknowledged INTEGER DEFAULT 0,
        synced_with_firebase INTEGER DEFAULT 0
      )
    ''');

    // System settings table - user preferences and thresholds
    await db.execute('''
      CREATE TABLE system_settings(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        setting_key TEXT UNIQUE NOT NULL,
        setting_value TEXT NOT NULL,
        data_type TEXT NOT NULL,
        description TEXT,
        synced_with_firebase INTEGER DEFAULT 0
      )
    ''');

    // Sync status table - track last sync time
    await db.execute('''
      CREATE TABLE sync_status(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name TEXT UNIQUE NOT NULL,
        last_sync_time DATETIME
      )
    ''');

    // Insert default data
    await insertDefaultData(db);
  }

  Future<void> _upgradeDatabase(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      // Add sync columns to existing tables
      await db.execute(
        'ALTER TABLE sensor_readings ADD COLUMN synced_with_firebase INTEGER DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE actuator_status ADD COLUMN synced_with_firebase INTEGER DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE actuator_logs ADD COLUMN synced_with_firebase INTEGER DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE alerts ADD COLUMN synced_with_firebase INTEGER DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE system_settings ADD COLUMN synced_with_firebase INTEGER DEFAULT 0',
      );
      await db.execute('''
        CREATE TABLE sync_status(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          table_name TEXT UNIQUE NOT NULL,
          last_sync_time DATETIME
        )
      ''');
    }
  }

  // ... rest of your existing insertDefaultData method remains the same ...
  Future<void> insertDefaultData(Database db) async {
    // Your existing default data insertion code here
    // (keep the same as before)
  }

  // === SYNC METHODS ===

  // Mark records as synced
  Future<void> markAsSynced(String tableName, List<int> ids) async {
    final db = await database;
    final placeholders = List.filled(ids.length, '?').join(',');

    await db.rawUpdate('''
      UPDATE $tableName 
      SET synced_with_firebase = 1 
      WHERE id IN ($placeholders)
    ''', ids);
  }

  // Get unsynced records
  Future<List<Map<String, dynamic>>> getUnsyncedRecords(
    String tableName,
  ) async {
    final db = await database;
    return await db.query(
      tableName,
      where: 'synced_with_firebase = ?',
      whereArgs: [0],
    );
  }

  // Update last sync time
  Future<void> updateLastSyncTime(String tableName) async {
    final db = await database;
    await db.insert('sync_status', {
      'table_name': tableName,
      'last_sync_time': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Get last sync time
  Future<DateTime?> getLastSyncTime(String tableName) async {
    final db = await database;
    final result = await db.query(
      'sync_status',
      where: 'table_name = ?',
      whereArgs: [tableName],
    );

    if (result.isEmpty) return null;
    return DateTime.parse(result.first['last_sync_time'] as String);
  }
}
