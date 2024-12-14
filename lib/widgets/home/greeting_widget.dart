import 'package:flutter/material.dart';
import 'package:random_avatar/random_avatar.dart';
import '../../utils/app_colors.dart';

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
          mainAxisSize: MainAxisSize.min,
          children: [
            // SVG avatar with border
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.fonts,
                  width: 2.0,
                ),
              ),
              child: ClipOval(
                child: RandomAvatar(
                  userId.hashCode.toString(),
                  height: 40,
                  width: 40,
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
