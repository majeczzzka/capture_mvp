import 'package:capture_mvp/utils/app_shadows.dart';
import 'package:flutter/material.dart';
import '../widgets/greeting_widget.dart';
import '../widgets/header_widget.dart';
import '../widgets/jar_grid.dart';
import '../widgets/bottom_nav_bar.dart';
import '../utils/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// The main screen of the app displaying a greeting, jar grid, and navigation bar.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _searchQuery = ''; // Holds the current search query
  String? _username; // Holds the fetched username
  bool _isLoading = true; // Loading state for fetching username

  @override
  void initState() {
    super.initState();
    _fetchUsername(); // Fetch username on screen load
  }

  /// Fetches the username for the logged-in user from Firestore.
  Future<void> _fetchUsername() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid != null) {
        final doc = await _firestore.collection('users').doc(uid).get();
        setState(() {
          _username = doc.data()?['username'] ?? 'User';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _username = 'User';
        _isLoading = false;
      });
    }
  }

  /// Updates the search query and triggers UI refresh
  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      // Show loading spinner while fetching username
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background, // Sets background color from theme

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0, // Removes shadow for a flat appearance
        toolbarHeight: 80,
        automaticallyImplyLeading: false, // Ensures no back button is shown
        title: GreetingWidget(
          name: _username ?? 'User', // Pass the fetched username
        ), // Personalized greeting widget
        leading: null, // Explicitly ensure no leading widget
      ),

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: AppColors
                      .jarGridBackground, // Background for jar grid container
                  borderRadius: BorderRadius.circular(16),
                  boxShadow:
                      AppShadows.subtleShadowList, // Rounded container edges
                ),
                child: Column(
                  children: [
                    // Header section with fixed height, including search functionality
                    SizedBox(
                      height: 60,
                      child: HeaderWidget(
                        onSearchChanged:
                            _onSearchChanged, // Passes search changes
                      ),
                    ),
                    const Divider(
                      thickness: 1,
                      color: AppColors.fonts,
                      indent: 8,
                      endIndent: 8, // Styling for the divider line
                    ),
                    // Main content area with jar grid, filtered by search query
                    Expanded(
                      child: JarGrid(searchQuery: _searchQuery),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16), // Spacing before the navigation bar
          ],
        ),
      ),

      bottomNavigationBar: const BottomNavBar(), // Bottom navigation bar widget
    );
  }
}
