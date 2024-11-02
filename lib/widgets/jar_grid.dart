// widgets/jar_grid.dart
import 'package:flutter/material.dart';
import 'jar_item.dart';
import '../models/jar_model.dart';

class JarGrid extends StatelessWidget {
  final List<Jar> jars = [
    Jar(
      title: 'our story',
      filterColor: Colors.purpleAccent,
      images: [
        'assets/images/profile_picture.jpg',
        'assets/images/profile_picture.jpg',
      ],
    ),
    Jar(
      title: 'room 314',
      filterColor: const Color.fromARGB(255, 136, 240, 105),
      images: [
        'assets/images/profile_picture.jpg',
      ],
    ),
    Jar(
      title: 'the trio',
      filterColor: Color.fromARGB(255, 240, 161, 34),
      images: [
        'assets/images/profile_picture.jpg',
        'assets/images/profile_picture.jpg',
        'assets/images/profile_picture.jpg',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: jars.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.7,
        ),
        itemBuilder: (context, index) {
          return JarItem(jar: jars[index]);
        },
      ),
    );
  }
}
