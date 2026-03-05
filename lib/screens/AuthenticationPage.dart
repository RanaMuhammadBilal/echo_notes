import 'package:echo_notes/AuthenticationServices.dart';
import 'package:echo_notes/screens/HomePage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class AuthenticationPage extends StatefulWidget{
  @override
  State<StatefulWidget> createState() => AuthenticationPageState();

}


class AuthenticationPageState extends State<AuthenticationPage> {
  IconData authIcon = Icons.lock_outline;
  final AuthenticationServices _authService = AuthenticationServices();

  @override
  void initState() {
    super.initState();
    _prepareAuth();
  }

  void _prepareAuth() async {
    // 1. Check if device has security
    bool secure = await _authService.isDeviceSecure();

    if (!secure) {
      if (mounted) {
        _showNoSecurityDialog();
      }
      return;
    }

    // 2. Set the correct icon
    IconData icon = await _authService.getBestIcon();
    setState(() => authIcon = icon);

    // 3. Trigger auto-auth
    biometric();
  }

  void _showNoSecurityDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Security Required"),
        content: const Text("Please set a PIN, Pattern, or Fingerprint in your device settings to use this feature."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  void biometric() async {
    bool check = await _authService.authenticateLocally();
    if (check && mounted) {
      // ✅ Use pushAndRemoveUntil to clear the entire history stack
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomePage()),
            (Route<dynamic> route) => false, // This 'false' means remove all previous routes
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: biometric,
              icon: Icon(authIcon, size: 80, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 16),
            const Text("Tap to Unlock", style: TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}