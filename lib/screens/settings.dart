import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  
  bool notificationsEnabled = true;
  bool autoMode = true;

  
  double minTemp = 18;
  double maxTemp = 28;
  double minPH = 5.5;
  double maxPH = 7.5;

  
  late TextEditingController minTempController;
  late TextEditingController maxTempController;
  late TextEditingController minPHController;
  late TextEditingController maxPHController;

  
  String userName = "Rana Mohamed";
  String userEmail = "rana@example.com";

  @override
  void initState() {
    super.initState();
    minTempController = TextEditingController(text: minTemp.toString());
    maxTempController = TextEditingController(text: maxTemp.toString());
    minPHController = TextEditingController(text: minPH.toString());
    maxPHController = TextEditingController(text: maxPH.toString());
  }

  @override
  void dispose() {
    minTempController.dispose();
    maxTempController.dispose();
    minPHController.dispose();
    maxPHController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryGreen = Colors.green.shade700;
    final Color accentBlue = Colors.lightBlue.shade300;

    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          
          _buildSectionTitle("Sensor Thresholds", primaryGreen),
          _buildThresholdRow(
            "Temperature (°C)",
            minTempController,
            maxTempController,
            (min, max) {
              setState(() {
                minTemp = min;
                maxTemp = max;
              });
            },
          ),
          _buildThresholdRow(
            "pH Level",
            minPHController,
            maxPHController,
            (min, max) {
              setState(() {
                minPH = min;
                maxPH = max;
              });
            },
          ),

          const SizedBox(height: 24),

          
          _buildSectionTitle("Notifications", primaryGreen),
          _buildSwitchTile(
            title: "Enable Notifications",
            subtitle: "Receive alerts for abnormal readings",
            value: notificationsEnabled,
            onChanged: (value) => setState(() => notificationsEnabled = value),
            activeColor: primaryGreen,
            inactiveColor: accentBlue,
          ),

          const SizedBox(height: 24),

          
          _buildSectionTitle("System Mode", primaryGreen),
          _buildSwitchTile(
            title: "Automatic Mode",
            subtitle: "Switch between manual and automatic control",
            value: autoMode,
            onChanged: (value) => setState(() => autoMode = value),
            activeColor: primaryGreen,
            inactiveColor: accentBlue,
          ),

          const SizedBox(height: 24),

          
          _buildSectionTitle("System Calibration", primaryGreen),
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('System calibration started...')),
              );
            },
            icon: const Icon(Icons.tune),
            label: const Text("Calibrate Sensors"),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          const SizedBox(height: 24),

         
          _buildSectionTitle("User Profile", primaryGreen),
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 30,
                        backgroundImage: AssetImage('./images/profile.jpg'),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(userName,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          Text(userEmail,
                              style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Divider(color: Colors.grey.shade300),
                  TextButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Logged out successfully')),
                      );
                    },
                    icon: const Icon(Icons.logout, color: Colors.red),
                    label: const Text("Logout",
                        style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          
          Center(
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Changes saved successfully!")),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("Save Changes",
                  style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  
  Widget _buildSectionTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }

  Widget _buildThresholdRow(
    String label,
    TextEditingController minController,
    TextEditingController maxController,
    Function(double, double) onChanged,
  ) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: minController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Min",
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    onChanged: (val) => onChanged(
                        double.tryParse(minController.text) ?? 0,
                        double.tryParse(maxController.text) ?? 0),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: maxController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Max",
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    onChanged: (val) => onChanged(
                        double.tryParse(minController.text) ?? 0,
                        double.tryParse(maxController.text) ?? 0),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color activeColor,
    required Color inactiveColor,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 12),
      child: SwitchListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => value ? activeColor : inactiveColor,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => value
              ? activeColor.withValues(alpha: 0.4)
              : inactiveColor.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}
