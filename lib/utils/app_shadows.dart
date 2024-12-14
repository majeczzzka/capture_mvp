import 'package:flutter/material.dart';

// App shadows
class AppShadows {
  static final BoxShadow subtleShadow = BoxShadow(
    color: Colors.black.withOpacity(0.1), // Shadow color
    spreadRadius: 2, // How wide the shadow spreads
    blurRadius: 8, // How soft the shadow is
    offset: const Offset(2, 4), // Offset to make shadow look realistic
  );

  static final List<BoxShadow> subtleShadowList = [
    subtleShadow,
  ];
}
