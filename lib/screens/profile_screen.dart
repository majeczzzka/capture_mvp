import 'package:capture_mvp/utils/app_colors.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile View')),
      body: const Center(child: Text('Hey, this is a profile view')),
      backgroundColor: AppColors.background,
    );
  }
}
