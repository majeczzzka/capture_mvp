import 'package:flutter/material.dart';
import '../models/jar_model.dart';
import 'avatar_stack.dart';
import '../screens/jar_page.dart';

class JarItem extends StatelessWidget {
  final Jar jar;

  const JarItem({super.key, required this.jar});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => JarPage(
              jarTitle: jar.title,
              contributorAvatars: jar.images,
              jarColor: jar.filterColor,
              jarImage: jar.jarImage,
            ),
          ),
        );
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Jar Image with Color Filter
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              jar.filterColor.withOpacity(0.7),
              BlendMode.modulate,
            ),
            child: Image.asset(
              jar.jarImage,
              width: 200,
              height: 200,
            ),
          ),
          // Title Text on Jar
          Positioned(
            top: 100,
            child: Text(
              jar.title,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 20,
                shadows: [
                  Shadow(
                    offset:
                        Offset(1, 1), // Slight horizontal and vertical offset
                    blurRadius: 2.0, // Blur effect for the shadow
                    color:
                        Colors.black26, // Shadow color with some transparency
                  ),
                ],
              ),
            ),
          ),
          // Contributor Avatars (using AvatarStack)
          Positioned(
            top: 130,
            child: AvatarStack(
              images: jar.images,
              radius: 13,
              overlap: 10,
            ),
          ),
        ],
      ),
    );
  }
}
