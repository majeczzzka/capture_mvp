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
      print(
          "🔍 DEBUG: getJarContents called for jarId: $jarId, user: $userId, includeDeleted: $includeDeleted");

      final jarDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('jars')
          .doc(jarId)
          .get();

      if (!jarDoc.exists) {
        print("🔍 DEBUG: Jar does not exist for user: $userId, jarId: $jarId");
        return [];
      }

      final jarData = jarDoc.data();
      if (jarData == null || !jarData.containsKey('content')) {
        print("🔍 DEBUG: No content found in jar document");
        return [];
      }

      final List<dynamic> contentList = jarData['content'];
      print("🔍 DEBUG: Jar has ${contentList.length} total content items");

      List<S3Item> items = [];

      for (var item in contentList) {
        try {
          if (item is! Map || !item.containsKey('data')) {
            print(
                "🔍 DEBUG: Skipping invalid item (not a Map or missing 'data' field)");
            continue;
          }

          // Safely extract fields with null checking
          final String url = item['data']?.toString() ?? '';
          final String type =
              (item['type']?.toString() ?? 'unknown').toLowerCase();

          // Log deletedByUsers field
          final deletedByUsersList = item['deletedByUsers'];
          print(
              "🔍 DEBUG: Item ${url.substring(0, url.length > 20 ? 20 : url.length)}... has deletedByUsers: $deletedByUsersList");

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

          // Check if this item is deleted by the current user
          final bool isDeletedByCurrentUser = s3Item.isDeletedByUser(userId);
          print(
              "🔍 DEBUG: Item is deleted by current user? $isDeletedByCurrentUser");

          // Only include items that this user hasn't deleted (unless includeDeleted is true)
          if (!includeDeleted && isDeletedByCurrentUser) {
            print(
                "🔍 DEBUG: Skipping item deleted by user (includeDeleted is false)");
            continue;
          }

          print("🔍 DEBUG: Adding item to results: $url");
          items.add(s3Item);
        } catch (e) {
          print("⚠️ Error processing item: $e");
          // Continue to next item
        }
      }

      print("🔍 DEBUG: Returning ${items.length} processed items from jar");
      return items;
    } catch (e) {
      print("❌ ERROR in getJarContents: $e");
      return [];
    }
  }

  /// Fetch deleted/archived items for a specific jar
  Future<List<S3Item>> getDeletedJarContents(String jarId) async {
    print(
        "🔎 DEBUG: getDeletedJarContents called for jar: $jarId, user: $userId");

    try {
      // Check if the jar document exists
      final documentPath = 'users/$userId/jars/$jarId';
      final documentExists = await _documentExists(documentPath);

      if (!documentExists) {
        print("🔎 DEBUG: Jar document doesn't exist: $jarId for user: $userId");
        return [];
      }

      // Use the same getJarContents method but include deleted items
      final allItems = await getJarContents(jarId, includeDeleted: true);
      print(
          "🔎 DEBUG: getJarContents returned ${allItems.length} total items (incl. non-deleted)");

      // Filter to only show items that were deleted by this user
      final deletedItems =
          allItems.where((item) => item.isDeletedByUser(userId)).toList();
      print(
          "🔎 DEBUG: Filtered to ${deletedItems.length} items deleted by user: $userId");

      // Print details of deleted items
      for (var item in deletedItems) {
        print(
            "🔎 DEBUG: Found deleted item: ${item.url}, type: ${item.type}, deletedByUsers: ${item.deletedByUsers}");
      }

      return deletedItems;
    } catch (e) {
      print("❌ ERROR in getDeletedJarContents: $e");
      return [];
    }
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

  /// Retrieves all archived jars for the current user
  Future<List<Map<String, dynamic>>> getArchivedJars() async {
    try {
      print("🔍 DEBUG: getArchivedJars called for user: $userId");

      // Check if the archived_jars collection exists
      final collectionPath = 'users/$userId/archived_jars';
      final collectionExists = await _collectionExists(collectionPath);

      if (!collectionExists) {
        print(
            "🔍 DEBUG: archived_jars collection doesn't exist or is empty for user: $userId");
        return [];
      }

      final archivedJarsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('archived_jars')
          .orderBy('archivedAt',
              descending: true) // Most recently archived first
          .get();

      print(
          "🔍 DEBUG: Firestore query returned ${archivedJarsSnapshot.docs.length} archived jar documents");

      final List<Map<String, dynamic>> archivedJars = [];

      for (final doc in archivedJarsSnapshot.docs) {
        print("🔍 DEBUG: Processing archived jar document with ID: ${doc.id}");
        final data = doc.data();
        data['id'] = doc.id; // Add the document ID
        archivedJars.add(data);
      }

      print("🔍 DEBUG: Processed ${archivedJars.length} archived jars");
      return archivedJars;
    } catch (e) {
      print("❌ ERROR in getArchivedJars: $e");
      return [];
    }
  }

  /// Restores an archived jar for the current user
  Future<bool> restoreArchivedJar(String jarId) async {
    try {
      print("🔄 Restoring archived jar: $jarId for user: $userId");

      // Get the archived jar document
      final archivedJarRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('archived_jars')
          .doc(jarId);

      final archivedJarDoc = await archivedJarRef.get();
      if (!archivedJarDoc.exists) {
        print("⚠️ Archived jar does not exist: $jarId");
        return false;
      }

      // Copy the jar data
      final jarData = Map<String, dynamic>.from(archivedJarDoc.data() ?? {});

      // Remove archiving metadata
      jarData.remove('archivedAt');
      jarData.remove('originalJarId');

      // Restore content by removing current user from deletedByUsers
      final contentList = List.from(jarData['content'] ?? []);
      for (int i = 0; i < contentList.length; i++) {
        if (contentList[i] is Map) {
          Map<String, dynamic> item = Map<String, dynamic>.from(contentList[i]);

          // Remove user from deletedByUsers list
          if (item.containsKey('deletedByUsers')) {
            List<String> deletedByUsers =
                List<String>.from(item['deletedByUsers']);
            if (deletedByUsers.contains(userId)) {
              deletedByUsers.remove(userId);
              item['deletedByUsers'] = deletedByUsers;
              contentList[i] = item;
            }
          }
        }
      }

      jarData['content'] = contentList;

      // Create the jar document in the jars collection
      final jarRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('jars')
          .doc(jarId);

      // Save to jars collection
      await jarRef.set(jarData);

      // Delete the archived jar
      await archivedJarRef.delete();

      print("✅ Jar restored successfully for user: $userId");
      return true;
    } catch (e) {
      print("❌ Error restoring archived jar: $e");
      return false;
    }
  }

  /// Deletes a specific item from a jar
  Future<void> deleteItemFromJar(
      String jarId, String itemUrl, List<String> collaborators) async {
    try {
      print("🗑️ Soft-deleting item from jar: $jarId, URL: $itemUrl");

      // Instead of immediately removing the item, mark it as deleted
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

          // Find the item to delete
          int itemIndex = contentList.indexWhere((item) =>
              item is Map &&
              item.containsKey('data') &&
              item['data'] == itemUrl);

          // If item found, mark it as deleted instead of removing it
          if (itemIndex != -1) {
            Map<String, dynamic> item =
                Map<String, dynamic>.from(contentList[itemIndex]);

            // Get or initialize deletedByUsers list
            List<String> deletedByUsers = item['deletedByUsers'] != null
                ? List<String>.from(item['deletedByUsers'])
                : [];

            // If the current user is the one deleting
            if (collaboratorId == userId) {
              // Add current user to deletedByUsers if not already there
              if (!deletedByUsers.contains(userId)) {
                deletedByUsers.add(userId);
              }

              // Set the deletion expiry date (90 days)
              final deleteExpiry = DateTime.now().add(const Duration(days: 90));
              item['deleteExpiry'] = deleteExpiry.toIso8601String();

              // Set isDeleted flag to true
              item['isDeleted'] = true;

              // Update the item in the content list
              item['deletedByUsers'] = deletedByUsers;
              contentList[itemIndex] = item;

              print("✅ Item marked as deleted for user $userId: $itemUrl");
            }

            // Update the jar document
            await jarRef.update({'content': contentList});
          } else {
            print("⚠️ Item not found in jar: $itemUrl");
          }
        }
      }

      print("✅ Item soft-deletion process completed");
    } catch (e) {
      print("❌ Error soft-deleting item: $e");
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

  /// Removes a jar for the current user only, without affecting other collaborators
  Future<void> leaveJar(String jarId) async {
    try {
      print("🚶 User $userId is leaving jar $jarId");

      // Get the jar document first to check if it exists
      final jarRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('jars')
          .doc(jarId);

      final jarDoc = await jarRef.get();
      if (!jarDoc.exists) {
        print("⚠️ Jar does not exist for this user: $jarId");
        return;
      }

      // Archive all content in the jar for this user before removing it
      print("🗄️ Archiving all jar content before removing");
      List<dynamic> contentList = List.from(jarDoc.data()?['content'] ?? []);
      print("🗄️ DEBUG: Processing ${contentList.length} items for archiving");

      // Create a copy of the jar document in the archived_jars collection
      final archivedJarRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('archived_jars')
          .doc(jarId);

      // Add deletion timestamp and copy the jar data
      final jarData = Map<String, dynamic>.from(jarDoc.data() ?? {});
      jarData['archivedAt'] = DateTime.now().toIso8601String();
      jarData['originalJarId'] = jarId;

      // Calculate deletion date (for 90-day auto cleanup)
      final deleteExpiry = DateTime.now().add(const Duration(days: 90));

      // Mark each content item as deleted by this user by updating the deletedByUsers array
      // This happens both in the active jar (for proper cleanup) and in the archived copy
      for (int i = 0; i < contentList.length; i++) {
        if (contentList[i] is Map) {
          Map<String, dynamic> item = Map<String, dynamic>.from(contentList[i]);

          // Initialize or get the deletedByUsers list
          List<String> deletedByUsers = [];
          if (item.containsKey('deletedByUsers') &&
              item['deletedByUsers'] != null) {
            deletedByUsers = List<String>.from(item['deletedByUsers']);
          }

          // Ensure this user is in the deletedByUsers list
          if (!deletedByUsers.contains(userId)) {
            deletedByUsers.add(userId);
            print("🗄️ DEBUG: Adding user $userId to deletedByUsers for item");
          }

          // Update the item with deletion info
          item['deletedByUsers'] = deletedByUsers;
          item['deleteExpiry'] = deleteExpiry.toIso8601String();

          // Set isDeleted flag to true for good measure
          item['isDeleted'] = true;

          contentList[i] = item;
        }
      }

      // Update the jar data with marked deleted items
      jarData['content'] = contentList;

      // Save to archived_jars collection
      await archivedJarRef.set(jarData);
      print(
          "✅ Jar archived for user $userId with ${contentList.length} items marked as deleted");

      // Update the jar with marked deleted items (this will be deleted, but we do this for consistency)
      await jarRef.update({'content': contentList});
      print("✅ All jar content marked as deleted for user $userId");

      // Now delete the jar document for this user
      await jarRef.delete();
      print("✅ Jar removed for user $userId");

      // Note: We're not deleting the jar content from S3 since other users may still have access
    } catch (e) {
      print("❌ Error leaving jar: $e");
      throw Exception("Failed to leave jar: $e");
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

  /// Get archived content for trash display
  Future<List<Map<String, dynamic>>> getArchivedContent() async {
    try {
      print("🔍 DEBUG: getArchivedContent called for user: $userId");

      // Get all archived jars
      final archivedJars = await getArchivedJars();
      print(
          "🔍 DEBUG: Found ${archivedJars.length} archived jars for user: $userId");

      // Log the details of archived jars
      for (final jar in archivedJars) {
        print(
            "🔍 DEBUG: Archived jar - ID: ${jar['id']}, Name: ${jar['name']}, ArchivedAt: ${jar['archivedAt']}");
      }

      final List<Map<String, dynamic>> archivedContent = [];

      // Process each archived jar
      for (final jarData in archivedJars) {
        final String jarId = jarData['id'];
        final String jarName = jarData['name'] ?? 'Unnamed Jar';

        // Get content list from the jar
        final List<dynamic> contentList = List.from(jarData['content'] ?? []);
        print("🔍 DEBUG: Jar $jarName has ${contentList.length} content items");

        // Process each content item in the jar
        for (final itemData in contentList) {
          if (itemData is Map) {
            // Convert to a proper Map<String, dynamic>
            final Map<String, dynamic> item =
                Map<String, dynamic>.from(itemData);

            // Check if this item was deleted by the current user
            final List<String> deletedByUsers = item['deletedByUsers'] != null
                ? List<String>.from(item['deletedByUsers'])
                : [];

            print(
                "🔍 DEBUG: Checking item in jar $jarName, deletedByUsers: $deletedByUsers");

            // IMPORTANT: If the item is in an archived jar, it should be visible in trash
            // regardless of whether the user's ID is in deletedByUsers array
            // This ensures we show all content from archived jars in the trash screen

            print(
                "🔍 DEBUG: Including item from archived jar for user: $userId");

            // If user ID is not in deletedByUsers, add it for future reference
            if (!deletedByUsers.contains(userId)) {
              print(
                  "🔍 DEBUG: Adding missing user ID to deletedByUsers list for archive item");
              deletedByUsers.add(userId);
              item['deletedByUsers'] = deletedByUsers;
            }

            // Create an S3Item from the data
            final S3Item s3Item = S3Item.fromFirestore(item);
            print(
                "🔍 DEBUG: Created S3Item with URL: ${s3Item.url}, type: ${s3Item.type}");

            // Add to the result list with jar info
            archivedContent.add({
              'item': s3Item,
              'jarId': jarId,
              'jarName': jarName,
              'isArchived':
                  true, // Flag to indicate this is from an archived jar
            });
          }
        }
      }

      print(
          "🔍 DEBUG: getArchivedContent returning ${archivedContent.length} items");
      return archivedContent;
    } catch (e) {
      print("❌ ERROR in getArchivedContent: $e");
      return [];
    }
  }

  /// Check if a collection exists
  Future<bool> _collectionExists(String path) async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance.collection(path).limit(1).get();
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print("❌ ERROR checking if collection exists: $e");
      return false;
    }
  }

  /// Check if document exists
  Future<bool> _documentExists(String path) async {
    try {
      final documentSnapshot = await FirebaseFirestore.instance.doc(path).get();
      return documentSnapshot.exists;
    } catch (e) {
      print("❌ ERROR checking if document exists: $e");
      return false;
    }
  }
}
