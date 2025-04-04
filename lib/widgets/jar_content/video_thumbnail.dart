// Add this package to pubspec.yaml:
// video_thumbnail: ^0.5.3

import 'package:video_thumbnail/video_thumbnail.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:math';

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
