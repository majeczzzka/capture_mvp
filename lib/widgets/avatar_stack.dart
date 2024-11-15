import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

/// A widget that displays a stack of overlapping avatar images.
class AvatarStack extends StatelessWidget {
  final List<String> images; // List of image paths for the avatars
  final double radius; // Radius of each avatar
  final double overlap; // Amount of overlap between avatars

  const AvatarStack({
    super.key,
    required this.images,
    this.radius = 13,
    this.overlap = 8,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // Calculate total width based on the number of images, overlap, and radius
      width: (images.length) * overlap + 2 * radius,
      height: 3 * radius, // Adjust height to fit the avatars

      // Stack to layer avatars on top of each other with overlap
      child: Stack(
        children: images.asMap().entries.map((entry) {
          int index = entry.key;
          String image = entry.value;

          return Positioned(
            left: index * overlap, // Position each avatar with overlap
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.fonts, // Border color around each avatar
                  width: 2.0, // Border thickness
                ),
              ),
              child: CircleAvatar(
                radius: radius, // Set avatar radius
                backgroundImage: AssetImage(image), // Display the image
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
