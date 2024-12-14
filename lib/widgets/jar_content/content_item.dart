import 'package:flutter/material.dart';

/// A widget representing a single content item in the grid.
class ContentItemWidget extends StatelessWidget {
  final Map<String, String> content;

  const ContentItemWidget({
    super.key,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getIconForType(content['type']),
            size: 50,
            color: Colors.grey,
          ),
          const SizedBox(height: 8),
          Text(
            content['type']!.toUpperCase(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  /// Returns the icon for the given content type.
  IconData _getIconForType(String? type) {
    switch (type) {
      case 'video':
        return Icons.videocam;
      case 'note':
        return Icons.notes;
      case 'photo':
        return Icons.photo;
      case 'voice note':
        return Icons.mic;
      case 'template':
        return Icons.format_paint;
      default:
        return Icons.error;
    }
  }
}
