import 'package:flutter/foundation.dart';
import '../services/firebase_service.dart';
import 'auth_provider.dart';

// Keys used to save/fetch settings
const List<String> thresholdKeys = [
  'temp_min', 'temp_max', 'ph_min', 'ph_max', 'humidity_min', 'humidity_max', 
  'water_level_min', 'water_level_max', 'light_intensity_min', 'light_intensity_max'
];

class UserSettingsProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final AuthProvider _authProvider;
  
  Map<String, double> _thresholds = {};
  bool _isLoadingSettings = false;

  Map<String, double> get thresholds => _thresholds;
  bool get isLoadingSettings => _isLoadingSettings;
  String? get currentUserId => _authProvider.firebaseUser?.uid;

  UserSettingsProvider(this._authProvider) {
    _authProvider.addListener(_handleAuthChange);
    _handleAuthChange();
  }

  @override
  void dispose() {
    _authProvider.removeListener(_handleAuthChange);
    super.dispose();
  }

  void _handleAuthChange() {
    // Only reload settings if the user state has changed (logged in/out)
    if (_authProvider.isLoggedIn && _thresholds.isEmpty) {
      loadUserSettings();
    } else if (!_authProvider.isLoggedIn) {
      // Clear settings on logout
      _thresholds = {};
      notifyListeners();
    }
  }

  Future<void> loadUserSettings() async {
    if (currentUserId == null) return;

    _isLoadingSettings = true;
    notifyListeners();
    
    try {
      final data = await _firebaseService.getUserSettings(currentUserId!);
      
      // Safely convert Firestore map data to Map<String, double>
      if (data.isNotEmpty) {
        _thresholds = data.map<String, double>(
          // Ensure value is treated as 'num' before converting to double
          (key, value) => MapEntry(key, (value as num).toDouble()),
        );
      } else {
        _thresholds = _getDefaultThresholds();
      }
    } catch (e) {
      debugPrint('Error loading user settings: $e');
      _thresholds = _getDefaultThresholds();
    } finally {
      _isLoadingSettings = false;
      notifyListeners();
    }
  }

  Future<void> saveUserSettings(Map<String, double> updatedSettings) async {
    if (currentUserId == null) return;
    
    _isLoadingSettings = true;
    notifyListeners();
    
    try {
      _thresholds.addAll(updatedSettings);

      final dataToSave = updatedSettings.map<String, dynamic>(
        (key, value) => MapEntry(key, value),
      );
      
      await _firebaseService.updateUserSettings(currentUserId!, dataToSave);
      
      // Notify HydroponicProvider to re-run automation with new thresholds
      // This is implicit via ProxyProvider in main.dart, but we ensure listeners are notified.
    } catch (e) {
      debugPrint('Error saving user settings: $e');
    } finally {
      _isLoadingSettings = false;
      notifyListeners();
    }
  }
  
  // Default values for new users or missing settings
  Map<String, double> _getDefaultThresholds() {
    return {
      'temp_min': 18.0, 'temp_max': 26.0, 
      'ph_min': 5.8, 'ph_max': 6.2, 
      'humidity_min': 50.0, 'humidity_max': 70.0,
      'water_level_min': 60.0, 'water_level_max': 90.0,
      'light_intensity_min': 25000.0, 'light_intensity_max': 40000.0,
    };
  }
}