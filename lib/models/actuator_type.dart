class ActuatorType {
  static const String waterPump = 'water_pump';
  static const String fan = 'fan';
  static const String light = 'light';

  static const List<String> allTypes = [waterPump, fan, light];

  static String getDisplayName(String actuatorType) {
    switch (actuatorType) {
      case waterPump:
        return 'Water Pump';
      case fan:
        return 'Fan';
      case light:
        return 'Grow Light';
      default:
        return actuatorType;
    }
  }

  static String getActionOn(String actuatorType) {
    return 'TURN_ON_${actuatorType.toUpperCase()}';
  }

  static String getActionOff(String actuatorType) {
    return 'TURN_OFF_${actuatorType.toUpperCase()}';
  }
}