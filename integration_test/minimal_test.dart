import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Minimal app tests', () {
    testWidgets('Can render basic widgets', (WidgetTester tester) async {
      // Build a minimal test app that doesn't depend on Firebase
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              title: const Text('Test App'),
            ),
            body: const Center(
              child: Text('Integration Test'),
            ),
          ),
        ),
      );

      // Verify basic widgets are rendered
      expect(find.text('Test App'), findsOneWidget);
      expect(find.text('Integration Test'), findsOneWidget);

      print('✅ Successfully rendered basic widgets');
    });
  });
}
