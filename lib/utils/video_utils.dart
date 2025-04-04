import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';

/// Utilities for working with videos
class VideoUtils {
  // Cache to avoid regenerating thumbnails for the same URL
  static final Map<String, String> _thumbnailCache = {};

  /// Generate a thumbnail image path from a video URL
  /// Returns the local path to the thumbnail image or null if generation failed
  static Future<String?> generateVideoThumbnail(String videoUrl) async {
    // Check cache first
    if (_thumbnailCache.containsKey(videoUrl)) {
      final cachedPath = _thumbnailCache[videoUrl];
      if (cachedPath != null && File(cachedPath).existsSync()) {
        return cachedPath;
      } else {
        // Remove invalid cache entry
        _thumbnailCache.remove(videoUrl);
      }
    }

    try {
      // Get a temporary directory to save the thumbnail
      final Directory tempDir = await getTemporaryDirectory();
      final String thumbnailPath =
          '${tempDir.path}/${Uri.encodeComponent(videoUrl.hashCode.toString())}.jpg';

      // Check if the thumbnail already exists
      if (File(thumbnailPath).existsSync()) {
        _thumbnailCache[videoUrl] = thumbnailPath;
        return thumbnailPath;
      }

      // Generate the thumbnail in a compute isolate to avoid blocking the UI
      final String? path = await compute(_generateThumbnail, {
        'videoUrl': videoUrl,
        'thumbnailPath': thumbnailPath,
      });

      if (path != null) {
        _thumbnailCache[videoUrl] = path;
      }

      return path;
    } catch (e) {
      print('⚠️ Error generating video thumbnail: $e');
      return null;
    }
  }

  /// Helper function to run in a separate isolate
  static Future<String?> _generateThumbnail(Map<String, String> params) async {
    try {
      final videoUrl = params['videoUrl']!;
      final thumbnailPath = params['thumbnailPath']!;

      return await VideoThumbnail.thumbnailFile(
        video: videoUrl,
        thumbnailPath: thumbnailPath,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 200,
        quality: 75,
        timeMs: 0, // Get the first frame
      );
    } catch (e) {
      print('⚠️ Error in isolate generating thumbnail: $e');
      return null;
    }
  }
}
