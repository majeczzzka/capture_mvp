import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/app_colors.dart';
import '../utils/app_shadows.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/greeting_widget.dart';

/// ProfileScreen displays the user's profile with an avatar and greeting.
class ProfileScreen extends StatelessWidget {
  final String userId; // User ID for fetching user data

  ProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Profile', style: TextStyle(color: AppColors.fonts)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 80,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.fonts),
                onPressed: () {
                  Navigator.pop(context);
                },
              )
            : null,
      ),
      body: Center(
        // Center the entire content
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            mainAxisSize:
                MainAxisSize.min, // Take up only required vertical space
            children: [
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId) // Fetch user document by ID
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (snapshot.hasError || !snapshot.hasData) {
                    return const Center(
                      child: Text(
                        'Failed to load profile',
                        style: TextStyle(color: Colors.red, fontSize: 16),
                      ),
                    );
                  }

                  // Extract user data
                  final userData =
                      snapshot.data?.data() as Map<String, dynamic>?;
                  final username =
                      userData?['username'] ?? 'User'; // Fallback to 'User'

                  // Use GreetingWidget here
                  return GreetingWidget(
                    name: username,
                    userId: userId, // Pass userId to GreetingWidget
                  );
                },
              ),

              const SizedBox(
                  height: 8), // Add space between the container and the bottom
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavBar(),
    );
  }
}
