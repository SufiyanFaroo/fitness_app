import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Local storage mein onboarding status save karne ke liye
  Future<void> completeOnboarding() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstTime', false);
  }

  // Firebase analytics log karne ke liye
  Future<void> logOnboardingEvent() async {
    await FirebaseAnalytics.instance.logEvent(
      name: 'onboarding_completed',
      parameters: {'status': 'success'},
    );
  }

  // 1. Email/Password Login
  Future<UserCredential> loginWithEmail(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();

      // Purana session clear karein taake account picker open ho
      await googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) return null;

      // --- YE HISSA ADD KAREIN ---
      // 1. Google se authentication details lein
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // 2. Firebase ke liye credential create karein
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 3. Firebase mein sign in karein
      return await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      print("Error during Google Sign-In: $e");
      return null;
    }
  }

  // 3. Facebook Login Logic
  Future<UserCredential?> signInWithFacebook() async {
    final LoginResult result = await FacebookAuth.instance.login();
    if (result.status == LoginStatus.success) {
      final OAuthCredential credential = FacebookAuthProvider.credential(
        result.accessToken!.tokenString,
      );
      return await _auth.signInWithCredential(credential);
    }
    return null;
  }

  // 4. Sync User & Check Profile Status
  Future<bool> syncUserStatus(User user) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    DocumentReference userRef = _firestore.collection('users').doc(user.uid);
    DocumentSnapshot userDoc = await userRef.get();

    bool isComplete = false;

    if (!userDoc.exists) {
      // New user setup
      await userRef.set({
        'uid': user.uid,
        'email': user.email ?? '',
        'displayName': user.displayName ?? 'Fitness User',
        'isProfileComplete': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
      isComplete = data['isProfileComplete'] ?? false;
    }

    // Local Storage persistence
    await prefs.setBool('isLoggedIn', true);
    await prefs.setBool('isProfileComplete', isComplete);
    await prefs.setString('userId', user.uid);

    return isComplete;
  }

  // 1. New User Registration (Email/Pass)
  Future<UserCredential> registerWithEmail(
    String email,
    String password,
  ) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // 2. Initial User Data Setup (Firestore + Local)
  Future<void> saveInitialUserData({
    required User user,
    required String name,
    required String phone,
  }) async {
    // Firestore setup
    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'full_name': name,
      'phone': phone,
      'email': user.email ?? '',
      'created_at': FieldValue.serverTimestamp(),
      'isProfileComplete': false,
    }, SetOptions(merge: true));

    // Local session setup
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('userId', user.uid);
    await prefs.setBool('isProfileComplete', false);
  }

  // Profile Update Logic
  Future<void> updateProfileData({
    required String uid,
    required Map<String, dynamic> profileData,
  }) async {
    // 1. Update Firestore
    await _firestore.collection('users').doc(uid).update(profileData);

    // 2. Local Storage Sync
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isProfileComplete', true);
    await prefs.setString('user_weight', profileData['weight']);
    await prefs.setString('user_height', profileData['height']);
  }

  // Final Goal Setup Logic
  Future<void> saveUserGoal({
    required String uid,
    required String goalTitle,
  }) async {
    // 1. Update Firestore: Goal aur Setup completion mark karna
    await _firestore.collection('users').doc(uid).update({
      'goal': goalTitle,
      'is_setup_complete': true,
      'last_updated': FieldValue.serverTimestamp(),
    });

    // 2. Local Storage: Session aur Setup status pakka karna
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setBool('isSetupComplete', true);
  }

  // User ka data fetch karne ke liye function
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return doc.data() as Map<String, dynamic>;
    }
    return null;
  }

  // Reset Password Logic
  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // App ki initial state check karne ke liye helper
  Future<Map<String, bool>> getInitialState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return {
      'isLoggedIn': prefs.getBool('isLoggedIn') ?? false,
      'isFirstTime': prefs.getBool('isFirstTime') ?? true,
      'isProfileComplete': prefs.getBool('isProfileComplete') ?? false,
    };
  }
}
