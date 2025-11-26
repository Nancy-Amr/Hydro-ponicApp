//import for material design widgets like Scaffold, AppBar, ListTile, FloatingActionButton, etc
import 'package:flutter/material.dart';

//stateful widget used because the screen has mutable state (autoRefresh toggles)
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
        // GridView for a more visual dashboard
        child: GridView.count(
          crossAxisCount: 2, //two cards per row
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: sensorData.entries.map((entry) {
            return Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      sensorIcons[entry.key] ?? Icons.sensors,
                      color: Colors.blue,
                      size: 40,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      entry.key,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Current Value: ${entry.value}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
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
