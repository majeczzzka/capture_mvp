import 'package:capture_mvp/utils/app_colors.dart';
import 'package:flutter/material.dart';
import '../widgets/bottom_nav_bar.dart'; // Import the BottomNavBar

/// A simple screen displaying the user's profile view.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile View'), // Title displayed in the app bar
      ),
      body: const Center(
        child: Text('Hey, this is a profile view'), // Main content message
      ),
      backgroundColor: AppColors.background, // Sets background color from theme

      // Adds the BottomNavBar to the screen
      bottomNavigationBar: const BottomNavBar(),
    );
  }
}
