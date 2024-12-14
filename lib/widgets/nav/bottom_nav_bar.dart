// widgets/bottom_nav_bar.dart
import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      iconSize: 30,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: '',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: ''),
      ],
      selectedItemColor: AppColors.selectedFonts,
      unselectedItemColor: AppColors.fonts,
      backgroundColor: AppColors.navBar,
      showSelectedLabels: false,
      showUnselectedLabels: false,
      onTap: (index) {
        // Define navigation based on the tapped icon's index
        switch (index) {
          case 0:
            Navigator.pushNamed(context, '/home'); // Home screen route
            break;
          case 1:
            Navigator.pushNamed(context, '/calendar'); // Calendar screen route
            break;
          case 2:
            Navigator.pushNamed(context, '/profile'); // Profile screen route
            break;
        }
      },
    );
  }
}
