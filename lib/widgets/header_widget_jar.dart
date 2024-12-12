import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/logo.dart';
import '../utils/app_colors.dart';

/// Header widget for a specific jar page, with search and delete functionality.
class HeaderWidgetJar extends StatefulWidget {
  final ValueChanged<String>
      onSearchChanged; // Callback to notify search changes
  final String userId; // User ID to identify the Firestore document
  final String jarId; // Jar ID to identify the jar to delete
  final VoidCallback onDeletePressed; // Callback to handle jar deletion

  const HeaderWidgetJar({
    super.key,
    required this.onSearchChanged,
    required this.userId,
    required this.jarId,
    required this.onDeletePressed,
  });

  @override
  HeaderWidgetState createState() => HeaderWidgetState();
}

class HeaderWidgetState extends State<HeaderWidgetJar> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  /// Displays a confirmation dialog before triggering `onDeletePressed`.
  Future<void> _showDeleteConfirmation() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this jar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      widget.onDeletePressed(); // Trigger the delete action
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Header row with logo, delete, and search buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (!_isSearching) const Logo(), // Display logo when not searching
            Row(
              children: [
                // Delete jar button
                IconButton(
                  icon: const Icon(Icons.delete, color: AppColors.fonts),
                  onPressed: _showDeleteConfirmation,
                ),
                // Search button to toggle search bar
                IconButton(
                  icon: Icon(Icons.search, color: AppColors.fonts),
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
        // Search bar when _isSearching is true
        if (_isSearching)
          Positioned.fill(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      style: const TextStyle(color: AppColors.fonts),
                      decoration: InputDecoration(
                        hintText: 'Enter search query',
                        hintStyle: TextStyle(
                          color: AppColors.fonts.withOpacity(0.6),
                        ),
                        filled: true,
                        fillColor: AppColors.background,
                        prefixIcon: IconButton(
                          icon: const Icon(Icons.arrow_back,
                              color: AppColors.fonts),
                          onPressed: () {
                            setState(() {
                              _isSearching = false;
                            });
                            widget.onSearchChanged(''); // Clear search input
                          },
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear, color: AppColors.fonts),
                          onPressed: () {
                            _searchController.clear();
                            widget.onSearchChanged(''); // Clear search input
                          },
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20.0, vertical: 12.0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: widget.onSearchChanged, // Notify parent
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
