// widgets/bottom_nav_bar.dart
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      iconSize: 30,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: ''),
      ],
      selectedItemColor: AppColors.selectedFonts,
      unselectedItemColor: AppColors.fonts,
      backgroundColor: AppColors.navBar,
      showSelectedLabels: false,
      showUnselectedLabels: false,
    );
  }
}
