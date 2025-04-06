import 'package:flutter/material.dart';
import '../header/logo.dart';
import '../../utils/app_colors.dart';

/// A header widget specifically for the jar page, displaying only the logo.
class HeaderWidgetJar extends StatelessWidget {
  const HeaderWidgetJar({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: const [
        Logo(), // Left-aligned logo
      ],
    );
  }
}
