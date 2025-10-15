import 'package:flutter/material.dart';

// Dummy data for simulation
class SensorData {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;

  SensorData(this.title, this.value, this.unit, this.icon, this.color);
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // State for the main control mode (Auto/Manual)
  bool _isAutomaticMode = true;

  // Placeholder real-time sensor data
  final List<SensorData> sensorReadings = [
    SensorData(
      "Water Temp",
      "22.5",
      "°C",
      Icons.thermostat_outlined,
      Colors.orange.shade700,
    ),
    SensorData("pH Level", "5.8", "", Icons.opacity, Colors.blue.shade700),
    SensorData(
      "EC / PPM",
      "1.4",
      "mS/cm",
      Icons.blur_on_rounded,
      Colors.teal.shade700,
    ),
    SensorData("Humidity", "65", "%", Icons.cloud_queue, Colors.grey.shade600),
  ];

  // Placeholder system status
  bool isPumpRunning = true;
  bool isLightOn = false;

  @override
  Widget build(BuildContext context) {
    final Color primaryGreen = Colors.green.shade700;
    final Color accentBlue = Colors.lightBlue.shade300;

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
],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. Mode Control Header ---
            _buildModeControlCard(primaryGreen, accentBlue),
            _gap(),

            // --- 2. Real-time Sensor Data Grid ---
            Text(
              'Real-time Sensor Data',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            _gap(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
              ),
              itemCount: sensorReadings.length,
              itemBuilder: (context, index) {
                return _buildSensorCard(sensorReadings[index]);
              },
            ),
            _gap(),

            // --- 3. System Status and Controls ---
            Text(
              'System Status & Controls',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            _gap(height: 8),
            _buildStatusIndicator(
              title: "Water Pump",
              isActive: isPumpRunning,
              icon: Icons.water_drop,
              primaryGreen: primaryGreen,
            ),
            _gap(height: 12),
            _buildStatusIndicator(
              title: "Grow Lights",
              isActive: isLightOn,
              icon: Icons.lightbulb_outline,
              primaryGreen: primaryGreen,
            ),
            _gap(height: 24),

            // --- 4. Critical Control Buttons (Only visible in Manual Mode) ---
            if (!_isAutomaticMode) ...[
              Text(
                'Manual Overrides',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              _gap(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildControlButton(
                    text: isPumpRunning ? 'STOP PUMP' : 'START PUMP',
                    color: isPumpRunning ? Colors.red.shade600 : primaryGreen,
                    onPressed: () {
                      setState(() => isPumpRunning = !isPumpRunning);
                    },
                    icon: isPumpRunning ? Icons.power_off : Icons.power,
                  ),
                  _buildControlButton(
                    text: isLightOn ? 'LIGHT OFF' : 'LIGHT ON',
                    color: isLightOn
                        ? Colors.grey.shade600
                        : Colors.yellow.shade700,
                    onPressed: () {
                      setState(() => isLightOn = !isLightOn);
                    },
                    icon: isLightOn ? Icons.lightbulb_outline : Icons.lightbulb,
                  ),
                ],
              ),
              //Adding a gap
              _gap(height: 24),
            ],
            // 5. Navigation Button to Sensor Monitoring Screen
            _gap(height: 24),
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/sensor_monitoring');
                },
                icon: const Icon(Icons.sensors),
                label: const Text('Go to Sensor Monitoring'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  backgroundColor: primaryGreen,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gap({double height = 16, double width = 0}) =>
      SizedBox(height: height, width: width);

  Widget _buildModeControlCard(Color primaryGreen, Color accentBlue) {
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
                  _isAutomaticMode ? 'AUTOMATIC' : 'MANUAL OVERRIDE',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: _isAutomaticMode
                        ? primaryGreen
                        : Colors.red.shade700,
                  ),
                ),
              ],
            ),
            Switch(
              value: _isAutomaticMode,
              onChanged: (value) {
                setState(() {
                  _isAutomaticMode = value;
                });
              },
              activeColor: primaryGreen,
              inactiveThumbColor: accentBlue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorCard(SensorData data) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(data.icon, size: 30, color: data.color),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                RichText(
                  text: TextSpan(
                    text: data.value,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: data.color,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text: ' ${data.unit}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator({
    required String title,
    required bool isActive,
    required IconData icon,
    required Color primaryGreen,
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
              color: isActive ? primaryGreen : Colors.red.shade400,
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
          onPressed: _isAutomaticMode
              ? null
              : onPressed, // Disable button if in Auto mode
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
}
