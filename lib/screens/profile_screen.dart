import 'package:capture_mvp/utils/app_colors.dart';
import 'package:capture_mvp/services/auth_service.dart'; // Import the AuthService
import 'package:flutter/material.dart';
import '../widgets/bottom_nav_bar.dart'; // Import the BottomNavBar

/// A simple screen displaying the user's profile view.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService(); // Initialize AuthService

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile View'), // Title displayed in the app bar
        actions: [
          IconButton(
            icon: const Icon(Icons.logout), // Logout icon
            onPressed: () async {
              try {
                await authService.signOut(); // Call the logout method
                // Navigate to the login screen after logout
                Navigator.pushReplacementNamed(context, '/login');
              } catch (e) {
                // Handle logout error
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error logging out: ${e.toString()}')),
                );
              }
            },
          ),
        ],
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
