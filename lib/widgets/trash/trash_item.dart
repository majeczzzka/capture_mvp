import 'package:flutter/material.dart';
import '../../models/s3_item.dart';
import '../../utils/app_colors.dart';

/// A reusable widget for media display with error and loading handling
class MediaDisplay extends StatelessWidget {
  final S3Item item;
  final double? height;

  const MediaDisplay({
    Key? key,
    required this.item,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return item.type == 'photo'
        ? Image.network(
            item.url,
            fit: BoxFit.cover,
            height: height,
            width: double.infinity,
            errorBuilder: (context, error, stackTrace) {
              print('Error loading image: $error');
              return Container(
                height: height,
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
                height: height,
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
          )
        : Container(
            height: height,
            color: Colors.grey[200],
            child: Center(
              child: Icon(
                item.type == 'video' ? Icons.videocam : Icons.insert_drive_file,
                size: 50,
                color: Colors.grey[700],
              ),
            ),
          );
  }
}

/// Status badge for trash items
class TrashStatusBadge extends StatelessWidget {
  final bool isArchived;

  const TrashStatusBadge({
    Key? key,
    required this.isArchived,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isArchived) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red.shade700,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: const Text(
        'Non-Restorable',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// A widget that displays a single item in the trash list
class TrashItem extends StatelessWidget {
  final S3Item item;
  final String jarId;
  final String jarName;
  final bool isArchived;
  final Function() onTap;
  final Function() onRestore;
  final Function() onDelete;

  const TrashItem({
    Key? key,
    required this.item,
    required this.jarId,
    required this.jarName,
    required this.isArchived,
    required this.onTap,
    required this.onRestore,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Media display
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: GestureDetector(
            onTap: onTap,
            child: AspectRatio(
              aspectRatio: 1.0,
              child: MediaDisplay(item: item),
            ),
          ),
        ),

        // Archived indicator
        if (isArchived)
          Positioned(
            top: 8,
            right: 8,
            child: TrashStatusBadge(isArchived: isArchived),
          ),

        // Actions overlay (partially transparent)
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon:
                      const Icon(Icons.restore, color: Colors.white, size: 18),
                  onPressed: isArchived ? null : onRestore,
                  tooltip: isArchived ? 'Cannot Restore' : 'Restore Item',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_forever,
                      color: Colors.white, size: 18),
                  onPressed: onDelete,
                  tooltip: 'Delete Forever',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Dialog to show details of a trash item
class TrashItemDetailsDialog extends StatelessWidget {
  final S3Item item;
  final String jarName;
  final bool isArchived;
  final Function() onRestore;
  final Function() onDelete;

  const TrashItemDetailsDialog({
    Key? key,
    required this.item,
    required this.jarName,
    required this.isArchived,
    required this.onRestore,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final deletionDate = item.uploadedAt.toString().substring(0, 10);
    final screenSize = MediaQuery.of(context).size;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: screenSize.width * 0.85,
          maxHeight: screenSize.height * 0.7,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: SizedBox(
                  height: 180,
                  child: MediaDisplay(item: item),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('From: $jarName'),
                    const SizedBox(height: 4),
                    Text('Deleted: $deletionDate'),
                    const SizedBox(height: 4),
                    if (isArchived)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                          border:
                              Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: const Text(
                          'From jar you\'ve left (cannot be restored)',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            // Only call onRestore for non-archived items
                            if (!isArchived) {
                              onRestore();
                            }
                            // For archived items, just close the dialog (already handled by pop)
                          },
                          child:
                              Text(isArchived ? 'View Only' : 'Restore Item'),
                          style: TextButton.styleFrom(
                            foregroundColor:
                                isArchived ? Colors.grey : Colors.blue,
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            onDelete();
                          },
                          child: const Text('Delete Forever'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
