class Alert {
  final int? id;
  final String alertType;
  final String message;
  final String severity;
  final String? sensorType;
  final double? value;
  final DateTime timestamp;
  final bool acknowledged;
  final bool? syncedWithFirebase;

  Alert({
    this.id,
    required this.alertType,
    required this.message,
    required this.severity,
    this.sensorType,
    this.value,
    required this.timestamp,
    this.acknowledged = false,
    this.syncedWithFirebase = false,
  });

  // Add copyWith method
  Alert copyWith({
    int? id,
    String? alertType,
    String? message,
    String? severity,
    String? sensorType,
    double? value,
    DateTime? timestamp,
    bool? acknowledged,
    bool? syncedWithFirebase,
  }) {
    return Alert(
      id: id ?? this.id,
      alertType: alertType ?? this.alertType,
      message: message ?? this.message,
      severity: severity ?? this.severity,
      sensorType: sensorType ?? this.sensorType,
      value: value ?? this.value,
      timestamp: timestamp ?? this.timestamp,
      acknowledged: acknowledged ?? this.acknowledged,
      syncedWithFirebase: syncedWithFirebase ?? this.syncedWithFirebase,
    );
  }

  // Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'alert_type': alertType,
      'message': message,
      'severity': severity,
      'sensor_type': sensorType,
      'value': value,
      'timestamp': timestamp.toIso8601String(),
      'acknowledged': acknowledged ? 1 : 0,
      'synced_with_firebase': syncedWithFirebase == true ? 1 : 0,
    };
  }

  // Create from Map
  factory Alert.fromMap(Map<String, dynamic> map) {
    return Alert(
      id: map['id'] as int?,
      alertType: map['alert_type'] as String,
      message: map['message'] as String,
      severity: map['severity'] as String,
      sensorType: map['sensor_type'] as String?,
      value: map['value'] as double?,
      timestamp: DateTime.parse(map['timestamp'] as String),
      acknowledged: (map['acknowledged'] as int?) == 1,
      syncedWithFirebase: (map['synced_with_firebase'] as int?) == 1,
    );
  }

  // Helper getters
  bool get isHighSeverity => severity == 'HIGH';
  bool get isMediumSeverity => severity == 'MEDIUM';
  bool get isLowSeverity => severity == 'LOW';
}