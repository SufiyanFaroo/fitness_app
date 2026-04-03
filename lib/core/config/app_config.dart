import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App Configuration & Initialization
/// Handles app state and routing logic
class AppConfig {
  static final AppConfig _instance = AppConfig._internal();

  late SharedPreferences _prefs;
  late bool isFirstTime;
  late bool isLoggedIn;
  late bool isProfileComplete;
  late User? currentUser;

  AppConfig._internal();

  factory AppConfig() {
    return _instance;
  }

  /// Initialize app configuration on startup
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    isFirstTime = _prefs.getBool('isFirstTime') ?? true;
    isLoggedIn = _prefs.getBool('isLoggedIn') ?? false;
    isProfileComplete = _prefs.getBool('isProfileComplete') ?? false;
    currentUser = FirebaseAuth.instance.currentUser;
  }

  /// Set first time launch flag
  Future<void> setFirstTimeLaunch(bool value) async {
    isFirstTime = value;
    await _prefs.setBool('isFirstTime', value);
  }

  /// Set login state
  Future<void> setLoggedIn(bool value) async {
    isLoggedIn = value;
    await _prefs.setBool('isLoggedIn', value);
  }

  /// Set profile completion state
  Future<void> setProfileComplete(bool value) async {
    isProfileComplete = value;
    await _prefs.setBool('isProfileComplete', value);
  }

  /// Update current user
  void updateCurrentUser(User? user) {
    currentUser = user;
    if (user != null) {
      setLoggedIn(true);
    }
  }

  /// Get app state summary
  AppState getAppState() {
    return AppState(
      isFirstTime: isFirstTime,
      isLoggedIn: isLoggedIn,
      isProfileComplete: isProfileComplete,
      currentUser: currentUser,
    );
  }

  /// Clear all app data (for logout)
  Future<void> clearAll() async {
    isFirstTime = false;
    isLoggedIn = false;
    isProfileComplete = false;
    currentUser = null;
    await _prefs.clear();
  }
}

/// App State Model
class AppState {
  final bool isFirstTime;
  final bool isLoggedIn;
  final bool isProfileComplete;
  final User? currentUser;

  AppState({
    required this.isFirstTime,
    required this.isLoggedIn,
    required this.isProfileComplete,
    required this.currentUser,
  });

  @override
  String toString() => 
    'AppState(firstTime: $isFirstTime, loggedIn: $isLoggedIn, '
    'profileComplete: $isProfileComplete, user: ${currentUser?.email})';
}
