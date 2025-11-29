import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/hydroponic_provider.dart';
import '../models/sensor_reading.dart';
import 'dart:async'; // Needed for Timer

class SensorMonitoringScreen extends StatefulWidget {
  const SensorMonitoringScreen({super.key});

  @override
  State<SensorMonitoringScreen> createState() => _SensorMonitoringScreenState();
}

class _SensorMonitoringScreenState extends State<SensorMonitoringScreen> {
  // Flag for UI control (from requirement #17)
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
    // Using Consumer to listen for state changes from the Provider
    return Consumer<HydroponicProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Sensor Monitoring'),
            actions: [
              IconButton(
                icon: Icon(
                  autoRefresh ? Icons.refresh : Icons.refresh_outlined,
                ),
                tooltip: 'Toggle Auto-Refresh',
                // Toggle the auto-refresh logic
                onPressed: () => _toggleAutoRefresh(!autoRefresh),
              ),
              IconButton(
                icon: const Icon(Icons.refresh_sharp),
                tooltip: 'Manual Refresh',
                onPressed: _manualRefresh,
              ),
            ],
          ),
          body: provider.isLoading && provider.sensorReadings.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: GridView.count(
                    crossAxisCount: 2, // two cards per row
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    // Map the configuration to the UI cards
                    children: sensorConfig.map((config) {
                      final reading =
                          config['getter'](provider) as SensorReading?;
                      return _buildSensorCard(
                        title: config['title'],
                        icon: config['icon'],
                        reading: reading,
                        provider: provider,
                      );
                    }).toList(),
                  ),
                ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              // SnackBar: Temporary message shown when calibration is triggered
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Calibration feature triggered.')),
              );
              // TODO: Implement actual calibration logic in Provider if required.
            },
            label: const Text('Calibrate Sensors'),
            icon: const Icon(Icons.tune),
          ),
        );
      },
    );
  }

  // Sensor Card Widget
  Widget _buildSensorCard({
    required String title,
    required IconData icon,
    required SensorReading? reading,
    required HydroponicProvider provider,
  }) {
    final value =
        reading?.value.toStringAsFixed(reading.sensorType == 'ph' ? 2 : 1) ??
        '--';
    final unit = reading?.unit ?? '';

    // Determine status color based on settings (thresholds defined in Provider)
    final Color statusColor = _getReadingColor(title, reading, provider);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor.withOpacity(0.5), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: statusColor, size: 30),
                CircleAvatar(radius: 6, backgroundColor: statusColor),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                ),
                Text(
                  value + ' $unit',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                Text(
                  reading != null
                      ? 'Last Update: ${_formatTime(reading.timestamp)}'
                      : 'No Data',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper to determine the status color based on set thresholds
  Color _getReadingColor(
    String title,
    SensorReading? reading,
    HydroponicProvider provider,
  ) {
    if (reading == null) return Colors.grey;
    final value = reading.value;

    switch (title) {
      case 'Temperature':
        if (value > provider.tempMax || value < provider.tempMin)
          return Colors.red;
        break;
      case 'Humidity':
        if (value > provider.humidityMax || value < provider.humidityMin)
          return Colors.red;
        break;
      case 'pH Level':
        if (value > provider.phMax || value < provider.phMin) return Colors.red;
        break;
      case 'Water Level':
        if (value < provider.waterLevelMin) return Colors.red;
        if (value > provider.waterLevelMax) return Colors.orange;
        break;
      case 'Light Intensity':
        if (value < provider.lightIntensityMin) return Colors.orange;
        break;
    }
    return Colors.green.shade700;
  }

  String _formatTime(DateTime timestamp) {
    // Use this format for consistency (Hours:Minutes)
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}
