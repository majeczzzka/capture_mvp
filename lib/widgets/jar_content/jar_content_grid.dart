import 'package:flutter/material.dart';
import 'package:capture_mvp/models/s3_item.dart';
import 'package:capture_mvp/services/s3_service.dart';
import 'package:capture_mvp/widgets/calendar/content_grid_item.dart';

/// A grid view displaying jar contents with animations and video support.
class JarContentGrid extends StatelessWidget {
  final List<S3Item> items;
  final String userId;
  final String jarId;
  final List<String> collaborators;
  final VoidCallback onDelete;

  const JarContentGrid({
    super.key,
    required this.items,
    required this.userId,
    required this.jarId,
    required this.collaborators,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];

        return ContentItem(
          content: {
            'jarId': jarId,
            'data': item.key, // This should be the S3 key, not just the URL
            'type': item.type,
            'jarName': 'Memory Jar', // Default name
            'jarColor': '#FF5722', // Default color
          },
          userId: userId,
          jarId: jarId,
        );
      },
    );
  }
}
