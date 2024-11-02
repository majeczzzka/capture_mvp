import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class AvatarStack extends StatelessWidget {
  final List<String> images;
  final double radius;
  final double overlap;

  AvatarStack({
    required this.images,
    this.radius = 13,
    this.overlap = 8,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: (images.length) * overlap + 2 * radius,
      height: 3 * radius,
      child: Stack(
        children: images.asMap().entries.map((entry) {
          int index = entry.key;
          String image = entry.value;

          return Positioned(
            left: index * overlap,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.fonts,
                  width: 2.0,
                ),
              ),
              child: CircleAvatar(
                radius: radius,
                backgroundImage: AssetImage(image),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
