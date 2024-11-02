import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

/// A dialog widget for adding a new jar with a title input field.
class AddJarDialog extends StatelessWidget {
  const AddJarDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.background, // Dialog background color

      // Dialog title
      title: const Text(
        'Add a New Jar',
        style: TextStyle(color: AppColors.fonts), // Font color for the title
      ),

      // Text field for entering the jar name
      content: const TextField(
        style: TextStyle(color: AppColors.fonts), // Input text color
        decoration: InputDecoration(
          hintText: 'Enter jar name', // Placeholder text
          hintStyle: TextStyle(color: AppColors.fonts), // Hint text color
        ),
      ),

      // Action buttons at the bottom of the dialog
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(), // Closes the dialog
          child: const Text(
            'Back',
            style: TextStyle(color: AppColors.fonts), // Button text color
          ),
        ),
      ],
    );
  }
}
