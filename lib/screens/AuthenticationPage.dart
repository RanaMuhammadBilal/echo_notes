import 'package:echo_notes/AuthenticationServices.dart';
import 'package:echo_notes/screens/HomePage.dart';
import 'package:flutter/material.dart';

class AuthenticationPage extends StatefulWidget {
  const AuthenticationPage({super.key});

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
    bool secure = await _authService.isDeviceSecure();

    if (!secure) {
      if (mounted) {
        _showNoSecurityDialog();
      }
      return;
    }

    IconData icon = await _authService.getBestIcon();
    if (mounted) {
      setState(() => authIcon = icon);
      biometric();
    }
  }

  void _showNoSecurityDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Security Required"),
        content: const Text(
            "Please set a PIN, Pattern, or Fingerprint in your device settings to use this feature."),
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
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomePage()),
        (Route<dynamic> route) => false,
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
              icon: Icon(authIcon,
                  size: 80, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 16),
            const Text("Tap to Unlock",
                style: TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}