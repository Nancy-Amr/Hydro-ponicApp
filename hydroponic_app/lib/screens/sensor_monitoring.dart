//import for material design widgets like Scaffold,AppBar, ListTile,FloatingActionButton,etc
import 'package:flutter/material.dart';

//stateful widget used because the screen has mutable state (autoRefresh toggles )
class SensorMonitoringScreen extends StatefulWidget {
  const SensorMonitoringScreen({super.key});

  @override
  State<SensorMonitoringScreen> createState() => _SensorMonitoringScreenState();
}

class _SensorMonitoringScreenState extends State<SensorMonitoringScreen> {
  // Simulated sensor data (replace with Firebase later)
  final Map<String, dynamic> sensorData = {
    'Temperature': '25 °C',
    'Humidity': '60%',
    'PH Level': '5.5',
    'Water Level': 'Normal',
    'Light Intensity': 'High',
  };

  //controls whether the refresh icon is filled or outlined
  bool autoRefresh = true;

  //Map sensor names to icons
  final Map<String, IconData> sensorIcons = {
    'Temperature': Icons.thermostat,
    'Humidity': Icons.water_drop,
    'PH Level': Icons.science,
    'Water Level': Icons.waves,
    'Light Intensity': Icons.light_mode,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sensor Monitoring'),
        actions: [
          IconButton(
            icon: Icon(autoRefresh ? Icons.refresh : Icons.refresh_outlined),
            tooltip: 'Toggle Auto-Refresh',
            onPressed: () {
              setState(() {
                autoRefresh = !autoRefresh;
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        // ListView Scorallable list of sensor cards
        child: ListView(
          children: sensorData.entries.map((entry) {
            return Card(
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 8),
              //ListTile displays each sensor's name , value , and status icon
              child: ListTile(
                leading: Icon(
                  sensorIcons[entry.key] ?? Icons.sensors,
                  color: Colors.blue,
                  size: 30,
                ),
                title: Text(entry.key),
                subtitle: Text('Current Value: ${entry.value}'),
                trailing: const Icon(Icons.check_circle, color: Colors.green),
              ),
            );
          }).toList(),
        ),
      ),
      //A button with both icon and label
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // SnackBar : Temporary message shown when calibration is triggered
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Calibration Started ...')),
          );
        },
        label: const Text('Calibrate Sensors'),
        icon: const Icon(Icons.tune),
      ),
    );
  }
}
