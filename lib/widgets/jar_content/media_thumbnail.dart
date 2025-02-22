import 'package:flutter/material.dart';
import '../../models/s3_item.dart';

class MediaThumbnail extends StatelessWidget {
  final S3Item s3Item;

  const MediaThumbnail({super.key, required this.s3Item});

  @override
  Widget build(BuildContext context) {
    switch (s3Item.type) {
      case 'photo':
        return Image.network(
          s3Item.url,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const Icon(Icons.image),
        );
      case 'video':
        return const Icon(Icons.video_library);
      case 'note':
        return const Icon(Icons.note);
      default:
        return const Icon(Icons.file_present);
    }
  }
}
