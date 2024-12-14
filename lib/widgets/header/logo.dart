import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

/// A widget that displays the app's logo with a color filter applied.
class Logo extends StatelessWidget {
  const Logo({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 16), // Adds padding on the left of the logo

        // Applies a color filter to the logo image for a consistent color theme
        ColorFiltered(
          colorFilter: const ColorFilter.mode(
            AppColors.fonts, // Color from the app's color theme
            BlendMode.modulate, // Blend mode to apply the color
          ),
          child: Image.asset(
            'assets/images/logo.png', // Logo image path
            height: 60, // Height of the logo
            width: 130, // Width of the logo
          ),
        ),
      ],
    );
  }
}
