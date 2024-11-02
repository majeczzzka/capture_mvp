// lib/screens/calendar_view.dart
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calendar View')),
      body: const Center(child: Text('Hey, this is a calendar view')),
      backgroundColor: AppColors.background,
    );
  }
}
