import 'package:capture_mvp/utils/app_colors.dart';
import 'package:flutter/material.dart';
import '../models/jar_model.dart';
import 'avatar_stack.dart';
import '../screens/jar_page.dart';

class JarItem extends StatelessWidget {
  final Jar jar;

  const JarItem({super.key, required this.jar});

  @override
  Widget build(BuildContext context) {
    final darkerColor = Color.fromARGB(
      jar.filterColor.alpha, // Keep the same alpha
      (jar.filterColor.red * 0.7).toInt(), // Reduce red by 20%
      (jar.filterColor.green * 0.7).toInt(), // Reduce green by 20%
      (jar.filterColor.blue * 0.7).toInt(), // Reduce blue by 20%
    );
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
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: darkerColor,
                fontSize: 20,
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
