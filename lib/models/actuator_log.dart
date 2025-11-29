class ActuatorLog {
  final int? id;
  final String actuatorName;
  final String action;
  final String mode;
  final DateTime timestamp;

  ActuatorLog({
    this.id,
    required this.actuatorName,
    required this.action,
    required this.mode,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'actuator_name': actuatorName,
      'action': action,
      'mode': mode,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ActuatorLog.fromMap(Map<String, dynamic> map) {
    return ActuatorLog(
      id: map['id'],
      actuatorName: map['actuator_name'],
      action: map['action'],
      mode: map['mode'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }

  @override
  String toString() {
    return 'ActuatorLog(id: $id, actuatorName: $actuatorName, action: $action, mode: $mode, timestamp: $timestamp)';
  }
}
// -------------------------------------------------------------
// **The DAO methods were removed from here:**
// Future<List<ActuatorLog>> getActuatorLogs() async { ... } 
// -------------------------------------------------------------