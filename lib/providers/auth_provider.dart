import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart'; // To fetch profile data

// User model to represent the logged-in user's profile data
class AppUser {
  final String uid;
  final String name;
  final String email;
  final String? phoneNumber; // Added new field
  final String? gender; // Added new field
  final int? age;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    this.phoneNumber,
    this.gender,
    this.age,
  });
}

class AuthProvider with ChangeNotifier {
  User? _firebaseUser = AuthService.currentUser();
  AppUser? _appUser;
  bool _isLoading = false;
  String? _authError;

  final FirebaseService _firebaseService =
      FirebaseService(); // Service instance

  User? get firebaseUser => _firebaseUser;
  AppUser? get appUser => _appUser;
  bool get isLoading => _isLoading;
  String? get authError => _authError;
  bool get isLoggedIn => _firebaseUser != null;
  String? get currentUserId => _firebaseUser?.uid; // Expose UID

  // Constructor: Attach listener for auth state changes
  AuthProvider() {
    FirebaseAuth.instance.authStateChanges().listen(_onAuthStateChanged);
  }

  // Handle Firebase state changes and load custom profile data (Class-level listener)
  void _onAuthStateChanged(User? user) async {
    _firebaseUser = user;
    _authError = null;
    _setLoading(true);

    if (user != null) {
      // Fetch custom AppUser profile data from Firestore
      final profileData = await _firebaseService.getUserProfile(user.uid);

      _appUser = AppUser(
        uid: user.uid,
        email: user.email!,
        // Prefer Firestore data, fall back to Auth metadata
        name:
            profileData['name'] ??
            user.displayName ??
            user.email!.split('@').first,
        phoneNumber: profileData['phoneNumber'], // Load from Firestore
        gender: profileData['gender'], // Load from Firestore
        age: profileData['age'],
      );
    } else {
      _appUser = null;
    }
    _setLoading(false);
  }

  // Sign In (remains similar)
  Future<void> signIn(String email, String password) async {
    _setLoading(true);
    try {
      await AuthService.signInWithEmail(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      _authError = e.message;
    } catch (e) {
      _authError = 'An unknown error occurred.';
    }
    _setLoading(false);
  }

  // Sign Out (remains similar)
  Future<void> signOut() async {
    await AuthService.signOut();
  }

  // Update the user's display name and custom profile fields in Firestore
  Future<void> updateProfile({
    required String name,
    String? phoneNumber,
    String? gender,
    num? age,
  }) async {
    if (_firebaseUser == null) return;

    _setLoading(true);
    try {
      // 1. Update Firebase Auth Display Name
      if (name != _firebaseUser!.displayName) {
        await _firebaseUser!.updateDisplayName(name);
      }

      // 2. Update Firestore Profile Document
      final profileData = <String, dynamic>{
        'name': name,
        'phoneNumber': phoneNumber,
        'gender': gender,
        'age': age,
      };

      // Assumes updateUserProfile is now defined in FirebaseService
      await _firebaseService.updateUserProfile(_firebaseUser!.uid, profileData);

      // 3. UI Refresh: No manual call to _onAuthStateChanged needed here.
      // The call to updateDisplayName/updateUserProfile will trigger the
      // class-level _onAuthStateChanged listener automatically, refreshing _appUser.
    } on Exception catch (e) {
      // Catch authentication errors or database errors
      _authError = 'Failed to update profile: $e';
      debugPrint('Update profile error: $e');
      // Re-throw or handle error in UI layer
      throw e;
    } finally {
      // Ensure loading state is reset regardless of success/failure
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
