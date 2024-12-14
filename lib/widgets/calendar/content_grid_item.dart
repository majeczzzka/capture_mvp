import 'package:capture_mvp/utils/app_colors.dart';
import 'package:flutter/material.dart';

// A widget displaying a single content item in a grid view.
class ContentItem extends StatelessWidget {
  final Map<String, dynamic> content;

  const ContentItem({super.key, required this.content});

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
            content['type'].toUpperCase(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.fonts,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content['jarName'],
            style: TextStyle(
              fontSize: 12,
              color: Color(
                  int.parse(content['jarColor'].replaceFirst('#', '0xFF'))),
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Returns the icon for the given content type.
  IconData _getIconForType(String type) {
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
