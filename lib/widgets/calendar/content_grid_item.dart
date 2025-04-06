import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/s3_service.dart';
import '../jar_content/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../repositories/media_repository.dart';

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
  late final MediaRepository _mediaRepository;
  bool _isFlipped = false;
  String? _thumbnailUrl;
  bool _loadingThumbnail = false;

  @override
  void initState() {
    super.initState();

    // Initialize repositories
    _mediaRepository = MediaRepository(userId: widget.userId);

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

    // Check if this is a video and load or generate a thumbnail
    final String contentType = widget.content['type'] ?? '';
    final String contentUrl = widget.content['data'] ?? '';

    if (contentType == 'video' && contentUrl.isNotEmpty) {
      _loadThumbnail(contentUrl);
    }
  }

  Future<void> _loadThumbnail(String videoUrl) async {
    if (_loadingThumbnail) return;

    // Immediately set placeholder to avoid rendering issues
    setState(() {
      _loadingThumbnail = true;
    });

    // Check if thumbnail is cached in the repository
    if (_mediaRepository.isThumbnailCached(videoUrl)) {
      setState(() {
        _thumbnailUrl = _mediaRepository.getCachedThumbnail(videoUrl);
        _loadingThumbnail = false;
      });
      return;
    }

    // Delay the actual thumbnail loading to prevent UI freezes during initial rendering
    Future.delayed(const Duration(milliseconds: 200), () async {
      if (!mounted) return;

      try {
        // Try to generate thumbnail with strict timeout
        final String? thumbnail = await _mediaRepository.generateThumbnail(
          videoUrl,
          widget.jarId,
          [], // Empty list as we don't need to share the thumbnail
        ).timeout(const Duration(seconds: 2), onTimeout: () {
          print("⏱️ Thumbnail generation timed out");
          return null;
        });

        if (thumbnail != null && mounted) {
          setState(() {
            _thumbnailUrl = thumbnail;
            _loadingThumbnail = false;
          });
        } else if (mounted) {
          setState(() {
            _loadingThumbnail = false;
          });
        }
      } catch (e) {
        print("❌ Error generating thumbnail: $e");
        if (mounted) {
          setState(() {
            _loadingThumbnail = false;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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

  // Show confirmation dialog for deleting content
  Future<void> _showDeleteConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Content'),
        content: const Text('Are you sure you want to delete this content?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _deleteContent();
    }
  }

  // Delete the content item
  Future<void> _deleteContent() async {
    try {
      final contentUrl = widget.content['data'] ?? '';

      // Get collaborators from the repository
      final collaborators =
          await _mediaRepository.getJarCollaborators(widget.jarId);

      // Delete the item
      await _mediaRepository.deleteItemFromJar(
          widget.jarId, contentUrl, collaborators);

      // Show a success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Content deleted successfully')),
        );
      }

      // Refresh the content if callback provided
      if (widget.onContentChanged != null) {
        widget.onContentChanged!();
      }
    } catch (e) {
      print("❌ Error deleting content: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete content')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if we're in calendar view (has jarName as a string, not a date)
    bool isCalendarView = widget.content.containsKey('jarName') &&
        widget.content['jarName'] is String &&
        !widget.content['jarName'].toString().contains('-');

    return GestureDetector(
      onTap: _toggleFlip,
      onLongPress: _showDeleteConfirmation,
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
                    child: _buildBackSide(isCalendarView),
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
  Widget _buildBackSide(bool isCalendarView) {
    // Parse the jar color from the hex string
    Color jarColor = Colors.grey; // Default color
    if (widget.content.containsKey('jarColor')) {
      try {
        jarColor = Color(
            int.parse(widget.content['jarColor'].replaceFirst('#', '0xFF')));
      } catch (e) {
        print("❌ Error parsing jar color: $e");
      }
    }

    return Card(
      elevation: 0, // Remove shadow to match front
      color: const Color(0xFFF5F5F5), // Light gray background
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Center(
          child: isCalendarView
              // Calendar view: Show only jar name in jar color
              ? Text(
                  widget.content['jarName'] ?? 'Unknown jar',
                  style: TextStyle(
                    color: jarColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                )
              // Jar content view: Show only the date
              : Text(
                  widget.content['jarName'] ?? 'Unknown date',
                  style: const TextStyle(
                    color: Color(0xFF333333),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
        ),
      ),
    );
  }

  /// Builds the media view (image or video)
  Widget _buildMediaView() {
    final String contentUrl = widget.content['data'] ?? '';
    final String contentType = widget.content['type'] ?? '';

    // For image content, use CachedNetworkImage for efficient loading
    if (contentType != 'video') {
      return CachedNetworkImage(
        imageUrl: contentUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.grey[200],
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2.0, // Thinner indicator
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey[300],
          child: const Center(
            child: Icon(
              Icons.image,
              size: 40,
              color: Colors.grey,
            ),
          ),
        ),
        memCacheWidth: 300, // Limit memory cache size
        memCacheHeight: 300,
      );
    }

    // For video content, show the thumbnail if available
    if (_thumbnailUrl != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: _thumbnailUrl!,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.grey[200],
              child: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2.0,
                ),
              ),
            ),
            errorWidget: (context, url, error) => const Icon(Icons.error),
          ),
          // Video play indicator overlay
          Center(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
        ],
      );
    }

    // Show loading indicator while thumbnail is being generated
    if (_loadingThumbnail) {
      return Container(
        color: Colors.grey[200],
        child: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2.0,
          ),
        ),
      );
    }

    // Fallback for videos without thumbnails
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: Icon(
          Icons.video_library,
          size: 40,
          color: Colors.grey,
        ),
      ),
    );
  }
}
