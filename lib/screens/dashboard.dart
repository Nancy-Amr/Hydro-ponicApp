import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/hydroponic_provider.dart';
import '../models/sensor_reading.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Load data when screen starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<HydroponicProvider>(context, listen: false).loadAllData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryGreen = Colors.green.shade700;

    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        title: const Text('Hydro-Smart Dashboard'),
        automaticallyImplyLeading: false,
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.pushNamed(context, '/alertsAndNotifications');
            },
          ),
        ],
      ),
      body: Consumer<HydroponicProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${provider.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.loadAllData(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- 1. Mode Control Header ---
                _buildModeControlCard(provider, primaryGreen),
                _gap(),

                // --- 2. Real-time Sensor Data Grid ---
                Text(
                  'Real-time Sensor Data',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                _gap(height: 8),
                _buildSensorGrid(provider),
                _gap(),

                // --- 3. System Status and Controls ---
                Text(
                  'System Status & Controls',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                _gap(height: 8),
                _buildActuatorStatus(provider),
                _gap(height: 24),

                // --- 4. Critical Control Buttons (Only visible in Manual Mode) ---
                if (!provider.autoMode) _buildManualControls(provider),

                // --- 5. Navigation Buttons ---
                _buildNavigationButtons(context, primaryGreen),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _gap({double height = 16, double width = 0}) =>
      SizedBox(height: height, width: width);

  // === UPDATED METHODS USING PROVIDER DATA ===

  Widget _buildModeControlCard(
    HydroponicProvider provider,
    Color primaryGreen,
  ) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Mode',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _gap(height: 4),
                Text(
                  provider.autoMode ? 'AUTOMATIC' : 'MANUAL OVERRIDE',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: provider.autoMode
                        ? primaryGreen
                        : Colors.red.shade700,
                  ),
                ),
                Text(
                  'System Health: ${provider.systemHealth}',
                  style: TextStyle(
                    fontSize: 12,
                    color: _getHealthColor(provider.systemHealth),
                  ),
                ),
              ],
            ),
            Switch(
              value: provider.autoMode,
              onChanged: (value) {
                provider.toggleAutoMode();
              },
              activeColor: primaryGreen,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorGrid(HydroponicProvider provider) {
    final sensorData = [
      _buildSensorData(
        'Temperature',
        provider.getLatestTemperature(),
        Icons.thermostat_outlined,
        Colors.orange.shade700,
        'Â°C',
      ),
      _buildSensorData(
        'Humidity',
        provider.getLatestHumidity(),
        Icons.cloud_queue,
        Colors.blue.shade700,
        '%',
      ),
      _buildSensorData(
        'pH Level',
        provider.getLatestPH(),
        Icons.opacity,
        Colors.purple.shade700,
        'pH',
      ),
      _buildSensorData(
        'Water Level',
        provider.getLatestWaterLevel(),
        Icons.water_drop,
        Colors.lightBlue.shade700,
        '%',
      ),
      _buildSensorData(
        'Light Intensity',
        provider.getLatestLightIntensity(),
        Icons.lightbulb_outline,
        Colors.yellow.shade700,
        'lux',
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: sensorData.length,
      itemBuilder: (context, index) => _buildSensorCard(sensorData[index]),
    );
  }

  Map<String, dynamic> _buildSensorData(
    String title,
    SensorReading? reading,
    IconData icon,
    Color color,
    String unit,
  ) {
    return {
      'title': title,
      'value': reading?.value.toStringAsFixed(1) ?? '--',
      'unit': unit,
      'icon': icon,
      'color': color,
      'timestamp': reading?.timestamp,
    };
  }

  Widget _buildSensorCard(Map<String, dynamic> data) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(data['icon'], size: 30, color: data['color']),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['title'],
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                RichText(
                  text: TextSpan(
                    text: data['value'],
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: data['color'],
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text: ' ${data['unit']}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (data['timestamp'] != null)
                  Text(
                    'Updated: ${_formatTime(data['timestamp'])}',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActuatorStatus(HydroponicProvider provider) {
    return Column(
      children: [
        _buildStatusIndicator(
          title: "Water Pump",
          isActive: provider.isWaterPumpOn(),
          icon: Icons.water_drop,
        ),
        _gap(height: 12),
        _buildStatusIndicator(
          title: "Fan",
          isActive: provider.isFanOn(),
          icon: Icons.air,
        ),
        _gap(height: 12),
        _buildStatusIndicator(
          title: "Grow Lights",
          isActive: provider.isLightOn(),
          icon: Icons.lightbulb_outline,
        ),
      ],
    );
  }

  Widget _buildStatusIndicator({
    required String title,
    required bool isActive,
    required IconData icon,
  }) {
    final Color primaryGreen = Colors.green.shade700;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isActive ? Colors.white : Colors.grey.shade200,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              icon,
              size: 30,
              color: isActive ? primaryGreen : Colors.grey.shade600,
            ),
            _gap(height: 0, width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    isActive ? 'Status: RUNNING' : 'Status: IDLE',
                    style: TextStyle(
                      color: isActive ? primaryGreen : Colors.red.shade400,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            CircleAvatar(
              radius: 8,
              backgroundColor: isActive ? Colors.lightGreen : Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualControls(HydroponicProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Manual Overrides', style: Theme.of(context).textTheme.titleLarge),
        _gap(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildControlButton(
              text: provider.isWaterPumpOn() ? 'STOP PUMP' : 'START PUMP',
              color: provider.isWaterPumpOn()
                  ? Colors.red.shade600
                  : Colors.green.shade700,
              onPressed: () => provider.toggleWaterPump(),
              icon: provider.isWaterPumpOn() ? Icons.power_off : Icons.power,
            ),
            _buildControlButton(
              text: provider.isLightOn() ? 'LIGHT OFF' : 'LIGHT ON',
              color: provider.isLightOn()
                  ? Colors.grey.shade600
                  : Colors.yellow.shade700,
              onPressed: () => provider.toggleLight(),
              icon: provider.isLightOn()
                  ? Icons.lightbulb_outline
                  : Icons.lightbulb,
            ),
          ],
        ),
        _gap(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildControlButton(
              text: provider.isFanOn() ? 'FAN OFF' : 'FAN ON',
              color: provider.isFanOn()
                  ? Colors.grey.shade600
                  : Colors.blue.shade700,
              onPressed: () => provider.toggleFan(),
              icon: provider.isFanOn() ? Icons.air : Icons.air_outlined,
            ),
            _buildControlButton(
              text: 'EMERGENCY STOP',
              color: Colors.red.shade700,
              onPressed: () => provider.emergencyStop(),
              icon: Icons.emergency,
            ),
          ],
        ),
        _gap(height: 24),
      ],
    );
  }

  Widget _buildControlButton({
    required String text,
    required Color color,
    required VoidCallback onPressed,
    required IconData icon,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, color: Colors.white),
          label: Text(
            text,
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 4,
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButtons(BuildContext context, Color primaryGreen) {
    return Column(
      children: [
        _buildNavigationButton(
          context: context,
          route: '/sensor_monitoring',
          icon: Icons.sensors,
          label: 'Go to Sensor Monitoring',
          color: primaryGreen,
        ),
        _gap(height: 12),
        _buildNavigationButton(
          context: context,
          route: '/control_panel',
          icon: Icons.settings_remote,
          label: 'Go to Control Panel',
          color: Colors.lightBlue.shade400,
        ),
        _gap(height: 12),
        _buildNavigationButton(
          context: context,
          route: '/history',
          icon: Icons.history,
          label: 'View History',
          color: Colors.deepPurple,
        ),
      ],
    );
  }

  Widget _buildNavigationButton({
    required BuildContext context,
    required String route,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return SizedBox(
      width: double.infinity, // Makes all buttons same width
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.pushNamed(context, route);
        },
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  // Helper methods
  Color _getHealthColor(String health) {
    switch (health) {
      case 'CRITICAL':
        return Colors.red;
      case 'WARNING':
        return Colors.orange;
      case 'ATTENTION':
        return Colors.yellow;
      case 'HEALTHY':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatTime(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}
