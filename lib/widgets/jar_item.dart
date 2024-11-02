import 'package:flutter/material.dart';
import '../models/jar_model.dart';
import 'avatar_stack.dart'; // Import the AvatarStack widget

class JarItem extends StatelessWidget {
  final Jar jar;

  const JarItem({super.key, required this.jar});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // The jar image without any filter applied.
            Image.asset(
              'assets/images/jar.png',
              width: 200,
              height: 200,
            ),
            // Apply unique color filter from jar.filterColor
            Positioned.fill(
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  jar.filterColor.withOpacity(0.3),
                  BlendMode.modulate,
                ),
                child: Image.asset(
                  'assets/images/jar.png',
                  width: 200,
                  height: 200,
                ),
              ),
            ),
          ],
        ),
        Positioned(
          top: 100,
          child: Text(
            jar.title,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 20,
            ),
          ),
        ),
        Positioned(
          top: 130,
          child: AvatarStack(
            images: jar.images,
            radius: 13,
            overlap: 10,
          ),
        ),
      ],
    );
  }
}
