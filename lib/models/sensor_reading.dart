class SensorReading {
  final int? id;
  final String sensorType;
  final double value;
  final String unit;
  final DateTime timestamp;

  SensorReading({
    this.id,
    required this.sensorType,
    required this.value,
    required this.unit,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sensor_type': sensorType,
      'value': value,
      'unit': unit,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory SensorReading.fromMap(Map<String, dynamic> map) {
    return SensorReading(
      id: map['id'],
      sensorType: map['sensor_type'],
      value: map['value'].toDouble(),
      unit: map['unit'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }

  @override
  String toString() {
    return 'SensorReading(id: $id, sensorType: $sensorType, value: $value, unit: $unit, timestamp: $timestamp)';
  }
}