import 'package:amplify_flutter/amplify_flutter.dart';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart' as amplify_s3;

/// Data source class responsible for low-level S3 storage operations
class S3DataSource {
  /// Initialize and check S3 bucket existence
  Future<bool> checkAndInitializeS3() async {
    try {
      print("🔍 Checking S3 bucket existence...");

      // Check if Amplify is configured
      if (!Amplify.isConfigured) {
        print("❌ Amplify is not configured");
        return false;
      }

      // Verify the bucket exists by trying to list files
      try {
        print("📋 Testing S3 list operation...");
        final listOperation = await Amplify.Storage.list(
          options: const StorageListOptions(
            accessLevel: StorageAccessLevel.guest,
          ),
        );
        final listResult = await listOperation.result;
        print("✅ S3 bucket exists - found ${listResult.items.length} items");
        return true;
      } catch (e) {
        print("⚠️ Error accessing S3 bucket: $e");

        // Try a direct upload to create a test file as a potential workaround
        try {
          print("🔄 Attempting to create a test file in the bucket...");
          final testKey =
              'public/test_${DateTime.now().millisecondsSinceEpoch}.txt';
          final testContent = 'Test file to initialize bucket access';

          // Create a temporary file
          final tempDir = Directory.systemTemp;
          final tempFile = File('${tempDir.path}/test_init.txt');
          await tempFile.writeAsString(testContent);

          // Try uploading to initialize the bucket access
          final uploadOperation = await Amplify.Storage.uploadFile(
            key: testKey,
            localFile: AWSFile.fromPath(tempFile.path),
            options: const StorageUploadFileOptions(
              accessLevel: StorageAccessLevel.guest,
            ),
          );
          await uploadOperation.result;
          print(
              "✅ Created test file successfully - bucket appears to be working now");

          // Clean up
          await tempFile.delete();
          return true;
        } catch (testError) {
          print("❌ Bucket initialization failed: $testError");
          print(
              "⚠️ You may need to create the S3 bucket '${dotenv.env['AWS_BUCKET_NAME']}' in the AWS console");
          return false;
        }
      }
    } catch (e) {
      print("❌ Error checking S3 bucket: $e");
      return false;
    }
  }

  /// Upload a file to S3 and return the download URL
  Future<String> uploadFile(String filePath) async {
    try {
      String key =
          'public/${DateTime.now().millisecondsSinceEpoch}_${filePath.split('/').last}';
      print("🔑 Generated S3 key: $key");

      // Upload file to S3
      await Amplify.Storage.uploadFile(
        localFile: AWSFile.fromPath(filePath),
        key: key,
        options: const StorageUploadFileOptions(
          accessLevel: StorageAccessLevel.guest,
        ),
      ).result;

      // Get download URL for the file
      final urlResult = await Amplify.Storage.getUrl(
        key: key,
        options: const StorageGetUrlOptions(
          accessLevel: StorageAccessLevel.guest,
        ),
      ).result;

      final downloadUrl = urlResult.url.toString();
      print("🔗 File uploaded, URL: $downloadUrl");

      return downloadUrl;
    } catch (e) {
      print("❌ Error uploading file to S3: $e");
      return "";
    }
  }

  /// Delete a file from S3
  Future<bool> deleteFile(String fileUrl) async {
    try {
      // Extract the key from the URL
      // URL format: https://bucket-name.s3.region.amazonaws.com/public/filename
      final uri = Uri.parse(fileUrl);
      final path = uri.path;

      // The key is everything after the first slash (public/filename)
      final key = path.startsWith('/') ? path.substring(1) : path;

      print("🗑️ Deleting file with key: $key");

      await Amplify.Storage.remove(
        key: key,
        options: const StorageRemoveOptions(
          accessLevel: StorageAccessLevel.guest,
        ),
      ).result;

      print("✅ File deleted successfully");
      return true;
    } catch (e) {
      print("❌ Error deleting file from S3: $e");
      return false;
    }
  }
}
