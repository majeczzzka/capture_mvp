import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Form Validation Tests', () {
    testWidgets('Email validation works correctly',
        (WidgetTester tester) async {
      // Controller to capture input
      final emailController = TextEditingController();
      String? errorMessage;

      // Simple form widget with validation
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    errorText: errorMessage,
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Simple email validation
                    if (!emailController.text.contains('@') ||
                        !emailController.text.contains('.')) {
                      errorMessage = 'Please enter a valid email';
                    } else {
                      errorMessage = null;
                    }
                    // This triggers a rebuild to show the error message
                    (tester.state(find.byType(StatefulBuilder)) as StateSetter)
                        .call(() {});
                  },
                  child: const Text('Validate'),
                ),
              ],
            ),
          ),
        ),
      );

      print('✅ Form rendered successfully');

      // Test invalid email
      await tester.enterText(find.byType(TextField), 'invalidemail');
      await tester.pump();
      expect(emailController.text, 'invalidemail');
      print('✅ Entered invalid email: invalidemail');

      // Validate form
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      expect(find.text('Please enter a valid email'), findsOneWidget);
      print('✅ Invalid email rejected correctly');

      // Test valid email
      await tester.enterText(find.byType(TextField), 'valid@email.com');
      await tester.pump();
      expect(emailController.text, 'valid@email.com');
      print('✅ Entered valid email: valid@email.com');

      // Validate form
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      expect(find.text('Please enter a valid email'), findsNothing);
      print('✅ Valid email accepted correctly');
    });
  });
}
