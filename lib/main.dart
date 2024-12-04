// lib/app/capture_app.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

// Screens
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const CaptureApp());
}

/// The root widget of the Capture application.
class CaptureApp extends StatelessWidget {
  const CaptureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(), // The wrapper to manage authentication flow
      routes: {
        '/login': (context) => LoginScreen(),
        '/signup': (context) => SignUpScreen(),
        '/home': (context) => const HomeScreen(),
        '/calendar': (context) => CalendarScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}

/// A wrapper widget to handle user authentication state.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        print("AuthWrapper: Checking user state");
        if (snapshot.connectionState == ConnectionState.active) {
          final user = snapshot.data;
          print(
              "AuthWrapper: User is ${user != null ? "logged in" : "not logged in"}");
          if (user == null) {
            // Show LoginScreen if user is not logged in
            return LoginScreen();
          } else {
            // Show HomeScreen if user is logged in
            return const HomeScreen();
          }
        }
        // Show a loading spinner while waiting for authentication state
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}
