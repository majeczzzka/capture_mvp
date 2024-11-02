import 'package:flutter/material.dart';
import 'package:capture_mvp/widgets/functionality_icon.dart';
import '../widgets/logo.dart';
import '../utils/app_colors.dart';

class HeaderWidget extends StatefulWidget {
  final ValueChanged<String>
      onSearchChanged; // Callback to notify search changes

  const HeaderWidget({
    super.key,
    required this.onSearchChanged,
  });

  @override
  HeaderWidgetState createState() => HeaderWidgetState();
}

class HeaderWidgetState extends State<HeaderWidget> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  void _showAddJarDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add a New Jar'),
          content: TextField(
            decoration: InputDecoration(
              hintText: 'Enter jar name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Back', style: TextStyle(color: AppColors.fonts)),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (!_isSearching) const Logo(),
            Row(
              children: [
                FunctionalityIcon(
                  icon: Icons.add,
                  onPressed: _showAddJarDialog, // Add jar dialog functionality
                ),
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
        if (_isSearching)
          Positioned.fill(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              color: Colors
                  .white, // Customize the background color of the search bar if needed
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      style: TextStyle(color: AppColors.fonts),
                      decoration: InputDecoration(
                        hintText: 'Enter search query',
                        hintStyle:
                            TextStyle(color: AppColors.fonts.withOpacity(0.6)),
                        filled: true,
                        fillColor: AppColors
                            .background, // Set your custom background color
                        prefixIcon: IconButton(
                          icon: Icon(Icons.arrow_back, color: AppColors.fonts),
                          onPressed: () {
                            setState(() {
                              _isSearching = false;
                            });
                            widget.onSearchChanged(''); // Clear search input
                          },
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.clear, color: AppColors.fonts),
                          onPressed: () {
                            _searchController.clear();
                            widget.onSearchChanged(''); // Clear search input
                          },
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20.0, vertical: 12.0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                              30), // Keep the original radius
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: widget
                          .onSearchChanged, // Notify parent of search changes
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
