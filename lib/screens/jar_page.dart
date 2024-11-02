// lib/screens/jar_page.dart
import 'package:flutter/material.dart';
import '../models/jar_model.dart';
import '../widgets/bottom_nav_bar.dart'; // Import the BottomNavBar

class JarPage extends StatelessWidget {
  final Jar jar;

  const JarPage({super.key, required this.jar});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(jar.title), // Displays the jar's title in the app bar
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Display the jar image
            ColorFiltered(
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
            const SizedBox(height: 20),
            Text(
              'Jar Page: ${jar.title}', // Display jar title
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            // Additional content (avatars or other details) can go here
          ],
        ),
      ),

      // Adds the BottomNavBar to the screen
      bottomNavigationBar: const BottomNavBar(),
    );
  }
}
