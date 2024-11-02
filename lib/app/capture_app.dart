import 'package:flutter/material.dart';
import '../screens/home_screen.dart';

class CaptureApp extends StatelessWidget {
  const CaptureApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}
