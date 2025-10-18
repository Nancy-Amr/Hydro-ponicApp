import 'package:flutter/material.dart';
import 'screens/dashboard.dart';
import 'screens/splashScreen.dart';
import 'screens/signup.dart';
import 'screens/forgotpass.dart';
import 'screens/sensor_monitoring.dart';
import 'screens/settings.dart';
import 'screens/alertsAndNotifications.dart';
import 'screens/control_panel.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Define primary theme colors here for consistency
    final Color primaryGreen = Colors.green.shade700;

    return MaterialApp(
      title: 'Hydroponic App',
      // 2. Define application-wide theme using the hydroponic colors
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryGreen,
          primary: primaryGreen,
        ),
        useMaterial3: true,
      ),

      // 3. Define the initial route (the first screen seen)
      initialRoute: '/',

      // 4. Define all named routes for navigation
      routes: {
        // The root route leads to your main entry screen (LoginScreen)
        '/': (context) => const Splashscreen(),

        // Route for the Sign Up screen
        '/signup': (context) => const SignUpScreen(),

        // Route for the Forgot Password screen
        '/forgot_password': (context) => const Forgotpass(),

        // Route for the Forgot DashBoard screen
        '/dashboard': (context) => const DashboardScreen(),

        // Route for the Sensor Monitoring screen
        '/sensor_monitoring': (context) => const SensorMonitoringScreen(),

        // Route for the Settings screen
        '/settings': (context) => const SettingsScreen(),

        // Route for the Alerts and Notifications screen
        '/alertsAndNotifications': (context) => const AlertsScreen(),

        // Route for the Control Panel screen
        '/control_panel': (context) => const ControlPanelScreen(),
      },
    );
  }
}
