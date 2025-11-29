import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/hydroponic_provider.dart';
import '../models/sensor_reading.dart';
import 'package:intl/intl.dart';
import '../models/actuator_log.dart';
import '../models/alert.dart';


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // State for the collapsible Control Panel sections
  bool _isManualControlsExpanded = true;
  bool _isScheduleSetupExpanded = false;
  bool _isActionLogsExpanded = true;

  // Static state for scheduling UI (TimeOfDay is non-persistable)
  TimeOfDay? pumpTime;
  TimeOfDay? lightTime;
  String repeatOption = 'Daily';

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
    return Scaffold(
    backgroundColor: Colors.green.shade50,
    appBar: AppBar(
      // FIX: Ensure title is always visible
      title: const Text('Hydro-Smart Dashboard'), // Title kept short
      automaticallyImplyLeading: false,
      backgroundColor: Colors.green.shade700,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        // 1. Alerts Icon (Critical Navigation)
        IconButton(
          icon: const Icon(Icons.notifications),
          onPressed: () {
            Navigator.pushNamed(context, '/alertsAndNotifications');
          },
        ),
        // 2. Settings Icon (Required Navigation)
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () {
            Navigator.pushNamed(context, '/settings');
          },
        ),
        
        // 3. Overflow Menu for Less Critical Navigation
        PopupMenuButton<String>(
          onSelected: (String result) {
            Navigator.pushNamed(context, result);
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              value: '/analytics',
              child: ListTile(
                leading: Icon(Icons.show_chart),
                title: Text('Analytics & History'),
              ),
            ),
            const PopupMenuItem<String>(
              value: '/sensor_monitoring',
              child: ListTile(
                leading: Icon(Icons.sensors),
                title: Text('Sensor Details'),
              ),
            ),
          ],
          icon: const Icon(Icons.more_vert), // The three-dot icon
        ),
      ],
    ),
      body: Consumer<HydroponicProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.sensorReadings.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error.isNotEmpty) {
            return _buildErrorState(provider);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- 1. Mode Control Header (Dashboard Requirement) ---
                _buildModeControlCard(provider),
                _gap(),

                // --- 2. Real-time Sensor Data Grid (Dashboard Requirement) ---
                _buildSectionTitle(
                  'Real-time Sensor Data',
                  Colors.green.shade700,
                ),
                _gap(height: 8),
                _buildSensorGrid(provider),
                _gap(),

                // --- 3. Actuator Status Indicators (Dashboard Requirement) ---
                _buildSectionTitle('Actuator Status', Colors.green.shade700),
                _gap(height: 8),
                _buildActuatorStatus(provider),
                _gap(height: 24),

                // =========================================================
                // --- CONTROL PANEL INTEGRATION BELOW ---
                // =========================================================

                // --- 4. Manual Controls (Control Panel Requirement) ---
                _buildCollapsiblePanel(
                  title: "Manual Control Overrides",
                  isExpanded: _isManualControlsExpanded,
                  onTap: () => setState(
                    () =>
                        _isManualControlsExpanded = !_isManualControlsExpanded,
                  ),
                  content: _buildManualControls(provider),
                ),
                _gap(),

                // --- 5. Schedule Setup (Control Panel Requirement) ---
                _buildCollapsiblePanel(
                  title: "Scheduling Setup",
                  isExpanded: _isScheduleSetupExpanded,
                  onTap: () => setState(
                    () => _isScheduleSetupExpanded = !_isScheduleSetupExpanded,
                  ),
                  content: _buildScheduleSetup(context, provider),
                ),
                _gap(),

                // --- 6. Recent Actions Log (Control Panel Requirement) ---
                _buildCollapsiblePanel(
                  title: "Recent Control Actions",
                  isExpanded: _isActionLogsExpanded,
                  onTap: () => setState(
                    () => _isActionLogsExpanded = !_isActionLogsExpanded,
                  ),
                  content: _buildActionLogs(provider),
                ),
                _gap(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- UI Helper Methods ---

  Widget _gap({double height = 16, double width = 0}) =>
      SizedBox(height: height, width: width);

  Widget _buildSectionTitle(String title, Color color) {
    return Text(
      title,
      style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18),
    );
  }

  Widget _buildErrorState(HydroponicProvider provider) {
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

  Widget _buildCollapsiblePanel({
    required String title,
    required bool isExpanded,
    required VoidCallback onTap,
    required Widget content,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          ListTile(
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
            onTap: onTap,
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: content,
            ),
        ],
      ),
    );
  }

  // === DASHBOARD WIDGETS (REUSED) ===

  Widget _buildModeControlCard(HydroponicProvider provider) {
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
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                  ),
                ),
                Text(
                  'System Health: ${provider.systemSummary['health']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: _getHealthColor(provider.systemSummary['health']),
                  ),
                ),
              ],
            ),
            Switch(
              value: provider.autoMode,
              onChanged: (value) {
                provider.toggleAutoMode();
              },
              activeColor: Colors.green.shade700,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorGrid(HydroponicProvider provider) {
    // Reusing logic from the original DashboardScreen for brevity
    final sensorData = [
      _buildSensorData(
        'Temperature',
        provider.getLatestTemperature(),
        Icons.thermostat_outlined,
        Colors.orange.shade700,
        '°C',
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
      'value':
          reading?.value.toStringAsFixed(title == 'pH Level' ? 2 : 1) ?? '--',
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
    // Reusing logic from the original DashboardScreen for brevity
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
              color: isActive ? Colors.green.shade700 : Colors.grey.shade600,
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
                      color: isActive
                          ? Colors.green.shade700
                          : Colors.red.shade400,
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

  // === CONTROL PANEL WIDGETS (NEWLY INTEGRATED & CONNECTED) ===

  Widget _buildManualControls(HydroponicProvider provider) {
    if (provider.autoMode) {
      return Center(
        child: Text(
          'Manual controls disabled. Switch to MANUAL OVERRIDE above to activate.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Water Pump Control
            _buildControlButton(
              text: provider.isWaterPumpOn() ? 'STOP PUMP' : 'START PUMP',
              color: provider.isWaterPumpOn()
                  ? Colors.red.shade600
                  : Colors.green.shade700,
              onPressed: () => provider.toggleWaterPump(),
              icon: provider.isWaterPumpOn() ? Icons.power_off : Icons.power,
            ),
            // Grow Light Control
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
            // Fan Control
            _buildControlButton(
              text: provider.isFanOn() ? 'FAN OFF' : 'FAN ON',
              color: provider.isFanOn()
                  ? Colors.grey.shade600
                  : Colors.blue.shade700,
              onPressed: () => provider.toggleFan(),
              icon: provider.isFanOn() ? Icons.air : Icons.air_outlined,
            ),
            // EMERGENCY STOP
            _buildControlButton(
              text: 'EMERGENCY STOP',
              color: Colors.red.shade700,
              onPressed: () {
                provider.emergencyStop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🚨 Emergency Stop activated — All off'),
                  ),
                );
              },
              icon: Icons.emergency,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildScheduleSetup(
    BuildContext context,
    HydroponicProvider provider,
  ) {
    // NOTE: Schedule actions (setting time) would require corresponding methods
    // in HydroponicProvider to save them to SQLite/Firebase.

    return Column(
      children: [
        _buildScheduleRow(
          label: "Pump Activation Time",
          time: pumpTime,
          onPick: () => _pickTime(context, "Pump", provider),
        ),
        _buildScheduleRow(
          label: "Light Activation Time",
          time: lightTime,
          onPick: () => _pickTime(context, "Light", provider),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: repeatOption,
          items: const [
            DropdownMenuItem(value: "Daily", child: Text("Daily")),
            DropdownMenuItem(value: "Hourly", child: Text("Hourly")),
          ],
          onChanged: (value) => setState(() => repeatOption = value ?? "Daily"),
          decoration: const InputDecoration(
            labelText: "Repeat Schedule",
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          ),
        ),
      ],
    );
  }

  Future<void> _pickTime(
    BuildContext context,
    String type,
    HydroponicProvider provider,
  ) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (type == "Pump") {
          pumpTime = picked;
        } else {
          lightTime = picked;
        }
      });

      // Notify the user or log the schedule update (calls Provider method if implemented)
      provider.addAlert(
        Alert(
          alertType: 'SCHEDULE_UPDATE',
          message:
              '$type schedule set to ${picked.format(context)} ($repeatOption)',
          severity: 'LOW',
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  Widget _buildActionLogs(HydroponicProvider provider) {
    // Fetch logs from ActuatorDao via provider, then display (Log is stored in Actuator Logs table)
    return FutureBuilder<List<ActuatorLog>>(
      future: provider
          .getActuatorLogs(), // Assuming you add this getter to HydroponicProvider
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Text("Loading logs..."));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              "No recent actions recorded.",
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        final logs = snapshot.data!;

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: logs.length > 10 ? 10 : logs.length, // Show top 10 logs
          itemBuilder: (context, index) {
            final log = logs[index];
            return ListTile(
              dense: true,
              leading: Icon(
                Icons.history,
                color: logs[index].action == 'ON' ? Colors.green : Colors.red,
              ),
              title: Text(
                '${_formatLogTime(log.timestamp)} - ${log.actuatorName} ${log.action} (${log.mode})',
                style: const TextStyle(fontSize: 14),
              ),
            );
          },
        );
      },
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
          label: Text(text, style: const TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 4,
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleRow({
    required String label,
    required TimeOfDay? time,
    required VoidCallback onPick,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label)),
          TextButton.icon(
            onPressed: onPick,
            icon: const Icon(Icons.access_time),
            label: Text(time != null ? time.format(context) : "Set Time"),
          ),
        ],
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

  String _formatLogTime(DateTime timestamp) {
    return DateFormat('hh:mm:ss a').format(timestamp);
  }
}
