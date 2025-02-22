import 'package:capture_mvp/utils/app_colors.dart';
import 'package:flutter/material.dart';

// A widget displaying a single content item in a grid view.
class ContentItem extends StatelessWidget {
  final Map<String, dynamic> content;

  const ContentItem({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    // Extract jarColor from the content map
    final String jarColor =
        content['jarColor'] ?? '#000000'; // Default to black if not provided

    return GestureDetector(
      onTap: () {
        // Implement navigation or display logic based on content type
      },
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: Color(int.parse(jarColor.replaceFirst('#', '0xFF'))),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(
              content['data'],
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.error, size: 50, color: Colors.grey);
              },
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
                color: Color(int.parse(jarColor.replaceFirst('#', '0xFF'))),
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
