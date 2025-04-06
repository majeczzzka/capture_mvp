import 'package:flutter/material.dart';
import 'package:capture_mvp/models/s3_item.dart';
import 'package:capture_mvp/widgets/calendar/content_grid_item.dart';

/// A grid view displaying jar contents with animations and video support.
class JarContentGrid extends StatelessWidget {
  final List<S3Item> items;
  final String userId;
  final String jarId;
  final VoidCallback onDelete;
  final String jarName;

  const JarContentGrid({
    super.key,
    required this.items,
    required this.userId,
    required this.jarId,
    required this.onDelete,
    this.jarName = 'Memory Jar',
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
            'data': item.key,
            'type': item.type,
            'jarName': jarName,
            'jarColor':
                '#FF5722', // Default color - consider making this a parameter
          },
          userId: userId,
          jarId: jarId,
        );
      },
    );
  }
}
