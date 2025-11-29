import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'screens/dashboard.dart';
import 'screens/splashScreen.dart';
import 'screens/signup.dart';
import 'screens/forgotpass.dart';
import 'screens/sensor_monitoring.dart';
import 'screens/settings.dart';
// import 'screens/history.dart';
import 'screens/alertsAndNotifications.dart';
import 'screens/control_panel.dart';
import 'providers/hydroponic_provider.dart';

// If you used `flutterfire configure` and have firebase_options.dart, uncomment below:
// import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Option A: If you have firebase_options.dart (created by flutterfire CLI), use:
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Option B: If you added google-services.json (Android) and GoogleService-Info.plist (iOS),
  // this default call will read them automatically:
  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final Color primaryGreen = Colors.green.shade700;

    return MultiProvider(
      providers: [
        // Provider will be created when first accessed (lazy loading)
        ChangeNotifierProvider(
          create: (context) => HydroponicProvider(),
          lazy: true,
        ),
      ],
      child: MaterialApp(
        title: 'SMART Hydroponic',
        theme: ThemeData(
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
          '/dashboard': (context) => Provider<HydroponicProvider>(
            create: (context) => HydroponicProvider()..loadAllData(),
            child: const DashboardScreen(),
          ),
          '/sensor_monitoring': (context) => const SensorMonitoringScreen(),
          '/settings': (context) => const SettingsScreen(),
          '/alertsAndNotifications': (context) => const AlertsScreen(),
          '/control_panel': (context) => const ControlPanelScreen(),
          // '/history': (context) => const HistoryScreen(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}