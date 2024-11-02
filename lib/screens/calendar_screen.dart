// lib/screens/calendar_view.dart

import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../widgets/bottom_nav_bar.dart'; // Import the BottomNavBar

/// A simple screen displaying a calendar view message.
class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar View'), // Title of the app bar
      ),
      body: const Center(
        child: Text('Hey, this is a calendar view'),
        // Main content message
      ),
      backgroundColor:
          AppColors.background, // Sets background color from app colors

      // Adds the BottomNavBar to the screen
      bottomNavigationBar: const BottomNavBar(),
    );
  }
}
