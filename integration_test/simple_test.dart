import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:capture_mvp/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Simple App Test', () {
    testWidgets('App can launch without crashing', (WidgetTester tester) async {
      // Just launch the app - don't wait for animations
      await tester.pumpWidget(const CaptureApp());

      // Pump just a few frames and check for MaterialApp
      await tester.pump(const Duration(milliseconds: 500));

      // Verify app started by checking for MaterialApp
      expect(find.byType(MaterialApp), findsOneWidget);

      // Force test to finish before any timeouts
      print('✅ Basic app launch test completed successfully');
    });
  });
}
