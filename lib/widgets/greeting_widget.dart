import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

/// A widget that displays a greeting message with an avatar.
class GreetingWidget extends StatelessWidget {
  final String name; // Name of the user to greet

  const GreetingWidget({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return Center(
      // Center the Row horizontally
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min, // Row takes minimum horizontal space
          children: [
            // Circular avatar with border
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.fonts, // Color of the border
                  width: 2.0, // Border thickness
                ),
              ),
              child: const CircleAvatar(
                radius: 20, // Size of the avatar
                backgroundImage: AssetImage(
                    'assets/images/profile_picture.jpg'), // Avatar image
              ),
            ),
            const SizedBox(width: 8), // Space between avatar and greeting text
            Text(
              'hello, $name!', // Personalized greeting text
              style: const TextStyle(
                color: AppColors.fonts, // Font color for the greeting text
                fontSize: 20, // Font size of the greeting
              ),
            ),
          ],
        ),
      ),
    );
  }
}
