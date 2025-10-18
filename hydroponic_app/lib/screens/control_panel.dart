import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ControlPanelScreen extends StatefulWidget {
  const ControlPanelScreen({super.key});

  @override
  State<ControlPanelScreen> createState() => _ControlPanelScreenState();
}

class _ControlPanelScreenState extends State<ControlPanelScreen> {
  bool pumpOn = false;
  bool lightOn = false;
  bool fanOn = false;

  TimeOfDay? pumpTime;
  TimeOfDay? lightTime;
  String repeatOption = 'Daily';

  final List<String> logs = [];

  void _addLog(String action) {
    final timestamp = DateFormat('hh:mm:ss a').format(DateTime.now());
    setState(() {
      logs.insert(0, "$timestamp - $action");
    });
  }

  Future<void> _pickTime(BuildContext context, String type) async {
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
      _addLog("$type schedule set to ${picked.format(context)}");
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryGreen = Colors.green.shade700;
    final Color accentBlue = Colors.lightBlue.shade300;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Control Panel'),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.green.shade50,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle("Manual Controls", primaryGreen),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildControlButton(
                label: pumpOn ? "Turn Off Pump" : "Turn On Pump",
                icon: Icons.water_drop,
                active: pumpOn,
                color: accentBlue,
                onPressed: () {
                  setState(() => pumpOn = !pumpOn);
                  _addLog(pumpOn ? "Pump turned ON" : "Pump turned OFF");
                },
              ),
              _buildControlButton(
                label: lightOn ? "Turn Off Light" : "Turn On Light",
                icon: Icons.lightbulb,
                active: lightOn,
                color: Colors.amber.shade400,
                onPressed: () {
                  setState(() => lightOn = !lightOn);
                  _addLog(lightOn ? "Light turned ON" : "Light turned OFF");
                },
              ),
              _buildControlButton(
  label: fanOn ? "Deactivate Fan" : "Activate Fan",
  icon: Icons.air,
  active: fanOn,
  color: Colors.cyan.shade400,
  onPressed: () {
    setState(() => fanOn = !fanOn);
    _addLog(fanOn ? "Fan activated" : "Fan deactivated");
  },
),

            ],
          ),

          const SizedBox(height: 24),

          _buildSectionTitle("Schedule Setup", primaryGreen),
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildScheduleRow(
                    label: "Pump Activation Time",
                    time: pumpTime,
                    onPick: () => _pickTime(context, "Pump"),
                  ),
                  _buildScheduleRow(
                    label: "Light Activation Time",
                    time: lightTime,
                    onPick: () => _pickTime(context, "Light"),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: repeatOption,
                    items: const [
                      DropdownMenuItem(value: "Daily", child: Text("Daily")),
                      DropdownMenuItem(value: "Hourly", child: Text("Hourly")),
                    ],
                    onChanged: (value) =>
                        setState(() => repeatOption = value ?? "Daily"),
                    decoration: const InputDecoration(
                      labelText: "Repeat Schedule",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          _buildSectionTitle("Emergency", primaryGreen),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                pumpOn = false;
                lightOn = false;
                fanOn = false;
              });
              _addLog("🚨 EMERGENCY STOP - All systems off");
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Emergency Stop activated — All off')),
              );
            },
            icon: const Icon(Icons.warning, color: Colors.white),
            label: const Text("Emergency Stop",
                style: TextStyle(color: Colors.white, fontSize: 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              padding:
                  const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          const SizedBox(height: 24),

          _buildSectionTitle("Recent Actions", primaryGreen),
          Card(
            elevation: 3,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: logs.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      "No recent actions.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: logs.length,
                    itemBuilder: (context, index) => ListTile(
                      leading: const Icon(Icons.history, color: Colors.green),
                      title: Text(logs[index]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required String label,
    required IconData icon,
    required bool active,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
      label: Text(label, style: const TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: active ? color : Colors.grey.shade400,
        minimumSize: const Size(150, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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
            label: Text(
              time != null ? time.format(context) : "Set Time",
            ),
          ),
        ],
      ),
    );
  }
}
