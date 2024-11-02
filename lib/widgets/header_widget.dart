import 'package:flutter/material.dart';
import 'package:capture_mvp/widgets/functionality_icon.dart';
import 'package:capture_mvp/widgets/search_bar.dart';
import 'package:capture_mvp/widgets/add_jar_dialog.dart';
import '../widgets/logo.dart';
import '../utils/app_colors.dart';

/// A header widget displaying the app logo, add button, and search functionality.
class HeaderWidget extends StatefulWidget {
  final ValueChanged<String> onSearchChanged; // Callback to update search query

  const HeaderWidget({
    super.key,
    required this.onSearchChanged,
  });

  @override
  HeaderWidgetState createState() => HeaderWidgetState();
}

class HeaderWidgetState extends State<HeaderWidget> {
  bool _isSearching = false; // Tracks if the search bar is active

  /// Opens a dialog for adding a new jar
  void _showAddJarDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const AddJarDialog(); // Dialog widget to create a new jar
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center, // Centers elements in the stack
      children: [
        // Main row containing logo, add button, and search button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (!_isSearching) const Logo(), // Display logo when not searching
            Row(
              children: [
                // Button to open the add jar dialog
                FunctionalityIcon(
                  icon: Icons.add,
                  onPressed: _showAddJarDialog,
                ),
                // Button to toggle search bar visibility
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

        // Display search bar when _isSearching is true
        if (_isSearching)
          SearchBarPop(
            onBackPressed: () {
              setState(() {
                _isSearching = false;
              });
              widget.onSearchChanged(''); // Clears search input
            },
            onClearPressed: () {
              widget.onSearchChanged(''); // Clears search input
            },
            onSearchChanged: widget.onSearchChanged, // Updates search query
          ),
      ],
    );
  }
}
