import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Navigation Tests', () {
    testWidgets('Can navigate between screens', (WidgetTester tester) async {
      // Define simple screens for testing navigation
      final homeScreen = Scaffold(
        appBar: AppBar(title: const Text('Home')),
        body: Center(
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(tester.element(find.byType(ElevatedButton)))
                  .push(MaterialPageRoute(
                builder: (context) => Scaffold(
                  appBar: AppBar(title: const Text('Details')),
                  body: const Center(child: Text('Details Screen')),
                ),
              ));
            },
            child: const Text('Go to Details'),
          ),
        ),
      );

      // Build our app and trigger a frame
      await tester.pumpWidget(
        MaterialApp(
          home: homeScreen,
        ),
      );

      print('✅ App rendered successfully');

      // Verify Home screen is showing
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Go to Details'), findsOneWidget);
      print('✅ Home screen is visible');

      // Tap the button to navigate to Details screen
      await tester.tap(find.text('Go to Details'));
      await tester.pumpAndSettle(); // Wait for navigation animation to complete

      // Verify we've navigated to Details screen
      expect(find.text('Home'), findsNothing);
      expect(find.text('Details'), findsOneWidget);
      expect(find.text('Details Screen'), findsOneWidget);
      print('✅ Successfully navigated to Details screen');

      // Test navigation back
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      // Verify we're back on Home screen
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Go to Details'), findsOneWidget);
      print('✅ Successfully navigated back to Home screen');
    });
  });
}
