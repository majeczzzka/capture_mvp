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
import 'services/s3_service.dart';
import 'repositories/s3_repository.dart';
import 'repositories/auth_repository.dart';
// Screens
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/trash_screen.dart';

Future<void> configureAmplify() async {
  try {
    // Check if Amplify is already configured to avoid duplicate configuration
    if (Amplify.isConfigured) {
      print('Amplify is already configured');
      return;
    }

    print('Starting Amplify configuration...');

    // Both plugins are needed - S3 needs Auth for permissions even with guest access
    final storagePlugin = AmplifyStorageS3();
    final authPlugin = AmplifyAuthCognito();
    print('Created storage and auth plugins');

    // Clear any existing plugins
    try {
      await Amplify.reset();
      print('Reset Amplify');
    } catch (e) {
      print('No need to reset Amplify: $e');
    }

    // Add plugins one by one to better identify issues
    try {
      await Amplify.addPlugin(authPlugin);
      print('Added auth plugin');
    } catch (authError) {
      print('Error adding auth plugin: $authError');
    }

    try {
      await Amplify.addPlugin(storagePlugin);
      print('Added storage plugin');
    } catch (storageError) {
      print('Error adding storage plugin: $storageError');
    }

    // Configure Amplify with the configuration that includes guest access
    try {
      print('About to configure Amplify with: $amplifyconfig');
      await Amplify.configure(amplifyconfig);
      print('Configured Amplify with guest access');
    } catch (configError) {
      print('Error configuring Amplify: $configError');
      if (!Amplify.isConfigured) {
        // If configure fails, try with a delay and retry once
        await Future.delayed(const Duration(seconds: 1));
        await Amplify.configure(amplifyconfig);
        print('Configured Amplify with guest access (retry)');
      }
    }

    if (Amplify.isConfigured) {
      print('✅ Amplify is configured and ready with guest access');

      // Test the configuration with a simple S3 list operation
      try {
        print('🧪 Testing S3 list operation...');
        final listOperation = await Amplify.Storage.list();
        final listResult = await listOperation.result;
        print('✅ S3 list successful, found ${listResult.items.length} items');
      } catch (e) {
        print('❌ S3 list test failed: $e');
      }
    } else {
      print('⚠️ Amplify is not configured');
    }
  } catch (e, stackTrace) {
    print('⚠️ Error during Amplify setup: $e');
    print('Stack trace: $stackTrace');

    // Don't rethrow - let the app continue even if Amplify fails
    // This way the app won't crash if there's an issue with S3
    print('Continuing without Amplify configuration');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    String envPath = ".env";
    await dotenv.load(fileName: envPath);
    print("✅ .env file loaded successfully: ${dotenv.env}");
  } catch (e) {
    print("⚠️ ERROR: .env file could not be loaded: $e");
  }

  // Initialize Firebase FIRST before any other services
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("✅ Firebase initialized successfully");
  } catch (e) {
    print("⚠️ Failed to initialize Firebase: $e");
  }

  // Then configure Amplify AFTER Firebase is initialized
  try {
    await configureAmplify();
    print("✅ Amplify configured successfully");

    // Test S3 bucket access
    final s3Repository = S3Repository(userId: 'init-check');
    final bucketOk = await s3Repository.checkAndInitializeS3();
    if (bucketOk) {
      print("✅ S3 bucket is accessible");
    } else {
      print("⚠️ S3 bucket issue - uploads may not work");
      print(
          "⚠️ Please verify the bucket '${dotenv.env['AWS_BUCKET_NAME']}' exists in the AWS console");
    }
  } catch (e) {
    print("⚠️ Failed to configure Amplify: $e");
  }

  runApp(const CaptureApp());
}

/// The root widget of the Capture application.
class CaptureApp extends StatelessWidget {
  const CaptureApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authRepository = AuthRepository();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(), // The wrapper to manage authentication flow
      routes: {
        '/login': (context) => LoginScreen(),
        '/signup': (context) => SignUpScreen(),
        '/home': (context) => const HomeScreen(),
        '/calendar': (context) {
          final user = authRepository.getCurrentUser();
          if (user != null) {
            return CalendarScreen(userId: user.uid);
          }
          return LoginScreen(); // Redirect to login if no user is found
        },
        '/profile': (context) {
          final user = authRepository.getCurrentUser();
          if (user != null) {
            return ProfileScreen(
              userId: user.uid,
            );
          }
          return LoginScreen();
        },
        '/trash': (context) {
          final user = authRepository.getCurrentUser();
          if (user != null) {
            return TrashScreen(userId: user.uid);
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
    final authRepository = AuthRepository();

    return StreamBuilder<User?>(
      stream: authRepository.authStateChanges(),
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
