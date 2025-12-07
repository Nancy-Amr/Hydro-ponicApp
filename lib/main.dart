import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'screens/dashboard.dart';
import 'screens/splashScreen.dart';
import 'screens/signup.dart';
import 'screens/forgotpass.dart';
import 'screens/sensor_monitoring.dart';
import 'screens/settings.dart';
import 'screens/alertsAndNotifications.dart';
// import 'screens/control_panel.dart';
import 'providers/hydroponic_provider.dart';
import 'screens/history.dart';
import 'providers/auth_provider.dart';
import 'providers/user_settings_provider.dart';
import 'screens/profile_edit_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final Color primaryGreen = Colors.green.shade700;

    return MultiProvider(
      providers: [
        // 1. AuthProvider: Manages login state (User ID)
        ChangeNotifierProvider(create: (_) => AuthProvider()),

        // 2. UserSettingsProvider: Depends on AuthProvider to know whose settings to load
        ChangeNotifierProxyProvider<AuthProvider, UserSettingsProvider>(
          create: (context) => UserSettingsProvider(
            context.read<AuthProvider>(),
          ), // Initialize with AuthProvider instance
          update: (context, auth, userSettings) => UserSettingsProvider(auth),
          // Note: The UserSettingsProvider handles its own update logic internally based on auth changes
        ),

        // 3. HydroponicProvider: Depends on UserSettingsProvider for thresholds
        ChangeNotifierProxyProvider<UserSettingsProvider, HydroponicProvider>(
          create: (context) => HydroponicProvider(),
          update: (context, userSettings, hydroponicProvider) {
            // Inject the user's current thresholds into the HydroponicProvider for automation rules
            hydroponicProvider!.initializeThresholds(userSettings.thresholds);
            return hydroponicProvider;
          },
        ),
      ],
      child: MaterialApp(
        title: 'SMART Hydroponic',
        theme: ThemeData(
          snackBarTheme: SnackBarThemeData(
            backgroundColor: Colors.green.shade600,
            contentTextStyle: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            behavior: SnackBarBehavior.floating,
          ),
          colorScheme: ColorScheme.fromSeed(
            seedColor: primaryGreen,
            primary: primaryGreen,
          ),
          useMaterial3: true,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const Splashscreen(),
          '/signup': (context) => const SignUpScreen(),
          '/forgot_password': (context) => const Forgotpass(),
          '/dashboard': (context) => const DashboardScreen(),
          '/sensor_monitoring': (context) => const SensorMonitoringScreen(),
          // Use the consumer/selector logic inside the SettingsScreen
          '/settings': (context) => const SettingsScreen(),
          '/alertsAndNotifications': (context) => const AlertsScreen(),
          '/history': (context) => const HistoryScreen(),
          '/profile_edit_screen': (context) => const ProfileEditScreen(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
