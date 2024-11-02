// widgets/logo_widget.dart
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class Logo extends StatelessWidget {
  const Logo({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 16),
        ColorFiltered(
          colorFilter: const ColorFilter.mode(
            AppColors.fonts, // Adjust opacity for the effect
            BlendMode.modulate, // Experiment with different blend modes
          ),
          child: Image.asset(
            'assets/images/logo.png',
            height: 60,
            width: 130,
          ),
        )
      ],
    );
  }
}
