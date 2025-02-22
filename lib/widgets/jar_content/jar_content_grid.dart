import 'package:flutter/material.dart';
import 'package:capture_mvp/models/s3_item.dart';
import 'media_thumbnail.dart';
import 'package:capture_mvp/services/s3_service.dart';

/// A grid view displaying jar contents.
class JarContentGrid extends StatelessWidget {
  final List<S3Item> items;
  final String userId;
  final String jarId;
  final VoidCallback onDelete;

  const JarContentGrid({
    super.key,
    required this.items,
    required this.userId,
    required this.jarId,
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
        return GestureDetector(
          onLongPress: () async {
            bool confirm = await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Delete Item'),
                content: Text('Are you sure you want to delete this item?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text('Delete'),
                  ),
                ],
              ),
            );
            if (confirm) {
              // Perform soft delete
              await S3Service(userId: userId).softDeleteItem(item.key);
              // Trigger the callback to refresh the UI
              onDelete();
            }
          },
          child: MediaThumbnail(s3Item: item),
        );
      },
    );
  }
}
