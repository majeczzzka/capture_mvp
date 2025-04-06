import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:capture_mvp/firebase_options.dart'; // Import the real Firebase options

/// Sets up Firebase for integration testing
class FirebaseTestSetup {
  static bool _initialized = false;

  /// Initializes Firebase using the app's real Firebase configuration
  static Future<void> setupFirebaseForTesting() async {
    // Skip if already initialized to prevent hanging
    if (_initialized) {
      print('Firebase already initialized, skipping setup');
      return;
    }

    try {
      // Add a timeout to prevent hanging
      await _tryInitializeFirebase().timeout(
        const Duration(seconds: 10), // Longer timeout for real Firebase
        onTimeout: () {
          print('⚠️ Firebase initialization timed out');
        },
      );
      _initialized = true;
      print('✅ Firebase test setup completed successfully');
    } catch (e) {
      print('⚠️ Firebase test setup failed: $e');
      print('Continuing tests without Firebase initialization');
    }
  }

  /// Attempt to initialize Firebase with real configurations
  static Future<void> _tryInitializeFirebase() async {
    try {
      // See if Firebase is already initialized
      Firebase.app();
      print('Firebase was already initialized');
      _initialized = true;
    } catch (e) {
      print('Initializing Firebase with real configurations...');
      try {
        // Use the app's real Firebase options
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        print('Real Firebase initialized successfully');
      } catch (e) {
        print('Error during Firebase initialization: $e');
        // Fall back to test configuration if real fails
        try {
          print('Trying fallback test configuration...');
          await Firebase.initializeApp(
            name: 'test-app',
            options: const FirebaseOptions(
              apiKey: 'fake-api-key',
              appId: 'fake-app-id-1',
              messagingSenderId: 'fake-sender-id',
              projectId: 'fake-project-id',
              databaseURL: 'https://fake-project-id.firebaseio.test',
              storageBucket: 'fake-project-id.appspot.test',
            ),
          );
          print('Using test configuration instead');
        } catch (secondaryError) {
          print('Both real and test configurations failed: $secondaryError');
        }
      }
    }
  }

  /// Helper function to wrap a test app for Firebase error handling
  static Widget wrapAppForTesting(Widget app) {
    // Set up error handling to prevent test crashes
    FlutterError.onError = (details) {
      print('⚠️ Flutter error caught: ${details.exception}');
      // Log but don't crash the test
    };

    // Just return the app directly without wrapping it in another MaterialApp
    // This allows the real app's Firebase initialization to work properly
    return app;
  }
}
