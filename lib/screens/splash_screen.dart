// lib/screens/splash_screen.dart
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../app/capture_app.dart'; // Import CaptureApp

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const CaptureApp()),
        (Route<dynamic> route) => false, // Clears all previous routes
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Image.asset(
          'assets/images/splash.png', // Path to your logo image
          width: 200,
          height: 200,
        ),
      ),
    );
  }
}
