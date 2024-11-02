import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class GreetingWidget extends StatelessWidget {
  final String name;

  const GreetingWidget({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return Center(
      // Center the entire Row horizontally
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          mainAxisSize:
              MainAxisSize.min, // Adjust Row to take minimum horizontal space
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.fonts, // Border color
                  width: 2.0, // Border width
                ),
              ),
              child: const CircleAvatar(
                radius: 20, // Set the size of the avatar
                backgroundImage:
                    AssetImage('assets/images/profile_picture.jpg'),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'hello, $name!',
              style: const TextStyle(
                color: AppColors.fonts,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
