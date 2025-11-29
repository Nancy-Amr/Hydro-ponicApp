import 'package:flutter/material.dart';
// NEW: import provider package and HydroponicProvider
import 'package:provider/provider.dart';
import '../providers/hydroponic_provider.dart';

class SensorMonitoringScreen extends StatefulWidget {
  const SensorMonitoringScreen({super.key});

  @override
  State<SensorMonitoringScreen> createState() => _SensorMonitoringScreenState();
}

class _SensorMonitoringScreenState extends State<SensorMonitoringScreen> {
  // REMOVED: hardcoded simulated sensorData map
  // Instead, we now fetch live data from HydroponicProvider

  //controls whether the refresh icon is filled or outlined
  bool autoRefresh = true;
  Timer? _refreshTimer;

  // Map sensor names to their display info (consistent with Provider getters)
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
      // In a real app, this timer would trigger a full data fetch,
      // but here we use it to trigger simulation for demonstration.
      _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
        // Trigger data update (e.g., simulating a new reading received by Firebase)
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

    // In a real app, you would call a method to force refresh the Firebase streams/data here.
    // For now, we'll just trigger one simulation run.
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
    // NEW: access HydroponicProvider
    final provider = context.watch<HydroponicProvider>();

    // NEW: build a map of sensor readings from provider
    final sensors = {
      'Temperature': provider.getLatestTemperature(),
      'Humidity': provider.getLatestHumidity(),
      'PH Level': provider.getLatestPH(),
      'Water Level': provider.getLatestWaterLevel(),
      'Light Intensity': provider.getLatestLightIntensity(),
    };

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
              // NEW: trigger reload of sensor readings when toggled
              if (autoRefresh) {
                provider.loadSensorReadings();
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
          children: sensors.entries.map((entry) {
            final reading = entry.value;
            // NEW: threshold check using provider settings
            bool isCritical = false;
            if (reading != null) {
              switch (entry.key) {
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
                case 'PH Level':
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
                      sensorIcons[entry.key] ?? Icons.sensors,
                      // NEW: icon color reflects threshold status
                      color: isCritical ? Colors.red : Colors.blue,
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
                      // UPDATED: show live value from provider instead of hardcoded map
                      reading != null
                          ? 'Current Value: ${reading.value} ${reading.unit}'
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

          // NEW: Example calibration logic — adjust thresholds dynamically
          // Here we reset thresholds to safe defaults
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

          // NEW: confirmation message after calibration
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Calibration Complete: Thresholds Reset'),
            ),
          );
        },
        label: const Text('Calibrate Sensors'),
        icon: const Icon(Icons.tune),
      ),
    );
  }
}
