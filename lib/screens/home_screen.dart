import 'package:flutter/material.dart';
import '../widgets/greeting_widget.dart';
import '../widgets/header_widget.dart';
import '../widgets/jar_grid.dart';
import '../widgets/bottom_nav_bar.dart';
import '../utils/app_colors.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 80,
        title: GreetingWidget(name: 'maja'), // Use GreetingWidget here
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            // Container for header and jar grid
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: AppColors.jarGridBackground,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const HeaderWidget(), // Use HeaderWidget here
                    const Divider(
                      thickness: 1, // Adjust the thickness
                      color: AppColors
                          .fonts, // Adjust the color to match your design
                      indent: 8, // Add padding on the left side
                      endIndent: 8, // Add padding on the right side
                    ),
                    Expanded(child: JarGrid()), // Use the JarGrid widget here
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(), // Use BottomNavBar here
    );
  }
}
