import 'package:capture_mvp/widgets/functionality_icon.dart';
import 'package:flutter/material.dart';
import '../widgets/logo.dart';

class HeaderWidget extends StatelessWidget {
  const HeaderWidget({super.key});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Logo(),
        Row(
          children: [
            FunctionalityIcon(
              icon: Icons.add,
              onPressed: () {
                // Add jar creation functionality
              },
            ),
            FunctionalityIcon(
              icon: Icons.search,
              onPressed: () {
                // Add search functionality
              },
            ),
          ],
        ),
      ],
    );
  }
}
