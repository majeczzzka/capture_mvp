import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Bare Minimum Tests', () {
    testWidgets('Can render a basic widget without any dependencies',
        (WidgetTester tester) async {
      // Create a minimal app with no external dependencies
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: Text('Hello World'),
            ),
          ),
        ),
      );

      // Verify it rendered
      expect(find.text('Hello World'), findsOneWidget);

      // Print something to show it's working
      print('✅ Successfully rendered basic widget');
    });
  });
}
