import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Utils class for common testing operations
class TestUtils {
  /// Helper method to find and tap a widget with specified text
  static Future<void> tapText(WidgetTester tester, String text) async {
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
  }

  /// Helper method to find and tap a widget by type
  static Future<void> tapWidget(WidgetTester tester, Type widgetType) async {
    await tester.tap(find.byType(widgetType));
    await tester.pumpAndSettle();
  }

  /// Helper method to find and tap a widget by key
  static Future<void> tapKey(WidgetTester tester, Key key) async {
    await tester.tap(find.byKey(key));
    await tester.pumpAndSettle();
  }

  /// Helper method to find and tap an icon
  static Future<void> tapIcon(WidgetTester tester, IconData icon) async {
    await tester.tap(find.byIcon(icon));
    await tester.pumpAndSettle();
  }

  /// Helper method to enter text into a TextField
  static Future<void> enterText(WidgetTester tester, String text,
      {Key? fieldKey, int? atIndex}) async {
    if (fieldKey != null) {
      await tester.enterText(find.byKey(fieldKey), text);
    } else if (atIndex != null) {
      await tester.enterText(find.byType(TextField).at(atIndex), text);
    } else {
      await tester.enterText(find.byType(TextField).first, text);
    }
    await tester.pumpAndSettle();
  }

  /// Wait for a specific duration
  static Future<void> wait(WidgetTester tester, Duration duration) async {
    await tester.pump(duration);
  }

  /// Takes a screenshot (useful for debugging failures)
  static Future<void> takeScreenshot(
      IntegrationTestWidgetsFlutterBinding binding, String name) async {
    if (binding is LiveTestWidgetsFlutterBinding) {
      await binding.takeScreenshot(name);
    }
  }

  /// Verifies that a text is present on screen
  static void expectTextPresent(String text) {
    expect(find.text(text), findsOneWidget);
  }

  /// Verifies that a text appears multiple times on screen
  static void expectTextPresentTimes(String text, int times) {
    expect(find.text(text), findsNWidgets(times));
  }

  /// Verifies that a text is not present on screen
  static void expectTextAbsent(String text) {
    expect(find.text(text), findsNothing);
  }

  /// Verifies that a widget is present on screen
  static void expectWidgetPresent(Type widgetType) {
    expect(find.byType(widgetType), findsWidgets);
  }
}
