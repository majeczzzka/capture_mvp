import 'package:flutter/material.dart';
import '../models/jar_model.dart';
import 'avatar_stack.dart';
import '../screens/jar_page.dart';

class JarItem extends StatelessWidget {
  final Jar jar;
  final String userId; // User ID required for jar-specific actions
  final String jarId; // Jar ID required for unique identification

  const JarItem({
    super.key,
    required this.jar,
    required this.userId,
    required this.jarId,
  });

  @override
  Widget build(BuildContext context) {
    final darkerColor = Color.fromARGB(
      jar.filterColor.alpha, // Keep the same alpha
      (jar.filterColor.red * 0.7).toInt(), // Reduce red by 30%
      (jar.filterColor.green * 0.7).toInt(), // Reduce green by 30%
      (jar.filterColor.blue * 0.7).toInt(), // Reduce blue by 30%
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
              userId: userId, // Pass userId to JarPage
              jarId: jarId, // Pass jarId to JarPage
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
            child: SizedBox(
              width: 100, // Width of the jar image
              child: Text(
                jar.title,
                maxLines: 1, // Restrict to a single line
                overflow:
                    TextOverflow.ellipsis, // Add ellipsis if text overflows
                textAlign: TextAlign.center, // Center-align text
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: darkerColor,
                  fontSize: 20,
                ),
              ),
            ),
          ),

          // Contributor Avatars (using AvatarStack)
          Positioned(
            top: 130,
            child: AvatarStack(
              avatars: jar.images,
              radius: 13,
              overlap: 10,
            ),
          ),
        ],
      ),
    );
  }
}
