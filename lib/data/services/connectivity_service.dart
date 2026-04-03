import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  // Internet status check karne ke liye stream
  Stream<List<ConnectivityResult>> get connectivityStream =>
      Connectivity().onConnectivityChanged;

  // Check current status (Single time)
  Future<bool> isConnected() async {
    // 🔥 Naye version mein ye List return karta hai
    final List<ConnectivityResult> result = await Connectivity()
        .checkConnectivity();

    // Agar list mein 'none' nahi hai, iska matlab internet hai
    return !result.contains(ConnectivityResult.none);
  }
}
