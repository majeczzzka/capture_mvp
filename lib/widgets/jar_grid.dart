import 'package:flutter/material.dart';
import 'jar_item.dart';
import '../models/jar_model.dart';

class JarGrid extends StatelessWidget {
  final String searchQuery;

  JarGrid({super.key, required this.searchQuery});

  final List<Jar> jars = [
    Jar(
        title: 'our story',
        filterColor: Colors.purpleAccent,
        images: ['assets/images/profile_picture.jpg']),
    Jar(
        title: 'room 314',
        filterColor: Color.fromARGB(255, 136, 208, 240),
        images: ['assets/images/profile_picture.jpg']),
    Jar(
        title: 'the trio',
        filterColor: Color.fromARGB(255, 255, 240, 161),
        images: ['assets/images/profile_picture.jpg']),
  ];

  @override
  Widget build(BuildContext context) {
    final filteredJars = jars
        .where((jar) =>
            jar.title.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    return GridView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: filteredJars.isNotEmpty ? filteredJars.length : 1,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.7,
      ),
      itemBuilder: (context, index) {
        if (filteredJars.isEmpty) {
          return Center(child: Text('No matching jars'));
        }
        return JarItem(jar: filteredJars[index]);
      },
    );
  }
}
