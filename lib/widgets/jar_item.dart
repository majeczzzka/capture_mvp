import 'package:flutter/material.dart';
import '../models/jar_model.dart';
import 'avatar_stack.dart';
import '../screens/jar_page.dart'; // Import the new JarPage screen

class JarItem extends StatelessWidget {
  final Jar jar;

  const JarItem({super.key, required this.jar});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // Navigate to the JarPage when the jar is tapped
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => JarPage(jar: jar),
          ),
        );
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Image.asset(
                'assets/images/jar.png',
                width: 200,
                height: 200,
              ),
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
      ),
    );
  }
}
