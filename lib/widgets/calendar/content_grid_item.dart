import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/s3_service.dart';
import '../jar_content/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';

/// A widget that displays a single content item from a jar (image or video)
/// with flipping animation to show details on the back.
class ContentItem extends StatefulWidget {
  final Map<String, dynamic> content;
  final String userId;
  final String jarId;
  final VoidCallback? onContentChanged;

  const ContentItem({
    Key? key,
    required this.content,
    required this.userId,
    required this.jarId,
    this.onContentChanged,
  }) : super(key: key);

  @override
  State<ContentItem> createState() => _ContentItemState();
}

class _ContentItemState extends State<ContentItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  bool _isFlipped = false;
  String? _thumbnailUrl;
  bool _loadingThumbnail = false;

  @override
  void initState() {
    super.initState();

    // Initialize the animation controller
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // Create a curved animation for a smoother flip effect
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    // Check if this is a video and generate a thumbnail
    final String contentType = widget.content['type'] ?? '';
    final String contentUrl = widget.content['data'] ?? '';

    if (contentType == 'video' && contentUrl.isNotEmpty) {
      _loadThumbnail(contentUrl);
    }
  }

  Future<void> _loadThumbnail(String videoUrl) async {
    if (_loadingThumbnail) return;

    setState(() {
      _loadingThumbnail = true;
    });

    try {
      final String? thumbnail = await generateThumbnail(
        videoUrl,
        widget.userId,
        widget.jarId,
        [], // Empty list as we don't need to share the thumbnail
      );

      if (thumbnail != null) {
        if (mounted) {
          setState(() {
            _thumbnailUrl = thumbnail;
            _loadingThumbnail = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _loadingThumbnail = false;
          });
        }
      }
    } catch (e) {
      print("Error generating thumbnail: $e");
      if (mounted) {
        setState(() {
          _loadingThumbnail = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleFlip,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final angle = _animation.value * 3.14; // 180 degrees in radians
          final transform = Matrix4.identity()
            ..setEntry(3, 2, 0.001) // Perspective
            ..rotateY(angle);

          // Determine which side to show based on the animation value
          return Transform(
            transform: transform,
            alignment: Alignment.center,
            child: angle < 1.57 // pi/2 (90 degrees)
                ? _buildFrontSide()
                : Transform(
                    transform: Matrix4.identity()
                      ..rotateY(3.14), // Flip back side
                    alignment: Alignment.center,
                    child: _buildBackSide(),
                  ),
          );
        },
      ),
    );
  }

  /// Builds the front side of the card showing the media content
  Widget _buildFrontSide() {
    return Card(
      elevation: 0, // Remove shadow
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      clipBehavior: Clip.antiAlias,
      child: _buildMediaView(),
    );
  }

  /// Builds the back side of the card showing details and actions
  Widget _buildBackSide() {
    return Card(
      elevation: 0, // Remove shadow to match front
      color: const Color(0xFFF5F5F5), // Light gray background
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date and jar info
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Added on:',
                  style: TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.content['jarName'] ?? 'Unknown date',
                  style: const TextStyle(
                    color: Color(0xFF333333),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.delete, color: Color(0xFF666666)),
                  onPressed: _deleteContent,
                  tooltip: 'Delete',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the media view (image or video)
  Widget _buildMediaView() {
    final String contentUrl = widget.content['data'] ?? '';
    final String contentType = widget.content['type'] ?? '';

    // For image content, try to load directly
    if (contentType != 'video') {
      return Image.network(
        contentUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[300],
            child: const Center(
              child: Icon(
                Icons.image,
                size: 40,
                color: Colors.grey,
              ),
            ),
          );
        },
      );
    }

    // For video content - use the generated thumbnail if available
    return Stack(
      fit: StackFit.expand,
      children: [
        // If we have a thumbnail URL, use it; otherwise try direct loading
        if (_thumbnailUrl != null)
          Image.network(
            _thumbnailUrl!,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              // Fall back to trying the content URL
              return _buildVideoFallback(contentUrl);
            },
          )
        else if (_loadingThumbnail)
          // Show loading indicator while generating thumbnail
          Container(
            color: Colors.grey[200],
            child: Center(
              child: CircularProgressIndicator(),
            ),
          )
        else
          // Try loading directly from content URL as fallback
          _buildVideoFallback(contentUrl),

        // Add a semi-transparent gradient overlay to ensure play button visibility
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.0),
                Colors.black.withOpacity(0.3),
              ],
            ),
          ),
        ),

        // Always show a play button to indicate this is a video
        Center(
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const Icon(
              Icons.play_arrow,
              size: 40,
              color: Color(0xFF333333),
            ),
          ),
        ),
      ],
    );
  }

  /// Fallback widget for video display when thumbnail generation fails
  Widget _buildVideoFallback(String contentUrl) {
    return Image.network(
      contentUrl,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: Colors.grey[300],
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        // If all attempts fail, show a video icon on a light background
        return Container(
          color: Colors.grey[300],
          child: Center(
            child: Icon(
              Icons.videocam,
              size: 40,
              color: Colors.grey[600],
            ),
          ),
        );
      },
    );
  }

  /// Toggle the flip animation
  void _toggleFlip() {
    setState(() {
      _isFlipped = !_isFlipped;
      if (_isFlipped) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  /// Delete the content item from S3 and Firestore
  Future<void> _deleteContent() async {
    try {
      final contentUrl = widget.content['data'];
      if (contentUrl != null) {
        // Show confirmation dialog
        bool shouldDelete = await _showDeleteConfirmationDialog();
        if (!shouldDelete) return;

        // Extract the key from the URL
        // The URL format is typically: https://[bucket].s3.[region].amazonaws.com/[key]
        final Uri uri = Uri.parse(contentUrl);
        final String path = uri.path;
        final String key = path.startsWith('/') ? path.substring(1) : path;

        if (key.isNotEmpty) {
          // Delete from S3 using the archiveItemForUser method
          await S3Service(userId: widget.userId)
              .archiveItemForUser(widget.jarId, contentUrl);

          // Notify the parent to refresh
          if (widget.onContentChanged != null) {
            widget.onContentChanged!();
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Item moved to trash'),
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting content: $e')),
        );
      }
      print('Error deleting content: $e');
    }
  }

  /// Show a confirmation dialog before deleting
  Future<bool> _showDeleteConfirmationDialog() async {
    return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Confirm Delete'),
              content: const Text(
                  'Are you sure you want to delete this item? This action cannot be undone.'),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                ),
                TextButton(
                  child: const Text('Delete'),
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                ),
              ],
            );
          },
        ) ??
        false;
  }

  /// Check if the content URL is a video
  bool _isVideo(String url) {
    final lowerUrl = url.toLowerCase();
    return lowerUrl.endsWith('.mp4') ||
        lowerUrl.endsWith('.mov') ||
        lowerUrl.endsWith('.avi');
  }
}
