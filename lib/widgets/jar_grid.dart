import 'package:flutter/material.dart';
import 'jar_item.dart';
import '../models/jar_model.dart';

/// A grid widget that displays a list of jars, filtered by a search query.
class JarGrid extends StatelessWidget {
  final String searchQuery; // Search query to filter jars by title

  JarGrid({super.key, required this.searchQuery});

  // Sample data representing jars with titles, colors, and images
  final List<Jar> jars = [
    Jar(
      title: 'our story',
      filterColor: const Color.fromARGB(255, 224, 114, 243),
      images: [
        'assets/images/profile_picture.jpg',
        'assets/images/profile_picture.jpg',
      ],
      jarImage: 'assets/images/jar.png',
    ),
    Jar(
      title: 'room 314',
      filterColor: const Color.fromARGB(255, 182, 248, 138),
      images: [
        'assets/images/profile_picture.jpg',
      ],
      jarImage: 'assets/images/jar.png',
    ),
    Jar(
      title: 'the trio',
      filterColor: const Color.fromARGB(255, 255, 215, 134),
      images: [
        'assets/images/profile_picture.jpg',
        'assets/images/profile_picture.jpg',
        'assets/images/profile_picture.jpg',
      ],
      jarImage: 'assets/images/jar.png',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Filter jars by checking if the title contains the search query (case-insensitive)
    final filteredJars = jars
        .where((jar) =>
            jar.title.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    // If no jars match the search query, display a centered message
    if (filteredJars.isEmpty) {
      return const Center(
        child: Text(
          'No matching jars',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    // Display a grid of jars that match the search query
    return GridView.builder(
      padding: const EdgeInsets.all(8.0), // Padding around the grid
      itemCount: filteredJars.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // Two columns in the grid
        mainAxisSpacing: 10, // Vertical spacing between grid items
        crossAxisSpacing: 10, // Horizontal spacing between grid items
        childAspectRatio:
            0.7, // Aspect ratio to control item height relative to width
      ),
      itemBuilder: (context, index) {
        return JarItem(
            jar: filteredJars[index]); // Displays each filtered jar item
      },
    );
  }
}
