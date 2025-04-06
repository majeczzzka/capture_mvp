// Add this package to pubspec.yaml:
// video_thumbnail: ^0.5.3

import 'package:video_thumbnail/video_thumbnail.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../repositories/media_repository.dart';

/// Generates a thumbnail image from a video URL
/// Returns the URL of the thumbnail in S3 or null if it fails
Future<String?> generateThumbnail(
  String videoUrl,
  String userId,
  String jarId,
  List<String> collaborators,
) async {
  try {
    print("📹 Starting thumbnail generation for video: $videoUrl");

    // Request storage permission
    final status = await Permission.storage.request();
    if (!status.isGranted) {
      print("❌ Storage permission denied");
      return null;
    }

    // Generate a unique filename to avoid conflicts
    final random = Random().nextInt(10000);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filename = 'thumb_${timestamp}_$random.jpg';

    // Use documents directory
    final appDir = await getApplicationDocumentsDirectory();
    final thumbnailPath = '${appDir.path}/$filename';

    // Ensure old file is removed if it exists
    final thumbnailFile = File(thumbnailPath);
    if (await thumbnailFile.exists()) {
      await thumbnailFile.delete();
    }

    // Generate the thumbnail - with timeout protection
    print("🔍 Extracting thumbnail from video...");
    final thumbnail = await VideoThumbnail.thumbnailFile(
      video: videoUrl,
      thumbnailPath: thumbnailPath,
      imageFormat: ImageFormat.JPEG,
      maxHeight: 300, // Slightly higher resolution
      quality: 75, // Better quality
      timeMs: 1000, // 1 second into the video for a better frame
    ).timeout(Duration(seconds: 10), onTimeout: () {
      print("⏱️ Thumbnail generation timed out");
      return null;
    });

    if (thumbnail == null) {
      print("❌ Failed to generate thumbnail");
      return null;
    }

    final thumbnailFileObj = File(thumbnail);
    if (!await thumbnailFileObj.exists()) {
      print("❌ Thumbnail file doesn't exist after generation");
      return null;
    }

    // Upload the thumbnail to S3
    print("📤 Uploading thumbnail to S3...");
    final key = 'thumbnails/$userId/$jarId/${timestamp}_$random.jpg';

    try {
      // Upload with error handling
      final uploadResult = await Amplify.Storage.uploadFile(
        localFile: AWSFile.fromPath(thumbnailFileObj.path),
        key: key,
        options: const StorageUploadFileOptions(
          accessLevel: StorageAccessLevel.guest,
        ),
      ).result;

      print("✅ Thumbnail uploaded successfully with key: $key");

      // Get the S3 URL after upload
      final urlResult = await Amplify.Storage.getUrl(
        key: key,
        options: const StorageGetUrlOptions(
          accessLevel: StorageAccessLevel.guest,
        ),
      ).result;

      final thumbnailUrl = urlResult.url.toString();
      print("🔗 Thumbnail URL: $thumbnailUrl");

      // Clean up the local file
      try {
        await thumbnailFileObj.delete();
      } catch (e) {
        print("⚠️ Warning: Failed to delete temporary thumbnail file: $e");
      }

      return thumbnailUrl;
    } catch (uploadError) {
      print("❌ Error uploading thumbnail to S3: $uploadError");
      return null;
    }
  } catch (e) {
    print("❌ Error generating thumbnail: $e");
    return null;
  }
}

/// A widget that displays a thumbnail for a video
class VideoThumbnailWidget extends StatefulWidget {
  final String videoUrl;
  final String userId;
  final String jarId;

  const VideoThumbnailWidget({
    Key? key,
    required this.videoUrl,
    required this.userId,
    required this.jarId,
  }) : super(key: key);

  @override
  State<VideoThumbnailWidget> createState() => _VideoThumbnailWidgetState();
}

class _VideoThumbnailWidgetState extends State<VideoThumbnailWidget> {
  String? thumbnailUrl;
  bool isLoading = true;
  bool hasError = false;
  late MediaRepository _mediaRepository;

  @override
  void initState() {
    super.initState();
    _mediaRepository = MediaRepository(userId: widget.userId);
    _loadThumbnail();
  }

  Future<void> _loadThumbnail() async {
    try {
      setState(() {
        isLoading = true;
        hasError = false;
      });

      final url = await _mediaRepository.generateVideoThumbnail(
        widget.videoUrl,
        widget.jarId,
      );

      if (mounted) {
        setState(() {
          thumbnailUrl = url;
          isLoading = false;
          hasError = url == null;
        });
      }
    } catch (e) {
      print('Error loading video thumbnail: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
          hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        color: Colors.grey[200],
        child: const Center(
          child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );
    }

    if (hasError || thumbnailUrl == null) {
      return Container(
        color: Colors.grey[300],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.videocam, size: 40, color: Colors.grey[600]),
              const SizedBox(height: 8),
              Text(
                'Video preview unavailable',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        // Thumbnail image
        Image.network(
          thumbnailUrl!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            print('Error loading thumbnail image: $error');
            return Container(
              color: Colors.grey[300],
              child: const Center(
                child: Icon(Icons.broken_image, size: 40),
              ),
            );
          },
        ),

        // Play button overlay
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          padding: const EdgeInsets.all(8),
          child: const Icon(
            Icons.play_arrow,
            color: Colors.white,
            size: 30,
          ),
        ),
      ],
    );
  }
}
