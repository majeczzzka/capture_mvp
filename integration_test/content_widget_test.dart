import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:capture_mvp/widgets/calendar/content_grid_item.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Content Widget Tests', () {
    testWidgets('ContentItem can be rendered', (WidgetTester tester) async {
      // Build a minimal app with just the ContentItem widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ContentItem(
                content: {
                  'type': 'image',
                  'data': 'https://example.com/test.jpg',
                  'jarName': 'Test Jar',
                  'jarColor': '#FF5722',
                },
                userId: 'test-user',
                jarId: 'test-jar',
                onContentChanged: () {
                  print('Content changed');
                },
              ),
            ),
          ),
        ),
      );

      // Allow widget to build
      await tester.pump();

      // Verify the widget renders
      expect(find.byType(ContentItem), findsOneWidget);

      // Note: Some elements may not render in the test environment due to network dependencies,
      // but the widget itself should not crash

      print('✅ ContentItem widget rendered without crashing');
    });
  });
}
