class SensorReading {
  final int? id;
  final String sensorType;
  final double value;
  final String unit;
  final DateTime timestamp;
  final bool? syncedWithFirebase;

  SensorReading({
    this.id,
    required this.sensorType,
    required this.value,
    required this.unit,
    required this.timestamp,
    this.syncedWithFirebase = false,
  });

  // Add copyWith method
  SensorReading copyWith({
    int? id,
    String? sensorType,
    double? value,
    String? unit,
    DateTime? timestamp,
    bool? syncedWithFirebase,
  }) {
    return SensorReading(
      id: id ?? this.id,
      sensorType: sensorType ?? this.sensorType,
      value: value ?? this.value,
      unit: unit ?? this.unit,
      timestamp: timestamp ?? this.timestamp,
      syncedWithFirebase: syncedWithFirebase ?? this.syncedWithFirebase,
    );
  }

  // Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sensor_type': sensorType,
      'value': value,
      'unit': unit,
      'timestamp': timestamp.toIso8601String(),
      'synced_with_firebase': syncedWithFirebase == true ? 1 : 0,
    };
  }

  // Create from Map
  factory SensorReading.fromMap(Map<String, dynamic> map) {
    return SensorReading(
      id: map['id'] as int?,
      sensorType: map['sensor_type'] as String,
      value: (map['value'] as num).toDouble(),
      unit: map['unit'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      syncedWithFirebase: (map['synced_with_firebase'] as int?) == 1,
    );
  }
}