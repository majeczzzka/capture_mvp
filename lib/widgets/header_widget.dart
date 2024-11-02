import 'package:flutter/material.dart';
import 'package:capture_mvp/widgets/functionality_icon.dart';
import '../widgets/logo.dart';
import '../utils/app_colors.dart';

class HeaderWidget extends StatefulWidget {
  const HeaderWidget({super.key});

  @override
  HeaderWidgetState createState() => HeaderWidgetState();
}

class HeaderWidgetState extends State<HeaderWidget> {
  bool _isSearching = false; // Toggle search bar visibility
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _jarNameController =
      TextEditingController(); // Controller for the jar name

  void _showAddJarDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add a New Jar'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _jarNameController,
                decoration: const InputDecoration(
                  labelText: 'Jar Name',
                  hintText: 'Enter jar name',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _jarNameController.clear(); // Clear input field
                Navigator.of(context).pop(); // Close the dialog
              },
              child:
                  const Text('Back', style: TextStyle(color: AppColors.fonts)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Main Row with Logo and Icons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (!_isSearching) const Logo(),
            Row(
              children: [
                FunctionalityIcon(
                  icon: Icons.add,
                  onPressed: _showAddJarDialog, // Show add jar dialog
                ),
                IconButton(
                  icon: const Icon(Icons.search, color: AppColors.fonts),
                  onPressed: () {
                    setState(() {
                      _isSearching = true;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
        // Search Bar Overlay
        if (_isSearching)
          Positioned.fill(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              color: Colors.white, // Background color for the search bar
              child: Row(
                children: [
                  Expanded(
                    child: SearchBar(
                      controller: _searchController,
                      hintText: 'Enter search query',
                      leading: IconButton(
                        icon: const Icon(Icons.arrow_back,
                            color: AppColors.fonts),
                        onPressed: () {
                          setState(() {
                            _isSearching = false;
                          });
                        },
                      ),
                      trailing: [
                        IconButton(
                          icon: const Icon(Icons.clear, color: AppColors.fonts),
                          onPressed: () {
                            _searchController.clear(); // Clear search field
                          },
                        ),
                      ],
                      onChanged: (query) {
                        // Handle search input change
                      },
                      onSubmitted: (query) {
                        // Handle search submission
                      },
                      backgroundColor:
                          WidgetStateProperty.all(AppColors.background),
                      elevation: WidgetStateProperty.all(0), // Flat style
                      shape: WidgetStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      padding: WidgetStateProperty.all(
                        const EdgeInsets.symmetric(horizontal: 8.0),
                      ),
                      autoFocus: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
