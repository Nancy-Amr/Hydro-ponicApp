import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart'; 
import '../providers/user_settings_provider.dart'; 
import '../providers/hydroponic_provider.dart';
import 'profile_edit_screen.dart';

// --- Placeholder/Mock User Model ---
// This is kept here for compilation purposes if other files need it, 
// but the provider logic now uses AppUser from auth_provider.dart.
class User {
  final String id;
  final String name;
  final String email;
  final String? profileImageUrl;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.profileImageUrl,
  });
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  
  // Thresholds state: These hold the user's edits BEFORE saving.
  double minTemp = 0;
  double maxTemp = 0;
  double minPH = 0;
  double maxPH = 0;
  
  // System State 
  bool autoMode = false;
  bool notificationsEnabled = true;

  // Controllers
  late TextEditingController minTempController;
  late TextEditingController maxTempController;
  late TextEditingController minPHController;
  late TextEditingController maxPHController;

  @override
  void initState() {
    super.initState();
    
    // Initialize controllers with empty strings/placeholders
    minTempController = TextEditingController();
    maxTempController = TextEditingController();
    minPHController = TextEditingController();
    maxPHController = TextEditingController();

    // Add a post-frame callback to safely read initial settings and populate controllers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialSettings();
    });
  }
  
  // Method to load initial data from the UserSettingsProvider
  void _loadInitialSettings() {
    // We use read here because we only want the initial value, not continuous updates
    final settingsProvider = context.read<UserSettingsProvider>();
    final hydroponicProvider = context.read<HydroponicProvider>();
    final t = settingsProvider.thresholds;
    
    // Set initial local state from provider (using safe defaults if not found)
    minTemp = t['temp_min'] ?? 18.0;
    maxTemp = t['temp_max'] ?? 28.0;
    minPH = t['ph_min'] ?? 5.5;
    maxPH = t['ph_max'] ?? 7.5;
    
    // Set initial system state from HydroponicProvider
    autoMode = hydroponicProvider.autoMode;
    // notificationsEnabled remains local state for now unless it's managed via provider

    // Populate controllers with loaded values
    minTempController.text = minTemp.toStringAsFixed(1);
    maxTempController.text = maxTemp.toStringAsFixed(1);
    minPHController.text = minPH.toStringAsFixed(1);
    maxPHController.text = maxPH.toStringAsFixed(1);
    
    setState(() {}); // Force rebuild with loaded values
  }


  @override
  void dispose() {
    minTempController.dispose();
    maxTempController.dispose();
    minPHController.dispose();
    maxPHController.dispose();
    super.dispose();
  }
  
  // --- Save Logic ---
  void _saveChanges() async {
    // Read providers using context.read for actions
    final settingsProvider = context.read<UserSettingsProvider>();
    final hydroponicProvider = context.read<HydroponicProvider>();
    
    // 1. Validate and Parse Input
    final newMinTemp = double.tryParse(minTempController.text) ?? minTemp;
    final newMaxTemp = double.tryParse(maxTempController.text) ?? maxTemp;
    final newMinPH = double.tryParse(minPHController.text) ?? minPH;
    final newMaxPH = double.tryParse(maxPHController.text) ?? maxPH;

    // 2. Prepare thresholds for saving
    final updatedThresholds = {
      'temp_min': newMinTemp,
      'temp_max': newMaxTemp,
      'ph_min': newMinPH,
      'ph_max': newMaxPH,
      // NOTE: Add all other thresholds (humidity, EC, etc.) here!
    };
    
    // 3. Save User Thresholds via UserSettingsProvider (updates Firebase)
    await settingsProvider.saveUserSettings(updatedThresholds);
    
    // 4. Update System State (Auto Mode) via HydroponicProvider
    if (hydroponicProvider.autoMode != autoMode) {
      // HydroponicProvider handles updating the system-level 'auto_mode' setting
      await hydroponicProvider.toggleAutoMode();
    }
    
    // 5. Show Success
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Settings saved! Your hydroponics system is updated."),
      ),
    );
  }

  // --- Helper Widgets (FULLY IMPLEMENTED) ---

  // 1. Section Title
  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  // 2. Settings Input Field
  Widget _buildSettingsInput(
    String label,
    TextEditingController controller,
    String unit,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 18, color: color, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            suffixText: unit,
            suffixStyle: TextStyle(color: color, fontWeight: FontWeight.bold),
            border: InputBorder.none,
            isDense: true,
            contentPadding: const EdgeInsets.only(top: 15, bottom: 5),
          ),
          onChanged: (val) {
            setState(() {});
          },
        ),
      ),
    );
  }

  // 3. Threshold Input Card
  Widget _buildThresholdCard(
      String title,
      IconData icon,
      TextEditingController minController,
      TextEditingController maxController,
      String unit,
      Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16, color: color),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                _buildSettingsInput("Min Value", minController, unit, color),
                const SizedBox(width: 16),
                _buildSettingsInput("Max Value", maxController, unit, color),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 4. Control Switch Card
  Widget _buildControlCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color activeColor,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: activeColor, size: 30),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style:
                          const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: Colors.white,
              activeTrackColor: activeColor.withOpacity(0.8),
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  // --- Dynamic User Account Widget ---
  Widget _buildDynamicUserProfile(Color primaryGreen, Color accentRed) {
    // Watch AuthProvider for user data
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.appUser; // Use AppUser model
    
    // Watch UserSettingsProvider for loading state
    final settingsProvider = context.watch<UserSettingsProvider>();

    // Handle Loading/No User State
    if (authProvider.isLoading || settingsProvider.isLoadingSettings) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(20.0),
        child: CircularProgressIndicator(color: Colors.green),
      ));
    }

    if (user == null) {
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: Icon(Icons.person_off, color: accentRed),
          title: const Text("Not Logged In"),
          subtitle: const Text("Please log in to manage settings."),
          onTap: () {
            // Navigate to the Login Screen
            Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
          },
        ),
      );
    }

    // User is logged in, display their data
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              radius: 25,
              backgroundColor: primaryGreen.withOpacity(0.7),
              child: Text(
                user.name[0].toUpperCase(), 
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(user.name,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            subtitle: Text(user.email,
                style: const TextStyle(color: Colors.grey)),
            trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
            onTap: () { Navigator.of(context).pushNamed('/profile_edit_screen');},
          ),
          Divider(color: Colors.grey.shade200, height: 1),
          TextButton.icon(
            onPressed: () async {
              await authProvider.signOut(); // Call sign out logic
              // Navigate to the splash or login screen after logout
              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
            },
            icon: Icon(Icons.logout, color: accentRed),
            label: Text("Logout",
                style: TextStyle(color: accentRed, fontWeight: FontWeight.bold)),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ],
      ),
    );
  }


  // --- Main Build Method ---

  @override
  Widget build(BuildContext context) {
    final Color primaryGreen = Colors.green.shade700;
    final Color accentRed = Colors.red.shade700; 

    // Listen to HydroponicProvider for AutoMode status
    final hydroponicProvider = context.watch<HydroponicProvider>();
    autoMode = hydroponicProvider.autoMode; // Update local state from provider

    return Scaffold(
      backgroundColor: Colors.grey.shade100, 
      appBar: AppBar(
        title: const Text('Hydroponics Settings'),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          
          // --- 1. System Mode ---
          _buildSectionTitle("System Control", Icons.settings_power, primaryGreen),
          _buildControlCard(
            title: "Automatic Mode",
            subtitle: "System automatically adjusts parameters (pH, Temp) to thresholds.",
            icon: Icons.auto_mode_outlined,
            value: autoMode,
            // Update local state here; the actual change to the system happens on save
            onChanged: (value) => setState(() => autoMode = value), 
            activeColor: primaryGreen,
          ),
          _buildControlCard(
            title: "Enable Notifications",
            subtitle: "Receive alerts when readings exceed the set thresholds.",
            icon: Icons.notifications_active_outlined,
            value: notificationsEnabled,
            onChanged: (value) => setState(() => notificationsEnabled = value),
            activeColor: primaryGreen,
          ),

          const SizedBox(height: 24),

          // --- 2. Thresholds ---
          _buildSectionTitle("Optimal Thresholds", Icons.timeline, accentRed),
          _buildThresholdCard(
            "Water Temperature",
            Icons.thermostat_outlined,
            minTempController,
            maxTempController,
            "°C",
            Colors.orange.shade700,
          ),
          _buildThresholdCard(
            "Nutrient pH Level",
            Icons.water_drop_outlined,
            minPHController,
            maxPHController,
            "pH",
            Colors.purple.shade700,
          ),
          // TODO: Add other thresholds (EC, Humidity, etc.)

          const SizedBox(height: 24),

          // --- 3. Calibration/Maintenance ---
          _buildSectionTitle("Maintenance & Sensors", Icons.build, primaryGreen),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Initiating sensor calibration process...'),
                    backgroundColor: primaryGreen,
                  ),
                );
              },
              icon: const Icon(Icons.tune_outlined),
              label: const Text("Calibrate Sensors"),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          
          // --- 4. User Profile ---
          _buildSectionTitle("User Account", Icons.person_outline, primaryGreen),
          _buildDynamicUserProfile(primaryGreen, accentRed),

          const SizedBox(height: 32),

          // --- 5. Save Changes Button (Final Action) ---
          Center(
            child: ElevatedButton(
              onPressed: _saveChanges, // Call the central save logic
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 6,
              ),
              child: const Text("Apply & Save Changes",
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}