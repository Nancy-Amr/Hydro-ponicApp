class ActuatorStatus {
  final int? id;
  final String actuatorName;
  final String currentState;
  final DateTime lastUpdated;

  ActuatorStatus({
    this.id,
    required this.actuatorName,
    required this.currentState,
    required this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'actuator_name': actuatorName,
      'current_state': currentState,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }

  factory ActuatorStatus.fromMap(Map<String, dynamic> map) {
    return ActuatorStatus(
      id: map['id'],
      actuatorName: map['actuator_name'],
      currentState: map['current_state'],
      lastUpdated: DateTime.parse(map['last_updated']),
    );
  }

  bool get isOn => currentState == 'ON';
  bool get isOff => currentState == 'OFF';

  @override
  String toString() {
    return 'ActuatorStatus(id: $id, actuatorName: $actuatorName, currentState: $currentState, lastUpdated: $lastUpdated)';
  }
}