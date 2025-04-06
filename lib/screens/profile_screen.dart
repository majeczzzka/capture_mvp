import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../widgets/nav/bottom_nav_bar.dart';
import '../widgets/home/greeting_widget.dart';
import '../repositories/user_repository.dart';
import '../repositories/auth_repository.dart';
import 'trash_screen.dart';

/// ProfileScreen displays the user's profile with an avatar and greeting.
class ProfileScreen extends StatefulWidget {
  final String userId; // User ID for fetching user data

  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserRepository _userRepository = UserRepository();
  final AuthRepository _authRepository = AuthRepository();
  String _username = 'User';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userData = await _userRepository.getUserData(widget.userId);
      if (userData != null) {
        setState(() {
          _username = userData['username'] ?? 'User';
          _isLoading = false;
        });
      } else {
        setState(() {
          _username = 'User';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading user data: $e');
      setState(() {
        _username = 'User';
        _isLoading = false;
      });
    }
  }

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
              try {
                await _authRepository.signOut(); // Use repository for sign out
                Navigator.of(context)
                    .pushReplacementNamed('/login'); // Redirect to login screen
              } catch (e) {
                print('❌ Error during logout: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Logout failed: ${e.toString()}')),
                );
              }
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
              _isLoading
                  ? const CircularProgressIndicator()
                  : GreetingWidget(
                      name: _username,
                      userId: widget.userId,
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
                        builder: (context) =>
                            TrashScreen(userId: widget.userId),
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
