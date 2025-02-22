// lib/app/capture_app.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';
import 'amplifyconfiguration.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
// Screens
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/splash_screen.dart';

Future<void> configureAmplify() async {
  try {
    print('Starting Amplify configuration...');

    // Create the plugin instances
    final authPlugin = AmplifyAuthCognito();
    final storagePlugin = AmplifyStorageS3();

    print('Created plugins');

    // Add ALL plugins before configure
    await Amplify.addPlugins([authPlugin, storagePlugin]);
    print('Added plugins');

    // Configure Amplify
    await Amplify.configure(amplifyconfig);
    print('Configured Amplify');

    if (Amplify.isConfigured) {
      print('✅ Amplify is configured and ready');
    } else {
      print('⚠️ Amplify is not configured');
    }
  } catch (e, stackTrace) {
    print('⚠️ Error configuring Amplify: $e');
    print('Stack trace: $stackTrace');
    rethrow;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await configureAmplify();
    print("✅ Amplify configured successfully");
  } catch (e) {
    print("⚠️ Failed to configure Amplify: $e");
  }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  print("✅ Firebase initialized successfully");

  try {
    String envPath = ".env";
    await dotenv.load(fileName: envPath);
    print("✅ .env file loaded successfully: ${dotenv.env}");
  } catch (e) {
    print("⚠️ ERROR: .env file could not be loaded: $e");
  }

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
        '/calendar': (context) {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            return CalendarScreen(userId: user.uid);
          }
          return LoginScreen(); // Redirect to login if no user is found
        },
        '/profile': (context) {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            return ProfileScreen(
              userId: user.uid,
            );
          }
          return LoginScreen();
        },
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
