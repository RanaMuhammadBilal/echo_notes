import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

class AuthenticationServices {
  final LocalAuthentication localAuthentication = LocalAuthentication();

  // Check if the device has ANY security set (PIN, Pattern, Fingerprint)
  Future<bool> isDeviceSecure() async {
    return await localAuthentication.canCheckBiometrics || await localAuthentication.isDeviceSupported();
  }

  // Determine which icon to show
  Future<IconData> getBestIcon() async {
    List<BiometricType> availableBiometrics = await localAuthentication.getAvailableBiometrics();

    if (availableBiometrics.contains(BiometricType.face) ||
        availableBiometrics.contains(BiometricType.strong)) {
      return Icons.face_rounded;
    } else if (availableBiometrics.contains(BiometricType.fingerprint)) {
      return Icons.fingerprint_rounded;
    }
    // Default to a lock icon if it's just PIN/Pattern or nothing
    return Icons.lock_open_rounded;
  }
  Future<bool> isDeviceActuallySecure() async {
    // Check if the device is capable of check biometrics OR has a PIN/Pattern/Pass set
    bool canAuthenticate = await localAuthentication.canCheckBiometrics ||
        await localAuthentication.isDeviceSupported();

    // Check if there are actually any biometrics enrolled OR if a PIN is set
    List<BiometricType> availableBiometrics = await localAuthentication.getAvailableBiometrics();

    // On some versions, if the list is empty AND canCheckBiometrics is true,
    // it means hardware exists but NO security is set.
    if (!canAuthenticate || (availableBiometrics.isEmpty)) {
      // Final fallback check: Try a "soft" authentication check
      // Some devices require this to truly know if a PIN exists
      return false;
    }

    return true;
  }

  Future<bool> authenticateLocally() async {
    bool isAuthenticated = false;
    try {
      isAuthenticated = await localAuthentication.authenticate(
        localizedReason: "Please authenticate to continue",
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Set to false to allow PIN/Pattern if fingerprint fails/missing
          useErrorDialogs: true,
        ),
      );
    } catch (ex) {
      print('Error : $ex');
    }
    return isAuthenticated;
  }
}