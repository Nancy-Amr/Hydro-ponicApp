class SensorType {
  static const String temperature = 'temperature';
  static const String humidity = 'humidity';
  static const String ph = 'ph';
  static const String waterLevel = 'water_level';
  static const String lightIntensity = 'light_intensity';

  static const List<String> allTypes = [
    temperature,
    humidity,
    ph,
    waterLevel,
    lightIntensity,
  ];

  static String getUnit(String sensorType) {
    switch (sensorType) {
      case temperature:
        return '°C';
      case humidity:
        return '%';
      case ph:
        return 'pH';
      case waterLevel:
        return '%';
      case lightIntensity:
        return 'lux';
      default:
        return '';
    }
  }

  static String getDisplayName(String sensorType) {
    switch (sensorType) {
      case temperature:
        return 'Temperature';
      case humidity:
        return 'Humidity';
      case ph:
        return 'pH Level';
      case waterLevel:
        return 'Water Level';
      case lightIntensity:
        return 'Light Intensity';
      default:
        return sensorType;
    }
  }
}