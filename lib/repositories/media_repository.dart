import 'dart:io';
import 'dart:math';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../data_sources/s3_data_source.dart';
import '../services/s3_service.dart';
import '../data_sources/firebase_data_source.dart';
import '../widgets/jar_content/video_thumbnail.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

/// Repository for handling media operations
class MediaRepository {
  final String userId;
  final S3Service _s3Service;
  final FirebaseDataSource _firebaseDataSource;
  final S3DataSource _s3DataSource;

  // Cache for thumbnails
  static final Map<String, String> _thumbnailCache = {};

  MediaRepository({
    required this.userId,
    S3Service? s3Service,
    FirebaseDataSource? firebaseDataSource,
    S3DataSource? s3DataSource,
  })  : _s3Service = s3Service ?? S3Service(userId: userId),
        _firebaseDataSource = firebaseDataSource ?? FirebaseDataSource(),
        _s3DataSource = s3DataSource ?? S3DataSource();

  /// Get collaborators for a jar
  Future<List<String>> getJarCollaborators(String jarId) async {
    final jarDoc =
        await _firebaseDataSource.getDocument('users/$userId/jars/$jarId');

    if (jarDoc == null || !jarDoc.exists) {
      return [];
    }

    final jarData = jarDoc.data() as Map<String, dynamic>?;
    return List<String>.from(jarData?['collaborators'] ?? []);
  }

  /// Delete an item from jar
  Future<void> deleteItemFromJar(
      String jarId, String contentUrl, List<String>? collaborators) async {
    List<String> collabList = collaborators ?? [];

    if (collaborators == null) {
      // Get collaborators if not provided
      collabList = await getJarCollaborators(jarId);
    }

    await _s3Service.deleteItemFromJar(jarId, contentUrl, collabList);
  }

  /// Generate a thumbnail for a video
  Future<String?> generateThumbnail(
      String videoUrl, String jarId, List<String> collaborators) async {
    // Check the cache first
    if (_thumbnailCache.containsKey(videoUrl)) {
      return _thumbnailCache[videoUrl];
    }

    try {
      // Delegate to the existing implementation to maintain functionality
      final thumbnail =
          await generateThumbnailImpl(videoUrl, userId, jarId, collaborators);

      if (thumbnail != null) {
        _thumbnailCache[videoUrl] = thumbnail;
      }

      return thumbnail;
    } catch (e) {
      print("❌ Error generating thumbnail: $e");
      return null;
    }
  }

  /// Check if a thumbnail is cached
  bool isThumbnailCached(String videoUrl) {
    return _thumbnailCache.containsKey(videoUrl);
  }

  /// Get a cached thumbnail
  String? getCachedThumbnail(String videoUrl) {
    return _thumbnailCache[videoUrl];
  }

  /// Generates a thumbnail image from a video URL
  /// Returns the URL of the thumbnail in S3 or null if it fails
  Future<String?> generateVideoThumbnail(
    String videoUrl,
    String jarId,
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
        maxHeight: 300,
        quality: 75,
        timeMs: 1000, // 1 second into the video for a better frame
      ).timeout(const Duration(seconds: 10), onTimeout: () {
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

  /// Upload media (photo, video) to a jar
  Future<bool> uploadMedia(
    String jarId,
    String filePath,
    String mediaType,
    List<String> collaborators,
  ) async {
    try {
      await _s3Service.uploadFileToJar(
          jarId, filePath, collaborators, mediaType);
      await _s3Service.syncJarContentAcrossCollaborators(jarId);
      return true;
    } catch (e) {
      print('❌ Error uploading media to jar: $e');
      return false;
    }
  }
}

/// Implementation function to maintain compatibility with existing code
/// This would normally be inside the repository class, but to maintain exact functionality,
/// we're keeping it separate
Future<String?> generateThumbnailImpl(String videoUrl, String userId,
    String jarId, List<String> collaborators) async {
  // Call the actual function from the original code to maintain functionality
  return await generateThumbnail(videoUrl, userId, jarId, collaborators);
}
