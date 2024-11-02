import 'package:flutter/material.dart';

class Jar {
  final String title;
  final Color filterColor;
  final List<String> images; // List of avatar image paths

  Jar({
    required this.title,
    required this.filterColor,
    required this.images,
  });
}
