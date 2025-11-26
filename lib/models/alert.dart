class Alert {
  final int? id;
  final String alertType;
  final String message;
  final String severity;
  final String? sensorType;
  final double? value;
  final DateTime timestamp;
  final bool acknowledged;

  Alert({
    this.id,
    required this.alertType,
    required this.message,
    required this.severity,
    this.sensorType,
    this.value,
    required this.timestamp,
    this.acknowledged = false,
  });

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
    };
  }

  factory Alert.fromMap(Map<String, dynamic> map) {
    return Alert(
      id: map['id'],
      alertType: map['alert_type'],
      message: map['message'],
      severity: map['severity'],
      sensorType: map['sensor_type'],
      value: map['value']?.toDouble(),
      timestamp: DateTime.parse(map['timestamp']),
      acknowledged: map['acknowledged'] == 1,
    );
  }

  bool get isHighSeverity => severity == 'HIGH';
  bool get isMediumSeverity => severity == 'MEDIUM';
  bool get isLowSeverity => severity == 'LOW';

  @override
  String toString() {
    return 'Alert(id: $id, alertType: $alertType, message: $message, severity: $severity, acknowledged: $acknowledged)';
  }
}