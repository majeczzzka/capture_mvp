import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/calendar_screen.dart';
import '../screens/profile_screen.dart';

class CaptureApp extends StatelessWidget {
  const CaptureApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
      routes: {
        '/calendar': (context) => const CalendarScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}
