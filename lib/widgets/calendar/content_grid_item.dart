import 'package:flutter/material.dart';
import 'dart:math';
import 'package:video_player/video_player.dart';

class ContentItem extends StatefulWidget {
  final Map<String, dynamic> content;

  const ContentItem({super.key, required this.content});

  @override
  _ContentItemState createState() => _ContentItemState();
}

class _ContentItemState extends State<ContentItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isFlipped = false;
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: pi).animate(_controller);

    // Check if content is a video and initialize video player
    if (_isVideo(widget.content['data'])) {
      _videoController = VideoPlayerController.network(widget.content['data'])
        ..initialize().then((_) {
          setState(() {}); // Refresh UI when video is ready
        });
    }
  }

  bool _isVideo(String url) {
    return url.endsWith(".mp4") || url.endsWith(".mov") || url.endsWith(".avi");
  }

  void _toggleFlip() {
    if (_isFlipped) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
    setState(() {
      _isFlipped = !_isFlipped;
    });
  }

  @override
  Widget build(BuildContext context) {
    final String jarColor = widget.content['jarColor'] ?? '#000000';

    return GestureDetector(
      onTap: _toggleFlip,
      child: MouseRegion(
        onEnter: (_) => _toggleFlip(),
        onExit: (_) => _toggleFlip(),
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            final isFlippedHalfway = _animation.value > pi / 2;
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.rotationY(_animation.value),
              child: isFlippedHalfway
                  ? _buildTextView(jarColor)
                  : _buildMediaView(),
            );
          },
        ),
      ),
    );
  }

  /// Builds the media view (handles both images and videos)
  Widget _buildMediaView() {
    if (_isVideo(widget.content['data'])) {
      return _videoController != null && _videoController!.value.isInitialized
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: _videoController!.value.aspectRatio,
                child: VideoPlayer(_videoController!),
              ),
            )
          : const Center(
              child: CircularProgressIndicator()); // Show loading for videos
    } else {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: 1,
          child: Image.network(
            widget.content['data'],
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Icon(Icons.error, size: 50, color: Colors.grey),
              );
            },
          ),
        ),
      );
    }
  }

  /// Builds the flipped text view (jar name) WITHOUT mirroring the text
  Widget _buildTextView(String jarColor) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 1,
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.rotationY(pi), // Fixes mirrored text issue
          child: Center(
            child: Text(
              widget.content['jarName'],
              style: TextStyle(
                fontSize: 16,
                color: Color(int.parse(jarColor.replaceFirst('#', '0xFF'))),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _videoController?.dispose(); // Dispose video controller
    super.dispose();
  }
}
