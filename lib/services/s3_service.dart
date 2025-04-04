import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/s3_item.dart';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart' as amplify_s3;

class S3Service {
  final String userId;

  S3Service({required this.userId});

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

  /// Verify collaborator exists and normalize their ID
  Future<String?> verifyCollaborator(String collabId) async {
    try {
      // Trim any whitespace that might be causing problems
      final normalizedId = collabId.trim();

      // Try direct lookup first
      final collabDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(normalizedId)
          .get();

      if (collabDoc.exists) {
        print("✅ Found collaborator document: $normalizedId");
        return normalizedId;
      }

      // If direct lookup fails, try case-insensitive search
      // This is expensive but can help if the ID case is different
      print(
          "⚠️ Collaborator not found directly, trying alternative lookup: $normalizedId");

      // Special handling for "defense1" which we know should exist
      if (normalizedId.toLowerCase() == "defense1") {
        final defenseQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('username', isEqualTo: 'defense1')
            .limit(1)
            .get();

        if (defenseQuery.docs.isNotEmpty) {
          final defenseId = defenseQuery.docs.first.id;
          print("✅ Found defense1 by username search: $defenseId");
          return defenseId;
        }
      }

      print("❌ Collaborator not found: $normalizedId");
      return null;
    } catch (e) {
      print("❌ Error verifying collaborator: $e");
      return null;
    }
  }

  /// Uploads a file to S3 and ensures Firestore updates for all collaborators.
  Future<String> uploadFileToJar(String jarId, String filePath,
      List<String> collaborators, String mediaType) async {
    try {
      String key =
          'public/${DateTime.now().millisecondsSinceEpoch}_${filePath.split('/').last}';
      print("🔑 Generated S3 key: $key");

      // Upload file to S3
      final uploadResult = await Amplify.Storage.uploadFile(
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

      // Update owner's jar first
      final jarRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('jars')
          .doc(jarId);

      final jarDoc = await jarRef.get();
      if (!jarDoc.exists) {
        print("❌ Jar does not exist: $jarId");
        return "";
      }

      // Add new content item to the jar
      final contentItem = {
        'type': mediaType,
        'data': downloadUrl,
        'uploadedBy': userId,
        'uploadedAt': DateTime.now().toIso8601String(),
        'deletedByUsers': [],
      };

      List<dynamic> existingContent =
          List.from(jarDoc.data()?['content'] ?? []);
      existingContent.add(contentItem);

      // Update owner's jar document
      await jarRef.update({'content': existingContent});
      print("✅ Content added to owner's jar: $jarId");

      // Filter list to only include collaborators that exist
      List<String> validCollaborators = [];
      for (String collabId in collaborators) {
        final validId = await verifyCollaborator(collabId);
        if (validId != null) {
          // Check if the jar exists for this collaborator
          try {
            final collabJarDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(validId)
                .collection('jars')
                .doc(jarId)
                .get();

            if (collabJarDoc.exists) {
              validCollaborators.add(validId);
              print("✅ Valid collaborator with jar: $validId");
            } else {
              print("⚠️ Jar $jarId does not exist for collaborator: $validId");
            }
          } catch (e) {
            print("❌ Error checking jar for collaborator $validId: $e");
          }
        }
      }

      // Process updates in batches for valid collaborators only
      if (validCollaborators.isNotEmpty) {
        WriteBatch batch = FirebaseFirestore.instance.batch();

        for (String collabId in validCollaborators) {
          final collabJarRef = FirebaseFirestore.instance
              .collection('users')
              .doc(collabId)
              .collection('jars')
              .doc(jarId);

          batch.update(collabJarRef, {'content': existingContent});
        }

        await batch.commit();
        print("✅ Content synced to ${validCollaborators.length} collaborators");
      } else {
        print("ℹ️ No valid collaborators to sync with");
      }

      return downloadUrl;
    } catch (e) {
      print("❌ Error uploading file to jar: $e");
      if (e.toString().contains('not-found')) {
        print("⚠️ This is likely because one of the documents doesn't exist");
      }
      rethrow;
    }
  }

  /// Fetch contents of a specific jar (supports all collaborators)
  Future<List<S3Item>> getJarContents(String jarId,
      {bool includeDeleted = false}) async {
    try {
      print("🔍 Fetching jar with ID: $jarId for user: $userId");

      final jarDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('jars')
          .doc(jarId)
          .get();

      if (!jarDoc.exists) {
        print('🔥 Jar does not exist for user: $userId, jarId: $jarId');
        return [];
      }

      final jarData = jarDoc.data();
      if (jarData == null || !jarData.containsKey('content')) {
        print('🔥 No content found in jar document.');
        return [];
      }

      final List<dynamic> contentList = jarData['content'];
      print("📂 Content count: ${contentList.length}");

      List<S3Item> items = [];

      for (var item in contentList) {
        try {
          if (item is! Map || !item.containsKey('data')) continue;

          // Safely extract fields with null checking
          final String url = item['data']?.toString() ?? '';
          final String type =
              (item['type']?.toString() ?? 'unknown').toLowerCase();

          // Handle missing date - use current time as fallback
          DateTime uploadedAt;
          try {
            final dateStr = item['uploadedAt'] ?? item['date'];
            uploadedAt = dateStr != null
                ? DateTime.parse(dateStr.toString())
                : DateTime.now();
          } catch (e) {
            print("⚠️ Error parsing date, using current time: $e");
            uploadedAt = DateTime.now();
          }

          // Handle missing deletedByUsers
          List<String> deletedByUsers = [];
          if (item['deletedByUsers'] != null) {
            deletedByUsers = List<String>.from(item['deletedByUsers']);
          }

          // Create S3Item
          final S3Item s3Item = S3Item(
            key: url,
            url: url,
            type: type,
            uploadedAt: uploadedAt,
            isDeleted: item['isDeleted'] ?? false,
            deletedByUsers: deletedByUsers,
          );

          // Only include items that this user hasn't deleted (unless includeDeleted is true)
          if (!includeDeleted && s3Item.isDeletedByUser(userId)) {
            continue;
          }

          items.add(s3Item);
        } catch (e) {
          print("⚠️ Error processing item: $e");
          // Continue to next item
        }
      }

      print("✅ Processed ${items.length} valid items");
      return items;
    } catch (e) {
      print('❌ Error fetching jar contents: $e');
      return [];
    }
  }

  /// Fetch deleted/archived items for a specific jar
  Future<List<S3Item>> getDeletedJarContents(String jarId) async {
    // Use the same getJarContents method but include deleted items
    final allItems = await getJarContents(jarId, includeDeleted: true);

    // Filter to only show items that were deleted by this user
    return allItems.where((item) => item.isDeletedByUser(userId)).toList();
  }

  /// Archives an item for a specific user (soft delete)
  Future<void> archiveItemForUser(String jarId, String itemUrl) async {
    try {
      print("🗑️ Archiving item for user: $userId, in jar: $jarId");
      print("🔗 Item URL: $itemUrl");

      // Get the jar document
      final jarRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('jars')
          .doc(jarId);

      final jarDoc = await jarRef.get();
      if (!jarDoc.exists) {
        print("❌ Jar does not exist: $jarId");
        return;
      }

      // Get the current content
      List<dynamic> contentList = List.from(jarDoc.data()?['content'] ?? []);

      // Find the specific item in the content list
      int itemIndex = contentList.indexWhere((item) =>
          item is Map && item.containsKey('data') && item['data'] == itemUrl);

      if (itemIndex == -1) {
        print("❌ Item not found in jar");
        return;
      }

      // Get current item
      Map<String, dynamic> item =
          Map<String, dynamic>.from(contentList[itemIndex]);

      // Add user to deletedByUsers list if it doesn't exist yet
      List<String> deletedByUsers = item['deletedByUsers'] != null
          ? List<String>.from(item['deletedByUsers'])
          : [];

      if (!deletedByUsers.contains(userId)) {
        deletedByUsers.add(userId);
      }

      // Calculate deletion date (for 90-day auto cleanup)
      final deleteExpiry = DateTime.now().add(const Duration(days: 90));

      // Update the item
      item['deletedByUsers'] = deletedByUsers;
      item['deleteExpiry'] = deleteExpiry.toIso8601String();
      contentList[itemIndex] = item;

      // Update the jar document
      await jarRef.update({'content': contentList});

      print("✅ Item archived successfully for user: $userId");
    } catch (e) {
      print("❌ Error archiving item: $e");
    }
  }

  /// Restores an archived item for a specific user
  Future<void> restoreArchivedItem(String jarId, String itemUrl) async {
    try {
      print("🔄 Restoring archived item for user: $userId, in jar: $jarId");

      // Get the jar document
      final jarRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('jars')
          .doc(jarId);

      final jarDoc = await jarRef.get();
      if (!jarDoc.exists) {
        print("❌ Jar does not exist: $jarId");
        return;
      }

      // Get the current content
      List<dynamic> contentList = List.from(jarDoc.data()?['content'] ?? []);

      // Find the specific item in the content list
      int itemIndex = contentList.indexWhere((item) =>
          item is Map && item.containsKey('data') && item['data'] == itemUrl);

      if (itemIndex == -1) {
        print("❌ Item not found in jar");
        return;
      }

      // Get current item
      Map<String, dynamic> item =
          Map<String, dynamic>.from(contentList[itemIndex]);

      // Remove user from deletedByUsers list
      List<String> deletedByUsers = item['deletedByUsers'] != null
          ? List<String>.from(item['deletedByUsers'])
          : [];

      if (deletedByUsers.contains(userId)) {
        deletedByUsers.remove(userId);
      }

      // Update the item
      item['deletedByUsers'] = deletedByUsers;
      contentList[itemIndex] = item;

      // Update the jar document
      await jarRef.update({'content': contentList});

      print("✅ Item restored successfully for user: $userId");
    } catch (e) {
      print("❌ Error restoring item: $e");
    }
  }

  /// Permanently deletes an item from S3 and all Firestore documents
  Future<void> permanentlyDeleteItem(
      String jarId, String itemUrl, List<String> collaborators) async {
    try {
      // Extract the key from the full URL - itemUrl is the full S3 URL
      print("🔍 Permanently deleting item with URL: $itemUrl");
      final uri = Uri.parse(itemUrl);
      String key;

      // Handle different URL formats
      if (uri.path.contains('/public/')) {
        // The URL contains '/public/' - extract from there
        final pathParts = uri.path.split('/public/');
        if (pathParts.length > 1) {
          key = 'public/' + pathParts[1];
          print("🔑 Extracted key from path: $key");
        } else {
          key = uri.path.startsWith('/') ? uri.path.substring(1) : uri.path;
          if (!key.startsWith('public/')) {
            key = 'public/' + key;
          }
          print("🔑 Normalized key: $key");
        }
      } else {
        // Handle other URL formats - assume it's the S3 URL pattern
        key = uri.path;
        if (key.startsWith('/')) {
          key = key.substring(1);
        }
        if (!key.startsWith('public/')) {
          key = 'public/' + key;
        }
        print("🔑 Adjusted key: $key");
      }

      WriteBatch batch = FirebaseFirestore.instance.batch();

      for (String collaboratorId in [...collaborators, userId]) {
        final jarRef = FirebaseFirestore.instance
            .collection('users')
            .doc(collaboratorId)
            .collection('jars')
            .doc(jarId);

        final jarDoc = await jarRef.get();
        if (jarDoc.exists) {
          List<dynamic> contentList =
              List.from(jarDoc.data()?['content'] ?? []);
          contentList.removeWhere((item) => item['data'] == itemUrl);
          batch.update(jarRef, {'content': contentList});
        }
      }

      await batch.commit();
      print("✅ Item permanently removed from all Firestore documents!");

      // Delete from S3
      try {
        await Amplify.Storage.remove(
          key: key,
          options: const StorageRemoveOptions(
            accessLevel: StorageAccessLevel.guest,
          ),
        );
        print("✅ Item permanently deleted from S3: $key");
      } catch (e) {
        print("⚠️ Error deleting from S3: $e");
        // Continue even if S3 delete fails
      }
    } catch (e) {
      print("❌ Error permanently deleting item: $e");
    }
  }

  /// Syncs content for all collaborators
  Future<void> syncJarContentAcrossCollaborators(String jarId) async {
    try {
      final jarDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('jars')
          .doc(jarId)
          .get();

      if (!jarDoc.exists) {
        print('❌ Jar does not exist for current user, cannot sync');
        return;
      }

      final jarData = jarDoc.data();
      if (jarData == null) return;

      List<String> collaborators =
          List<String>.from(jarData['collaborators'] ?? []);

      // Filter to only valid collaborators
      List<String> validCollaborators = [];
      for (String collabId in collaborators) {
        final validId = await verifyCollaborator(collabId);
        if (validId != null) {
          // Check if jar exists for this collaborator
          try {
            final collabJarDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(validId)
                .collection('jars')
                .doc(jarId)
                .get();

            if (collabJarDoc.exists) {
              validCollaborators.add(validId);
              print("✅ Valid collaborator with jar: $validId");
            } else {
              print("⚠️ Jar $jarId does not exist for collaborator: $validId");

              // Special case for defense1 - create the jar if it doesn't exist
              if (validId.toLowerCase().contains("defense") ||
                  collabId.toLowerCase().contains("defense")) {
                print(
                    "🔄 Creating missing jar for defense1 collaborator: $validId");

                try {
                  // Create a new jar document for the collaborator with same content as owner
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(validId)
                      .collection('jars')
                      .doc(jarId)
                      .set({
                    'name': jarData['name'] ?? 'Shared Jar',
                    'color': jarData['color'] ?? '#FF9800',
                    'content': jarData['content'] ?? [],
                    'createdAt': jarData['createdAt'] ??
                        DateTime.now().toIso8601String(),
                    'collaborators': jarData['collaborators'] ?? [],
                  });

                  validCollaborators.add(validId);
                  print("✅ Created jar for collaborator: $validId");
                } catch (e) {
                  print("❌ Error creating jar for collaborator: $e");
                }
              }
            }
          } catch (e) {
            print("❌ Error checking jar for collaborator $validId: $e");
          }
        }
      }

      if (validCollaborators.isEmpty) {
        print("ℹ️ No valid collaborators to sync with");
        return;
      }

      WriteBatch batch = FirebaseFirestore.instance.batch();

      for (String collaboratorId in validCollaborators) {
        final collaboratorJarRef = FirebaseFirestore.instance
            .collection('users')
            .doc(collaboratorId)
            .collection('jars')
            .doc(jarId);

        batch.update(collaboratorJarRef, {
          'content': jarData['content'] ?? [],
        });

        print("✅ Syncing content to collaborator: $collaboratorId");
      }

      await batch.commit();
      print(
          "✅ Content sync complete! Synced with ${validCollaborators.length} collaborators");
    } catch (e) {
      print("❌ Error syncing jar content: $e");
      if (e.toString().contains('not-found')) {
        print("⚠️ This is likely because one of the documents doesn't exist");
      }
    }
  }

  /// Deletes a specific item from a jar
  Future<void> deleteItemFromJar(
      String jarId, String itemUrl, List<String> collaborators) async {
    try {
      // Extract the key from the full URL - itemUrl is the full S3 URL
      print("🔍 Extracting key from URL: $itemUrl");
      final uri = Uri.parse(itemUrl);
      String key;

      // Handle different URL formats
      if (uri.path.contains('/public/')) {
        // The URL contains '/public/' - extract from there
        final pathParts = uri.path.split('/public/');
        if (pathParts.length > 1) {
          key = 'public/' + pathParts[1];
          print("🔑 Extracted key from path: $key");
        } else {
          key = uri.path.startsWith('/') ? uri.path.substring(1) : uri.path;
          if (!key.startsWith('public/')) {
            key = 'public/' + key;
          }
          print("🔑 Normalized key: $key");
        }
      } else {
        // Handle other URL formats - assume it's the S3 URL pattern
        key = uri.path;
        if (key.startsWith('/')) {
          key = key.substring(1);
        }
        if (!key.startsWith('public/')) {
          key = 'public/' + key;
        }
        print("🔑 Adjusted key: $key");
      }

      WriteBatch batch = FirebaseFirestore.instance.batch();

      for (String collaboratorId in [...collaborators, userId]) {
        final jarRef = FirebaseFirestore.instance
            .collection('users')
            .doc(collaboratorId)
            .collection('jars')
            .doc(jarId);

        final jarDoc = await jarRef.get();
        if (jarDoc.exists) {
          List<dynamic> contentList =
              List.from(jarDoc.data()?['content'] ?? []);
          contentList.removeWhere((item) => item['data'] == itemUrl);
          batch.update(jarRef, {'content': contentList});
        }
      }

      await batch.commit();
      print("✅ Item removed from all Firestore documents!");

      // Delete from S3
      try {
        await Amplify.Storage.remove(
          key: key,
          options: const StorageRemoveOptions(
            accessLevel: StorageAccessLevel.guest,
          ),
        );
        print("✅ Item deleted from S3: $key");
      } catch (e) {
        print("⚠️ Error deleting from S3: $e");
        // Continue even if S3 delete fails
      }
    } catch (e) {
      print("❌ Error deleting item: $e");
    }
  }

  /// Deletes an entire jar and all its contents.
  Future<void> deleteJar(String jarId, List<String> collaborators) async {
    try {
      WriteBatch batch = FirebaseFirestore.instance.batch();

      for (String collaboratorId in [...collaborators, userId]) {
        final jarRef = FirebaseFirestore.instance
            .collection('users')
            .doc(collaboratorId)
            .collection('jars')
            .doc(jarId);
        batch.delete(jarRef);
      }

      await batch.commit();
      print("✅ Jar deleted from all collaborators!");

      // Get all items inside the jar to delete from S3
      final ownerJarRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('jars')
          .doc(jarId);
      final ownerJarDoc = await ownerJarRef.get();

      if (ownerJarDoc.exists) {
        List<dynamic> contentList = ownerJarDoc.data()?['content'] ?? [];
        for (var item in contentList) {
          if (item is Map && item.containsKey('data')) {
            String fileKey = item['data'];
            await Amplify.Storage.remove(key: fileKey);
            print("✅ Deleted from S3: $fileKey");
          }
        }
      }
    } catch (e) {
      print("❌ Error deleting jar: $e");
    }
  }

  Future<void> syncContentToCollaborator(
      String jarId, String contentId, String collaboratorId) async {
    try {
      print("🔄 Starting sync content to collaborator: $collaboratorId");

      // Verify collaborator exists
      final validCollabId = await verifyCollaborator(collaboratorId);
      if (validCollabId == null) {
        print("⚠️ Collaborator verification failed for: $collaboratorId");
        return;
      }

      print("✅ Valid collaborator found: $validCollabId");

      // Check if jar exists for collaborator
      final jarDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(validCollabId)
          .collection('jars')
          .doc(jarId)
          .get();

      // If the jar doesn't exist and this is defense1, create it
      if (!jarDoc.exists) {
        if (validCollabId.toLowerCase().contains("defense") ||
            collaboratorId.toLowerCase().contains("defense")) {
          print("🔄 Creating missing jar for defense1 collaborator");

          // Get owner's jar to copy structure
          final ownerJarDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('jars')
              .doc(jarId)
              .get();

          if (!ownerJarDoc.exists) {
            print("❌ Owner's jar document not found: $jarId");
            return;
          }

          final ownerData = ownerJarDoc.data();
          if (ownerData == null) {
            print("❌ Owner's jar has no data");
            return;
          }

          try {
            // Create jar for collaborator
            await FirebaseFirestore.instance
                .collection('users')
                .doc(validCollabId)
                .collection('jars')
                .doc(jarId)
                .set({
              'name': ownerData['name'] ?? 'Shared Jar',
              'color': ownerData['color'] ?? '#FF9800',
              'content': ownerData['content'] ?? [],
              'createdAt':
                  ownerData['createdAt'] ?? DateTime.now().toIso8601String(),
              'collaborators': ownerData['collaborators'] ?? [],
            });

            print("✅ Created jar for collaborator: $validCollabId");
            return; // Jar is already populated with all content
          } catch (e) {
            print("❌ Error creating jar for collaborator: $e");
            return;
          }
        } else {
          print("⚠️ Jar document not found for collaborator: $jarId");
          return; // Skip sync if jar doesn't exist
        }
      }

      // Get owner's jar content
      final ownerJarDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('jars')
          .doc(jarId)
          .get();

      if (!ownerJarDoc.exists) {
        print("❌ Owner's jar document not found: $jarId");
        return;
      }

      // Get the content from owner's jar
      final ownerContent = ownerJarDoc.data()?['content'] ?? [];
      final collabContent = jarDoc.data()?['content'] ?? [];

      // Find the specific content item by ID or URL
      Map<String, dynamic>? contentItem;
      if (contentId.startsWith('http')) {
        // If contentId is a URL, find by 'data' field
        for (var item in ownerContent) {
          if (item is Map<String, dynamic> && item['data'] == contentId) {
            contentItem = item;
            break;
          }
        }
      } else {
        // Otherwise find by some other identifier if available
        for (var item in ownerContent) {
          if (item is Map<String, dynamic> && item['id'] == contentId) {
            contentItem = item;
            break;
          }
        }
      }

      if (contentItem == null) {
        print("❌ Content item not found in owner's jar: $contentId");
        return;
      }

      // Update the collaborator's jar with the new content
      await FirebaseFirestore.instance
          .collection('users')
          .doc(validCollabId)
          .collection('jars')
          .doc(jarId)
          .update({
        'content': FieldValue.arrayUnion([contentItem])
      });

      print("✅ Content successfully synced to collaborator: $validCollabId");
    } catch (e) {
      // More detailed error logging
      print("❌ Error syncing content to collaborator: $e");

      if (e.toString().contains('not-found')) {
        print(
            "⚠️ This is likely because the collaborator or jar document doesn't exist");
      }
    }
  }
}
