import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/hydroponic_provider.dart';
import '../models/sensor_reading.dart'; // Needed for SensorReading type
import 'dart:async';

class SensorMonitoringScreen extends StatefulWidget {
  const SensorMonitoringScreen({super.key});

  @override
  State<SensorMonitoringScreen> createState() => _SensorMonitoringScreenState();
}

class _SensorMonitoringScreenState extends State<SensorMonitoringScreen> {
  // controls whether the refresh icon is filled or outlined
  bool autoRefresh = true;
  Timer? _refreshTimer;

  // Map sensor names to their display info (consistent with Provider getters)
  // This map already contains the icon data, which we will use directly in the builder.
  final List<Map<String, dynamic>> sensorConfig = [
    {
      'title': 'Temperature',
      'icon': Icons.thermostat,
      'getter': (p) => p.getLatestTemperature(),
    },
    {
      'title': 'Humidity',
      'icon': Icons.water_drop,
      'getter': (p) => p.getLatestHumidity(),
    },
    {
      'title': 'pH Level',
      'icon': Icons.science,
      'getter': (p) => p.getLatestPH(),
    },
    {
      'title': 'Water Level',
      'icon': Icons.waves,
      'getter': (p) => p.getLatestWaterLevel(),
    },
    {
      'title': 'Light Intensity',
      'icon': Icons.light_mode,
      'getter': (p) => p.getLatestLightIntensity(),
    },
  ];

  @override
  void initState() {
    super.initState();
    // Start the auto-refresh timer immediately
    _toggleAutoRefresh(true);
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  // === Data Refresh and Auto-Update Logic (from requirement #17) ===

  // Toggles the auto-refresh timer
  void _toggleAutoRefresh(bool enable) {
    if (_refreshTimer != null) {
      _refreshTimer!.cancel();
    }
    setState(() {
      autoRefresh = enable;
    });

    if (enable) {
      // Trigger simulation for demonstration
      _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
        Provider.of<HydroponicProvider>(
          context,
          listen: false,
        ).simulateSensorData();
      });
    }
  }

  // Manual refresh logic
  Future<void> _manualRefresh() async {
    // Stop the auto-refresh if it's running
    if (autoRefresh) {
      _toggleAutoRefresh(false);
    }

    // Trigger one simulation run
    await Provider.of<HydroponicProvider>(
      context,
      listen: false,
    ).simulateSensorData();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sensors manually refreshed.')),
    );
  }

  // === UI Construction ===

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HydroponicProvider>();

    // Removed: The 'sensors' map which contained the undefined 'sensorIcons'
    // We now iterate over the sensorConfig list directly.

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sensor Monitoring'),
        actions: [
        // FIX: Combine both auto and manual refresh into a single conditional button
        IconButton(
          // If autoRefresh is ON, show the filled icon, and tapping turns it OFF.
          // If autoRefresh is OFF, show a clock icon or a single refresh icon, and tapping performs manual refresh.
          icon: Icon(autoRefresh ? Icons.refresh : Icons.refresh_sharp),
          tooltip: autoRefresh ? 'Auto-Refresh ON: Tap to stop' : 'Auto-Refresh OFF: Tap to refresh once',
          onPressed: () {
            if (autoRefresh) {
              // If auto is ON, tap turns it OFF.
              _toggleAutoRefresh(false);
            } else {
              // If auto is OFF, tap performs a manual refresh.
              _manualRefresh();
            }
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
          // FIX: Iterate through sensorConfig list directly
          children: sensorConfig.map((config) {
            final reading = config['getter'](provider) as SensorReading?;
            final String title = config['title'];
            final IconData icon = config['icon'];

            // NEW: threshold check using provider settings
            bool isCritical = false;
            if (reading != null) {
              switch (title) {
                case 'Temperature':
                  isCritical =
                      reading.value < provider.tempMin ||
                      reading.value > provider.tempMax;
                  break;
                case 'Humidity':
                  isCritical =
                      reading.value < provider.humidityMin ||
                      reading.value > provider.humidityMax;
                  break;
                case 'pH Level':
                  isCritical =
                      reading.value < provider.phMin ||
                      reading.value > provider.phMax;
                  break;
                case 'Water Level':
                  isCritical =
                      reading.value < provider.waterLevelMin ||
                      reading.value > provider.waterLevelMax;
                  break;
                case 'Light Intensity':
                  isCritical =
                      reading.value < provider.lightIntensityMin ||
                      reading.value > provider.lightIntensityMax;
                  break;
              }
            }

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
                      icon, // FIX: Use icon from config instead of 'sensorIcons[entry.key]'
                      // NEW: icon color reflects threshold status
                      color: isCritical ? Colors.red : Colors.blue,
                      size: 40,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      // UPDATED: show live value from provider
                      reading != null
                          ? 'Current Value: ${reading.value.toStringAsFixed(title == 'pH Level' ? 2 : 1)} ${reading.unit}'
                          : 'No data',
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
        onPressed: () async {
          // SnackBar : Temporary message shown when calibration is triggered
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Calibration Started ...')),
          );

          // Example calibration logic — adjust thresholds dynamically
          await provider.updateMultipleSettings({
            'temp_min': '20.0',
            'temp_max': '25.0',
            'humidity_min': '55.0',
            'humidity_max': '65.0',
            'ph_min': '5.8',
            'ph_max': '6.2',
            'water_level_min': '70.0',
            'water_level_max': '90.0',
            'light_intensity_min': '25000.0',
            'light_intensity_max': '40000.0',
          });

          // confirmation message after calibration
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Calibration Complete: Thresholds Updated'),
            ),
          );
        },
        label: const Text('Calibrate Sensors'),
        icon: const Icon(Icons.tune),
      ),
    );
  }
}
