import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/sensor_reading.dart';
import '../models/alert.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseDatabase _realtimeDb = FirebaseDatabase.instance;

  // === SENSOR DATA ===

  // Stream for real-time sensor data from Firebase
  Stream<List<SensorReading>> getSensorReadingsStream() {
    return _firestore
        .collection('sensor_readings')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => SensorReading.fromMap(doc.data()))
              .toList(),
        );
  }

  // Send sensor data to Firebase (from hardware)
  Future<void> sendSensorReadingToFirebase(SensorReading reading) async {
    await _firestore.collection('sensor_readings').add(reading.toMap());
  }

  // === ACTUATOR CONTROL ===

  // Stream for real-time actuator status
  Stream<Map<String, dynamic>> getActuatorStatusStream() {
    return _realtimeDb
        .ref()
        .child('actuators')
        .onValue
        .map(
          (event) =>
              Map<String, dynamic>.from(event.snapshot.value as Map? ?? {}),
        );
  }

  // Control actuators via Firebase (sends commands to hardware)
  Future<void> controlActuator(String actuatorName, String action) async {
    await _realtimeDb.ref().child('actuators').child(actuatorName).set({
      'action': action,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // === ALERTS ===

  // Stream for real-time alerts
  Stream<List<Alert>> getAlertsStream() {
    return _firestore
        .collection('alerts')
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Alert.fromMap(doc.data())).toList(),
        );
  }

  // Send alert to Firebase
  Future<void> sendAlertToFirebase(Alert alert) async {
    await _firestore.collection('alerts').add(alert.toMap());
  }

  // === SYSTEM SETTINGS ===

  // Get system settings from Firebase
  Future<Map<String, dynamic>> getSystemSettings() async {
    final snapshot = await _firestore
        .collection('system_settings')
        .doc('default')
        .get();
    return snapshot.data() ?? {};
  }

  // Update system settings in Firebase
  Future<void> updateSystemSettings(Map<String, dynamic> settings) async {
    await _firestore.collection('system_settings').doc('default').set(settings);
  }

  // === SYNC METHODS ===

  // Sync local SQLite data to Firebase (for backup)
  Future<void> syncLocalToFirebase(List<SensorReading> localReadings) async {
    final batch = _firestore.batch();

    for (final reading in localReadings.take(100)) {
      // Limit to avoid timeout
      final docRef = _firestore.collection('sensor_readings').doc();
      batch.set(docRef, reading.toMap());
    }

    await batch.commit();
  }

  // Check Firebase connectivity
  Future<bool> checkFirebaseConnection() async {
    try {
      await _firestore.collection('connection_test').doc('test').get();
      return true;
    } catch (e) {
      return false;
    }
  }
}
