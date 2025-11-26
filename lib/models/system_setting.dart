class SystemSetting {
  final int? id;
  final String settingKey;
  final String settingValue;
  final String dataType;
  final String? description;

  SystemSetting({
    this.id,
    required this.settingKey,
    required this.settingValue,
    required this.dataType,
    this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'setting_key': settingKey,
      'setting_value': settingValue,
      'data_type': dataType,
      'description': description,
    };
  }

  factory SystemSetting.fromMap(Map<String, dynamic> map) {
    return SystemSetting(
      id: map['id'],
      settingKey: map['setting_key'],
      settingValue: map['setting_value'],
      dataType: map['data_type'],
      description: map['description'],
    );
  }

  // Helper methods to convert setting value based on data type
  int get asInt => int.parse(settingValue);
  double get asDouble => double.parse(settingValue);
  bool get asBool => settingValue.toLowerCase() == 'true';
  String get asString => settingValue;

  @override
  String toString() {
    return 'SystemSetting(id: $id, settingKey: $settingKey, settingValue: $settingValue, dataType: $dataType)';
  }
}