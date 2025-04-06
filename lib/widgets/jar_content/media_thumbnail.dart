import 'package:flutter/material.dart';
import '../../models/s3_item.dart';
import 'video_thumbnail.dart';

class MediaThumbnail extends StatelessWidget {
  final S3Item s3Item;
  final String userId;
  final String jarId;

  const MediaThumbnail({
    super.key,
    required this.s3Item,
    required this.userId,
    required this.jarId,
  });

  @override
  Widget build(BuildContext context) {
    switch (s3Item.type) {
      case 'photo':
        return Image.network(
          s3Item.url,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('Error loading image: $error');
            return Container(
              color: Colors.grey[300],
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image, size: 40, color: Colors.grey[600]),
                  const SizedBox(height: 4),
                  Text(
                    'Image unavailable',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: Colors.grey[200],
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                  strokeWidth: 2,
                ),
              ),
            );
          },
        );
      case 'video':
        return VideoThumbnailWidget(
          videoUrl: s3Item.url,
          userId: userId,
          jarId: jarId,
        );
      case 'note':
        return Container(
          color: Colors.grey[200],
          child: const Center(
            child: Icon(
              Icons.note,
              size: 50,
              color: Colors.grey,
            ),
          ),
        );
      default:
        return Container(
          color: Colors.grey[200],
          child: const Center(
            child: Icon(
              Icons.file_present,
              size: 50,
              color: Colors.grey,
            ),
          ),
        );
    }
  }
}
