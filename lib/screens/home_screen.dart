import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../widgets/nav/bottom_nav_bar.dart';
import '../widgets/header/header_widget.dart';
import '../widgets/home/greeting_widget.dart';
import '../widgets/home/jar_grid.dart';
import '../services/user_service.dart';
import '../widgets/home/content_container.dart';
import '../models/jar_data.dart';
import '../repositories/jar_repository.dart';

/// The main screen of the app displaying a greeting, jar grid, and navigation bar.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final UserService _userService = UserService(); // User service instance
  late JarRepository _jarRepository; // Repository for jar operations

  String _searchQuery = ''; // Holds the current search query
  String? _username; // Holds the fetched username
  String? _userId; // Holds the current user's ID
  bool _isLoading = true; // Loading state for fetching user data
  List<String> _collaborators = []; // Define the collaborators list

  @override
  void initState() {
    super.initState();
    _initializeUser(); // Initialize user data on screen load
  }

  /// Initializes user data by fetching the user ID and username.
  Future<void> _initializeUser() async {
    final user = await _userService.getCurrentUser();
    if (!mounted) return; // Return early if the widget has been disposed.

    setState(() {
      _userId = user?.uid;
      _username = user?.username ?? 'User';
      _isLoading = false;
    });

    if (_userId != null) {
      _jarRepository = JarRepository(userId: _userId!);
    }
  }

  /// Updates the search query and triggers UI refresh.
  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      // Show loading spinner while fetching user data
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_userId == null) {
      // Handle cases where the user ID is not available
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text(
            'Error: Unable to load user data.',
            style: TextStyle(fontSize: 16, color: Colors.red),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 80,
        automaticallyImplyLeading: false,
        title: GreetingWidget(
          name: _username ?? 'User',
          userId: _userId!,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            Expanded(
              child: ContentContainer(
                child: Column(
                  children: [
                    SizedBox(
                      height: 60,
                      child: HeaderWidget(
                        onSearchChanged: _onSearchChanged,
                        userId: _userId!,
                      ),
                    ),
                    const Divider(
                      thickness: 1,
                      color: AppColors.fonts,
                      indent: 8,
                      endIndent: 8,
                    ),
                    Expanded(
                      child: _userId == null
                          ? const Center(
                              child: Text('User ID not available'),
                            )
                          : JarGrid(
                              searchQuery: _searchQuery,
                              userId: _userId!,
                              collaborators: _collaborators,
                              jarRepository: _jarRepository,
                            ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(),
    );
  }
}
