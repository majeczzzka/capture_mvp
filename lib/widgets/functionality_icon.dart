// widgets/icon_with_filter.dart
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class FunctionalityIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const FunctionalityIcon({
    super.key,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: ColorFiltered(
        colorFilter: const ColorFilter.mode(
          AppColors.fonts,
          BlendMode.srcIn,
        ),
        child: Icon(icon),
      ),
      onPressed: onPressed,
    );
  }
}
