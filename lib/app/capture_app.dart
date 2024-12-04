// lib/app/capture_app.dart
import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/calendar_screen.dart';
import '../screens/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const CaptureApp());
}

/// The root widget of the Capture application.
class CaptureApp extends StatelessWidget {
  const CaptureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(), // Sets the default screen as HomeScreen
      routes: {
        '/home': (context) => const HomeScreen(),
        '/calendar': (context) => CalendarScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}
