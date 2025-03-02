import 'package:flutter/material.dart';
import 'dart:math';
import 'package:video_player/video_player.dart';
import 'package:capture_mvp/services/s3_service.dart';

class ContentItem extends StatefulWidget {
  final Map<String, dynamic> content;
  final String userId;
  final String jarId;

  const ContentItem(
      {super.key,
      required this.content,
      required this.userId,
      required this.jarId});

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

    if (_isVideo(widget.content['data'])) {
      _videoController = VideoPlayerController.network(widget.content['data'])
        ..initialize().then((_) {
          setState(() {});
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

  void _deleteContent() {
    print("Long press detected!");
    print("Content Map: ${widget.content}");

    String? jarId = widget.jarId;
    String? itemKey = widget.content['data'];

    // Extract only the S3 key if itemKey contains a full URL
    if (itemKey != null && itemKey.startsWith("http")) {
      Uri uri = Uri.parse(itemKey);
      String? path =
          uri.pathSegments.skipWhile((seg) => seg != 'uploads').join('/');
      itemKey = path.isNotEmpty ? path : null;
    }

    if (jarId == null || itemKey == null || itemKey.isEmpty) {
      print("❌ jarId or itemKey is null/empty. Cannot delete.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Cannot delete item.')),
      );
      return;
    }

    List<String> collaborators = [];

    S3Service(userId: widget.userId)
        .deleteItemFromJar(jarId, itemKey, collaborators)
        .then((_) {
      print("✅ Content deleted successfully.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item deleted.')),
      );
      setState(() {});
    }).catchError((error) {
      print("❌ Error deleting content: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete item: $error')),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final String jarColor = widget.content['jarColor'] ?? '#000000';

    return GestureDetector(
      onTap: _toggleFlip,
      onLongPress: _deleteContent,
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
          : const Center(child: CircularProgressIndicator());
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

  Widget _buildTextView(String jarColor) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 1,
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.rotationY(pi),
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
    _videoController?.dispose();
    super.dispose();
  }
}
