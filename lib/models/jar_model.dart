import 'package:flutter/material.dart';

/// A model representing a jar with a title, color filter, and associated avatars.
class Jar {
  final String title; // The title or name of the jar
  final Color filterColor; // Color filter for styling the jar's appearance
  final List<String>
      images; // List of avatar image paths associated with the jar
  final String jarImage; // Image path for the jar itself

  /// Constructor for creating a [Jar] instance.
  ///
  /// Requires [title], [filterColor], and a list of [images].
  Jar({
    required this.title,
    required this.filterColor,
    required this.images,
    required this.jarImage,
  });
}
