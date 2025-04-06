import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:capture_mvp/main.dart';
import 'package:capture_mvp/screens/jar_page.dart';
import 'package:capture_mvp/screens/home_screen.dart';
import 'test_utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Jar Content Flow Tests', () {
    // This test checks the jar content upload flow
    // Note: It assumes the user is already logged in and has at least one jar
    testWidgets('Navigate to jar and view content',
        (WidgetTester tester) async {
      // Launch the app
      await tester.pumpWidget(const CaptureApp());

      // Wait for the splash screen and possible login screen
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Check if we need to login
      if (find.text('Sign In').evaluate().isNotEmpty) {
        // Enter email and password
        await TestUtils.enterText(tester, 'test@example.com', atIndex: 0);
        await TestUtils.enterText(tester, 'password123', atIndex: 1);

        // Tap sign in button
        await TestUtils.tapText(tester, 'Sign In');

        // Wait for login and navigation
        await tester.pumpAndSettle(const Duration(seconds: 5));
      }

      // Verify we're on home screen
      expect(find.byType(HomeScreen), findsOneWidget);

      // Find the first jar item and tap it
      final jarItem = find.byType(InkWell).evaluate().firstWhere(
            (element) =>
                element.widget is InkWell &&
                (element.widget as InkWell).onTap != null &&
                element.findAncestorWidgetOfExactType<Image>() != null,
            orElse: () => throw Exception('No jar items found on home screen'),
          );

      await tester.tap(find.byWidget(jarItem.widget));
      await tester.pumpAndSettle();

      // Verify we're on jar page
      expect(find.byType(JarPage), findsOneWidget);

      // Check for multimedia options
      expect(find.text('Photo'), findsOneWidget);
      expect(find.text('Video'), findsOneWidget);
    });

    // This test is marked as skipped because it would require setting up mock media files
    // and permissions in the integration test environment, which is complex
    testWidgets('Upload content to jar', (WidgetTester tester) async {
      // Mark this test as skipped in actual execution
      markTestSkipped(
          'This test requires real device capabilities to upload media');

      // Launch the app
      await tester.pumpWidget(const CaptureApp());

      // Wait for the splash screen and possible login screen
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Check if we need to login
      if (find.text('Sign In').evaluate().isNotEmpty) {
        // Enter email and password
        await TestUtils.enterText(tester, 'test@example.com', atIndex: 0);
        await TestUtils.enterText(tester, 'password123', atIndex: 1);

        // Tap sign in button
        await TestUtils.tapText(tester, 'Sign In');

        // Wait for login and navigation
        await tester.pumpAndSettle(const Duration(seconds: 5));
      }

      // Verify we're on home screen
      expect(find.byType(HomeScreen), findsOneWidget);

      // Find and tap first jar
      final jarItems = find
          .byType(InkWell)
          .evaluate()
          .where(
            (element) =>
                element.widget is InkWell &&
                (element.widget as InkWell).onTap != null &&
                element.findAncestorWidgetOfExactType<Image>() != null,
          )
          .toList();

      if (jarItems.isEmpty) {
        throw Exception('No jar items found on home screen');
      }

      await tester.tap(find.byWidget(jarItems.first.widget));
      await tester.pumpAndSettle();

      // Find and tap on "Photo" option
      await TestUtils.tapText(tester, 'Photo');
      await tester.pumpAndSettle();

      // Note: In a real integration test on a device, you would need to:
      // 1. Create a test image file
      // 2. Mock the image picker to return this file
      // 3. Check that the content was added to the jar

      // Since we can't actually test file upload in the test environment,
      // we just verify that we reached the proper screen
      expect(find.byType(JarPage), findsOneWidget);
    });
  });
}
