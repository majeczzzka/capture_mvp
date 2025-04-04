import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/app_colors.dart';
import '../widgets/nav/bottom_nav_bar.dart';
import '../widgets/home/greeting_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'trash_screen.dart';

/// ProfileScreen displays the user's profile with an avatar and greeting.
class ProfileScreen extends StatelessWidget {
  final String userId; // User ID for fetching user data

  const ProfileScreen({super.key, required this.userId});

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
        // Add Logout Button to the AppBar
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.fonts),
            onPressed: () async {
              await FirebaseAuth.instance.signOut(); // Perform logout
              Navigator.of(context)
                  .pushReplacementNamed('/login'); // Redirect to login screen
            },
            tooltip: 'Logout',
          ),
        ],
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

              const SizedBox(height: 32),

              // Add Trash option
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading:
                      const Icon(Icons.delete_outline, color: AppColors.fonts),
                  title: const Text('Trash',
                      style: TextStyle(color: AppColors.fonts)),
                  subtitle: const Text('View and restore deleted items'),
                  trailing: const Icon(Icons.arrow_forward_ios,
                      size: 16, color: AppColors.fonts),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TrashScreen(userId: userId),
                      ),
                    );
                  },
                ),
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
