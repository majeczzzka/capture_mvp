import 'package:flutter/material.dart';
import 'package:random_avatar/random_avatar.dart';
import '../utils/app_colors.dart';

/// A widget that displays a greeting message with an avatar.
class GreetingWidget extends StatelessWidget {
  final String name; // Name of the user to greet
  final String userId; // User ID for avatar generation

  const GreetingWidget({
    super.key,
    required this.name,
    required this.userId, // Add userId as a required parameter
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      // Center the Row horizontally
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min, // Row takes minimum horizontal space
          children: [
            // SVG avatar with border
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.fonts, // Color of the border
                  width: 2.0, // Border thickness
                ),
              ),
              child: ClipOval(
                child: RandomAvatar(
                  userId.hashCode
                      .toString(), // Use userId for avatar generation
                  height: 40, // Avatar height
                  width: 40, // Avatar width
                ),
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
