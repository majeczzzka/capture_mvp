import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_shadows.dart';

/// A container for wrapping content with a background color and shadow.
class ContentContainer extends StatelessWidget {
  final Widget child;

  const ContentContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: AppColors.jarGridBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.subtleShadowList,
      ),
      child: child,
    );
  }
}
