import 'package:flutter/material.dart';
import 'jar_data.dart';

/// A UI model for displaying jars in the app interface.
/// This is separate from JarData model which handles persistence and business logic.
class JarDisplayModel {
  final String id; // The jar's unique identifier
  final String title; // The title or name of the jar
  final Color filterColor; // Color filter for styling the jar's appearance
  final List<Widget> images; // List of avatar widgets associated with the jar
  final String jarImage; // Image path for the jar itself
  final List<String> collaborators; // List of user IDs associated with the jar

  /// Constructor for creating a JarDisplayModel instance
  JarDisplayModel({
    required this.id,
    required this.title,
    required this.filterColor,
    required this.images,
    required this.jarImage,
    required this.collaborators,
  });

  /// Factory method to create a JarDisplayModel from JarData and avatar widgets
  /// This helps separate UI concerns from data concerns
  factory JarDisplayModel.fromJarData(JarData data, List<Widget> avatarWidgets,
      {String defaultImage = ''}) {
    // Convert hex color string to Color
    final Color color = data.color.startsWith('#')
        ? Color(int.parse(data.color.substring(1, 7), radix: 16) + 0xFF000000)
        : Colors.blue;

    return JarDisplayModel(
      id: data.id,
      title: data.name,
      filterColor: color,
      images: avatarWidgets,
      jarImage: defaultImage,
      collaborators: data.collaborators,
    );
  }
}

// For backward compatibility, keeping the original name as a typedef
typedef Jar = JarDisplayModel;
