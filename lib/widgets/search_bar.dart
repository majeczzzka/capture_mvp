import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

/// A custom search bar widget with a pop-up style, including back and clear buttons.
class SearchBarPop extends StatefulWidget {
  final VoidCallback onBackPressed; // Callback for back button press
  final VoidCallback onClearPressed; // Callback for clear button press
  final ValueChanged<String>
      onSearchChanged; // Callback for search input changes

  const SearchBarPop({
    super.key,
    required this.onBackPressed,
    required this.onClearPressed,
    required this.onSearchChanged,
  });

  @override
  SearchBarPopState createState() => SearchBarPopState();
}

class SearchBarPopState extends State<SearchBarPop> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();

    // Listen to changes in the text field and trigger onSearchChanged
    _searchController.addListener(() {
      widget.onSearchChanged(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController
        .dispose(); // Clean up the controller when widget is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
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
                  hintStyle: TextStyle(color: AppColors.fonts.withOpacity(0.6)),
                  filled: true,
                  fillColor: AppColors.background,

                  // Back button to exit search mode
                  prefixIcon: IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.fonts),
                    onPressed: () {
                      widget.onBackPressed();
                      _searchController.clear(); // Reset input on back
                    },
                  ),

                  // Clear button to clear search input
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear, color: AppColors.fonts),
                    onPressed: () {
                      _searchController.clear(); // Clears input field
                      widget.onClearPressed();
                    },
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 12.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (text) {
                  widget
                      .onSearchChanged(text); // Trigger callback on text change
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
