import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

/// A custom icon button with a color filter applied for styling.
class FunctionalityIcon extends StatelessWidget {
  final IconData icon; // The icon to display
  final VoidCallback onPressed; // Callback for when the icon is pressed

  const FunctionalityIcon({
    super.key,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      // Applies a color filter to the icon
      icon: ColorFiltered(
        colorFilter: const ColorFilter.mode(
          AppColors.fonts, // Sets the icon color
          BlendMode.srcIn, // Blend mode to apply the color
        ),
        child: Icon(icon), // The icon displayed within the button
      ),
      onPressed: onPressed, // Action triggered when the icon is tapped
    );
  }
}
