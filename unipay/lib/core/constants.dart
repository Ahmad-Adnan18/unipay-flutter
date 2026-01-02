// lib/core/constants.dart

import 'dart:io';

// Use 10.0.2.2 for Android Emulator.
// Use 127.0.0.1 for iOS Simulator and Windows/macOS/Linux Desktop.
// Use LAN IP for Physical Devices (update manually if checking on real phone).

String get baseUrl {
  try {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000/api';
    }
    return 'http://127.0.0.1:8000/api';
  } catch (e) {
    // Fallback for web or errors
    return 'http://127.0.0.1:8000/api';
  }
}
