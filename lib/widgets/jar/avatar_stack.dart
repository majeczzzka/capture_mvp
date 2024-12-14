import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

/// A widget that displays a stack of overlapping avatar widgets.
class AvatarStack extends StatelessWidget {
  final List<Widget> avatars; // List of avatar widgets
  final double radius; // Radius of each avatar
  final double overlap; // Amount of overlap between avatars

  const AvatarStack({
    super.key,
    required this.avatars,
    this.radius = 13,
    this.overlap = 8,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // Calculate total width based on the number of avatars, overlap, and radius
      width: (avatars.length) * overlap + 2 * radius,
      height: 3 * radius, // Adjust height to fit the avatars

      // Stack to layer avatars on top of each other with overlap
      child: Stack(
        children: avatars.asMap().entries.map((entry) {
          int index = entry.key;
          Widget avatar = entry.value;

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
              child: ClipOval(
                child: SizedBox(
                  width: 2 * radius,
                  height: 2 * radius,
                  child: avatar, // Use the provided avatar widget
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
